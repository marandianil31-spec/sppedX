import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../services/gps_control.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver {
  static const Color background = Color(0xFF0B111B);
  static const Color cardColor = Color(0xFF18212F);
  static const Color accent = Color(0xFF35D9FF);

  StreamSubscription<Position>? _positionSubscription;
  Timer? _displayTimer;

  bool isTracking = false;
  bool isLoading = false;
  bool _disposed = false;

  double currentSpeed = 0;
  double targetSpeed = 0;
  double maxSpeed = 0;
  double totalDistance = 0;
  double gpsAccuracy = 0;

  Position? _lastPosition;
  DateTime? _lastPositionTime;

  final List<double> _speedSamples = [];

  String gpsStatus = 'GPS Ready';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Automatically start tracking when the screen opens.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndStartGps();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAndStartGps();
    }
  }

  Future<void> _checkAndStartGps() async {
    if (!mounted || isLoading || isTracking) return;

    await GpsControl.instance.load();

    if (!mounted) return;

    if (!GpsControl.instance.isEnabled) {
      setState(() {
        gpsStatus = 'GPS Disabled in Settings';
      });
      return;
    }

    await startTrip();
  }

  @override
  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _positionSubscription?.cancel();
    _displayTimer?.cancel();
    super.dispose();
  }

  Future<void> startTrip() async {
    if (isLoading || isTracking || !mounted) return;

    setState(() {
      isLoading = true;
      gpsStatus = 'Checking GPS...';
    });

    try {
      final serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!mounted) return;

      if (!serviceEnabled) {
        setState(() {
          gpsStatus = 'Please enable phone GPS';
        });
        _showMessage('Please turn on Location/GPS.');
        return;
      }

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (!mounted) return;

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          gpsStatus = 'Location Permission Required';
        });
        _showMessage(
          'Allow SpeedX location permission in phone Settings.',
        );
        return;
      }

      await _positionSubscription?.cancel();
      _displayTimer?.cancel();

      _speedSamples.clear();
      _lastPosition = null;
      _lastPositionTime = null;

      setState(() {
        currentSpeed = 0;
        targetSpeed = 0;
        maxSpeed = 0;
        totalDistance = 0;
        gpsAccuracy = 0;
        isTracking = true;
        gpsStatus = 'Searching for GPS...';
      });

      final settings = AndroidSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
        intervalDuration: const Duration(milliseconds: 500),
        forceLocationManager: false,
      );

      // Smooth visual movement without delaying GPS updates excessively.
      _displayTimer = Timer.periodic(
        const Duration(milliseconds: 50),
        (_) {
          if (!mounted || !isTracking) return;

          final difference = targetSpeed - currentSpeed;

          // Faster response when speed increases or decreases.
          final factor = difference.abs() > 8 ? 0.38 : 0.24;

          double nextSpeed =
              currentSpeed + difference * factor;

          if (nextSpeed < 0.4 && targetSpeed < 0.4) {
            nextSpeed = 0;
          }

          if ((nextSpeed - currentSpeed).abs() > 0.01) {
            setState(() {
              currentSpeed = nextSpeed;
            });
          }
        },
      );

      _positionSubscription =
          Geolocator.getPositionStream(
        locationSettings: settings,
      ).listen(
        _onPosition,
        onError: (Object error) {
          if (!mounted) return;

          setState(() {
            gpsStatus = 'GPS Error';
          });
        },
      );
    } catch (e) {
      _showMessage('Unable to start GPS. Please try again.');

      if (mounted) {
        setState(() {
          gpsStatus = 'GPS Error';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _onPosition(Position position) {
    if (!mounted || !isTracking) return;

    final now = DateTime.now();

    if (!position.accuracy.isFinite ||
        position.accuracy <= 0 ||
        position.accuracy > 35) {
      setState(() {
        gpsAccuracy = position.accuracy.isFinite
            ? position.accuracy
            : 0;
        gpsStatus = 'Weak GPS Signal';
      });
      return;
    }

    gpsAccuracy = position.accuracy;

    final rawSpeed = position.speed.isFinite
        ? math.max(0.0, position.speed * 3.6)
        : 0.0;

    final previous = _lastPosition;
    final previousTime = _lastPositionTime;

    double measuredSpeed = rawSpeed;
    double addedDistance = 0;

    if (previous != null && previousTime != null) {
      final elapsed =
          now.difference(previousTime).inMilliseconds / 1000.0;

      if (elapsed <= 0 || elapsed > 8) {
        _lastPosition = position;
        _lastPositionTime = now;
        return;
      }

      final meters = Geolocator.distanceBetween(
        previous.latitude,
        previous.longitude,
        position.latitude,
        position.longitude,
      );

      final calculatedSpeed = meters / elapsed * 3.6;

      // Ignore impossible jumps.
      if (meters > 150 || calculatedSpeed > 220) {
        setState(() {
          gpsStatus = 'GPS Signal Unstable';
        });
        return;
      }

      // Use location speed as primary measurement.
      // Use calculated speed only when the two differ greatly
      // and GPS accuracy is reasonably good.
      if (meters >= 2 &&
          elapsed >= 0.5 &&
          (rawSpeed - calculatedSpeed).abs() > 25 &&
          position.accuracy <= 12) {
        measuredSpeed = calculatedSpeed;
      }

      // Suppress tiny movements while stationary.
      if (meters < 1.5 && rawSpeed < 3) {
        measuredSpeed = 0;
      }

      if (meters >= 2 && meters <= 100) {
        addedDistance = meters / 1000.0;
      }
    }

    _lastPosition = position;
    _lastPositionTime = now;

    // Use a short rolling median to remove spikes without
    // adding the delay of a large sample window.
    _speedSamples.add(measuredSpeed);

    if (_speedSamples.length > 3) {
      _speedSamples.removeAt(0);
    }

    final sorted = List<double>.from(_speedSamples)..sort();
    final median = sorted[sorted.length ~/ 2];

    // Adapt smoothing to how quickly the measured speed changes.
    final difference = (median - targetSpeed).abs();

    final alpha = difference > 8
        ? 0.72
        : difference > 3
            ? 0.55
            : 0.35;

    targetSpeed += (median - targetSpeed) * alpha;

    if (targetSpeed < 0.5 && median < 0.5) {
      targetSpeed = 0;
    }

    if (targetSpeed > maxSpeed) {
      maxSpeed = targetSpeed;
    }

    totalDistance += addedDistance;

    setState(() {
      gpsStatus = position.accuracy <= 10
          ? 'GPS Signal: Good'
          : 'GPS Signal: Fair';
    });
  }

  Future<void> stopTrip() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;

    _displayTimer?.cancel();
    _displayTimer = null;

    if (!mounted) return;

    setState(() {
      isTracking = false;
      currentSpeed = 0;
      targetSpeed = 0;
      gpsStatus = 'GPS Stopped';
      _lastPosition = null;
      _lastPositionTime = null;
      _speedSamples.clear();
    });
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        foregroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.speed, color: accent, size: 30),
            SizedBox(width: 10),
            Text(
              'SpeedX',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isTracking
                      ? Colors.green.withValues(alpha: 0.15)
                      : Colors.white10,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isTracking ? 'LIVE GPS' : 'GPS OFF',
                  style: TextStyle(
                    color: isTracking
                        ? Colors.greenAccent
                        : Colors.white54,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            const SizedBox(height: 10),
            Center(
              child: Text(
                'CURRENT SPEED',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 13,
                  letterSpacing: 3,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: SizedBox(
                width: 280,
                height: 280,
                child: CustomPaint(
                  painter: SpeedGaugePainter(
                    speed: currentSpeed,
                    maxSpeed: 220,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 35),
                      Text(
                        currentSpeed.toStringAsFixed(0),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 68,
                          fontWeight: FontWeight.bold,
                          fontFeatures: [
                            FontFeature.tabularFigures(),
                          ],
                        ),
                      ),
                      const Text(
                        'km/h',
                        style: TextStyle(
                          color: accent,
                          fontSize: 18,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                gpsStatus,
                style: const TextStyle(
                  color: accent,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: _infoCard(
                    icon: Icons.speed,
                    title: 'MAX SPEED',
                    value: maxSpeed.toStringAsFixed(1),
                    unit: 'km/h',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _infoCard(
                    icon: Icons.route,
                    title: 'DISTANCE',
                    value: totalDistance.toStringAsFixed(2),
                    unit: 'km',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.gps_fixed, color: accent),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'GPS Accuracy',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                  Text(
                    gpsAccuracy > 0
                        ? '${gpsAccuracy.toStringAsFixed(1)} m'
                        : '--',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'GPS starts automatically when this screen opens. '
              'Use Settings to disable tracking.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white38,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required String title,
    required String value,
    required String unit,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 25),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 10,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            unit,
            style: const TextStyle(
              color: accent,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class SpeedGaugePainter extends CustomPainter {
  final double speed;
  final double maxSpeed;

  SpeedGaugePainter({
    required this.speed,
    required this.maxSpeed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 18;

    const startAngle = math.pi * 0.75;
    const sweepAngle = math.pi * 1.5;

    final backgroundPaint = Paint()
      ..color = const Color(0xFF263344)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 15
      ..strokeCap = StrokeCap.round;

    final activePaint = Paint()
      ..color = const Color(0xFF35D9FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 15
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(
      center: center,
      radius: radius,
    );

    canvas.drawArc(
      rect,
      startAngle,
      sweepAngle,
      false,
      backgroundPaint,
    );

    final progress = (speed / maxSpeed).clamp(0.0, 1.0);

    canvas.drawArc(
      rect,
      startAngle,
      sweepAngle * progress,
      false,
      activePaint,
    );

    final tickPaint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 2;

    for (int i = 0; i <= 22; i++) {
      final angle = startAngle + sweepAngle * i / 22;

      final outer = Offset(
        center.dx + math.cos(angle) * (radius - 18),
        center.dy + math.sin(angle) * (radius - 18),
      );

      final inner = Offset(
        center.dx + math.cos(angle) * (radius - 28),
        center.dy + math.sin(angle) * (radius - 28),
      );

      canvas.drawLine(inner, outer, tickPaint);
    }
  }

  @override
  bool shouldRepaint(covariant SpeedGaugePainter oldDelegate) {
    return oldDelegate.speed != speed ||
        oldDelegate.maxSpeed != maxSpeed;
  }
}
