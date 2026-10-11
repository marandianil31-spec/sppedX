import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color background = Color(0xFF0B111B);
  static const Color cardColor = Color(0xFF18212F);
  static const Color accent = Color(0xFF35D9FF);

  StreamSubscription<Position>? _positionSubscription;

  bool isTracking = false;
  bool isLoading = false;

  double currentSpeed = 0;
  double maxSpeed = 0;
  double totalDistance = 0;
  double gpsAccuracy = 0;

  Position? _lastPosition;
  DateTime? _lastUpdate;
  final List<double> _speedSamples = [];

  String gpsStatus = 'GPS Ready';

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }

  Future<void> startTrip() async {
    if (isLoading || isTracking) return;

    setState(() {
      isLoading = true;
      gpsStatus = 'Checking GPS...';
    });

    try {
      final serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        _showMessage('Phone ki Location/GPS ON karein.');
        return;
      }

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        _showMessage('GPS permission allow karein.');
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        _showMessage(
          'Settings mein jaakar SpeedX ko Location permission dein.',
        );
        return;
      }

      _lastPosition = null;
      _lastUpdate = null;
      _speedSamples.clear();

      if (!mounted) return;

      setState(() {
        currentSpeed = 0;
        maxSpeed = 0;
        totalDistance = 0;
        gpsAccuracy = 0;
        isTracking = true;
        gpsStatus = 'Searching for GPS...';
      });

      const settings = AndroidSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
        intervalDuration: Duration(seconds: 1),
        forceLocationManager: false,
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

          _showMessage('GPS update nahi mil raha hai.');
        },
      );
    } catch (e) {
      _showMessage('GPS start nahi hua. Dobara try karein.');
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

    // Reject inaccurate GPS positions.
    if (!position.accuracy.isFinite ||
        position.accuracy <= 0 ||
        position.accuracy > 25) {
      setState(() {
        gpsAccuracy = position.accuracy;
        gpsStatus = 'Weak GPS Signal';
      });
      return;
    }

    gpsAccuracy = position.accuracy;

    final rawSpeed = position.speed.isFinite
        ? math.max(0.0, position.speed * 3.6)
        : 0.0;

    final previous = _lastPosition;
    final previousTime = _lastUpdate;

    double measuredSpeed = rawSpeed;
    double addedDistance = 0;

    if (previous != null && previousTime != null) {
      final elapsed = now.difference(previousTime).inMilliseconds /
          1000.0;

      if (elapsed <= 0 || elapsed > 10) {
        _lastPosition = position;
        _lastUpdate = now;
        return;
      }

      final meters = Geolocator.distanceBetween(
        previous.latitude,
        previous.longitude,
        position.latitude,
        position.longitude,
      );

      // GPS jumps can create unrealistic speeds.
      final calculatedSpeed = meters / elapsed * 3.6;

      if (meters > 150 || calculatedSpeed > 220) {
        gpsStatus = 'GPS Signal Unstable';
        return;
      }

      // Ignore tiny movements while stationary.
      if (meters < 1.5 && rawSpeed < 3) {
        measuredSpeed = 0;
      }

      // Do not count very small GPS movements as distance.
      if (meters >= 2 && meters <= 100) {
        addedDistance = meters / 1000.0;
      }

      // Compare GPS speed with distance-based speed.
      // If they differ greatly, trust GPS speed cautiously.
      if (meters >= 2 && elapsed >= 0.5) {
        final difference = (rawSpeed - calculatedSpeed).abs();

        if (difference > 35 && position.accuracy > 10) {
          measuredSpeed = calculatedSpeed;
        }
      }

      _lastPosition = position;
      _lastUpdate = now;
    } else {
      _lastPosition = position;
      _lastUpdate = now;
    }

    // Smooth speed using recent readings.
    _speedSamples.add(measuredSpeed);

    if (_speedSamples.length > 5) {
      _speedSamples.removeAt(0);
    }

    final sortedSamples = List<double>.from(_speedSamples)
      ..sort();

    final median = sortedSamples[sortedSamples.length ~/ 2];

    // Limit sudden jumps between consecutive display readings.
    double smoothedSpeed = median;

    final difference = smoothedSpeed - currentSpeed;

    if (difference > 15) {
      smoothedSpeed = currentSpeed + 15;
    } else if (difference < -20) {
      smoothedSpeed = currentSpeed - 20;
    }

    // Do not report a false stationary speed.
    if (rawSpeed < 1.0 &&
        position.accuracy <= 10 &&
        currentSpeed < 4) {
      smoothedSpeed = 0;
    }

    smoothedSpeed = math.max(0, smoothedSpeed);

    setState(() {
      currentSpeed = smoothedSpeed;

      if (currentSpeed > maxSpeed) {
        maxSpeed = currentSpeed;
      }

      totalDistance += addedDistance;

      gpsStatus = position.accuracy <= 10
          ? 'GPS Signal: Good'
          : 'GPS Signal: Fair';
    });
  }

  Future<void> stopTrip() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;

    if (!mounted) return;

    setState(() {
      isTracking = false;
      currentSpeed = 0;
      gpsStatus = 'Trip Stopped';
      _lastPosition = null;
      _lastUpdate = null;
      _speedSamples.clear();
    });

    _showMessage(
      'Trip stopped. Distance: ${totalDistance.toStringAsFixed(2)} km',
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String get speedText => currentSpeed.toStringAsFixed(0);

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
                    color: isTracking ? Colors.greenAccent : Colors.white54,
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
                        speedText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 68,
                          fontWeight: FontWeight.bold,
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
                  const Icon(
                    Icons.gps_fixed,
                    color: accent,
                  ),
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

            const SizedBox(height: 24),

            SizedBox(
              height: 58,
              child: ElevatedButton.icon(
                onPressed: isLoading
                    ? null
                    : isTracking
                        ? stopTrip
                        : startTrip,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isTracking ? Colors.redAccent : accent,
                  foregroundColor:
                      isTracking ? Colors.white : background,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                icon: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : Icon(
                        isTracking ? Icons.stop : Icons.play_arrow,
                      ),
                label: Text(
                  isLoading
                      ? 'STARTING GPS...'
                      : isTracking
                          ? 'STOP TRIP'
                          : 'START TRIP',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 18),

            const Text(
              'For better GPS results, test outdoors with a clear view of the sky.',
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
