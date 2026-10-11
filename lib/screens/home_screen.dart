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
  StreamSubscription<Position>? _gpsSubscription;

  double speed = 0;
  double maxSpeed = 0;
  double distance = 0;

  Position? previousPosition;

  bool isTracking = false;
  String gpsStatus = 'GPS ready';

  Future<void> startTrip() async {
    try {
      final enabled =
          await Geolocator.isLocationServiceEnabled();

      if (!enabled) {
        setState(() => gpsStatus = 'Please turn GPS on');
        return;
      }

      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() => gpsStatus = 'Location permission required');
        return;
      }

      setState(() {
        speed = 0;
        maxSpeed = 0;
        distance = 0;
        previousPosition = null;
        isTracking = true;
        gpsStatus = 'Connecting GPS...';
      });

      await _gpsSubscription?.cancel();

      _gpsSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 1,
        ),
      ).listen(
        (Position position) {
          if (!mounted || !isTracking) return;

          final currentSpeed = math.max(
            0.0,
            position.speed * 3.6,
          );

          setState(() {
            speed = currentSpeed;

            if (speed > maxSpeed) {
              maxSpeed = speed;
            }

            final previous = previousPosition;

            if (previous != null) {
              final metres = Geolocator.distanceBetween(
                previous.latitude,
                previous.longitude,
                position.latitude,
                position.longitude,
              );

              if (metres >= 2 && metres < 100) {
                distance += metres / 1000;
              }
            }

            previousPosition = position;
            gpsStatus = 'GPS connected';
          });
        },
        onError: (_) {
          if (mounted) {
            setState(() {
              gpsStatus = 'GPS signal unavailable';
            });
          }
        },
      );
    } catch (_) {
      if (mounted) {
        setState(() => gpsStatus = 'GPS error');
      }
    }
  }

  Future<void> stopTrip() async {
    await _gpsSubscription?.cancel();
    _gpsSubscription = null;

    if (!mounted) return;

    setState(() {
      isTracking = false;
      speed = 0;
      gpsStatus = 'Trip stopped';
    });
  }

  @override
  void dispose() {
    _gpsSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.speed,
                    color: Color(0xFF00F5A0),
                    size: 38,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SpeedX',
                          style: TextStyle(
                            fontSize: 27,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'GPS SPEEDOMETER',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 10,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.gps_fixed,
                    color: Color(0xFF00F5A0),
                  ),
                ],
              ),

              const SizedBox(height: 25),

              Text(
                gpsStatus,
                style: const TextStyle(
                  color: Color(0xFF00F5A0),
                  fontSize: 13,
                ),
              ),

              const SizedBox(height: 15),

              SizedBox(
                width: 290,
                height: 290,
                child: CustomPaint(
                  painter: SpeedGaugePainter(speed: speed),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 35),
                      Text(
                        speed.round().toString(),
                        style: const TextStyle(
                          fontSize: 76,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Text(
                        'km/h',
                        style: TextStyle(
                          color: Color(0xFF00F5A0),
                          fontSize: 18,
                          letterSpacing: 3,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'LIVE SPEED',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 25),

              Row(
                children: [
                  Expanded(
                    child: _statCard(
                      'MAX SPEED',
                      maxSpeed.round().toString(),
                      'km/h',
                      Icons.trending_up,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _statCard(
                      'DISTANCE',
                      distance.toStringAsFixed(2),
                      'km',
                      Icons.route,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 25),

              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton.icon(
                  onPressed: isTracking ? stopTrip : startTrip,
                  icon: Icon(
                    isTracking ? Icons.stop : Icons.play_arrow,
                  ),
                  label: Text(
                    isTracking ? 'STOP TRIP' : 'START TRIP',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isTracking
                        ? Colors.redAccent
                        : const Color(0xFF00F5A0),
                    foregroundColor: const Color(0xFF080D14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              const Text(
                'GPS accuracy depends on signal and phone quality.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard(
    String title,
    String value,
    String unit,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF111A25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF00F5A0)),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            value,
            style: const TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            unit,
            style: const TextStyle(
              color: Color(0xFF00F5A0),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class SpeedGaugePainter extends CustomPainter {
  final double speed;

  SpeedGaugePainter({required this.speed});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.42;

    const startAngle = math.pi * 0.75;
    const sweepAngle = math.pi * 1.5;

    final rect = Rect.fromCircle(
      center: center,
      radius: radius,
    );

    final backgroundPaint = Paint()
      ..color = const Color(0xFF24303E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    final activePaint = Paint()
      ..color = const Color(0xFF00F5A0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      rect,
      startAngle,
      sweepAngle,
      false,
      backgroundPaint,
    );

    final progress = (speed / 180).clamp(0.0, 1.0);

    if (progress > 0) {
      canvas.drawArc(
        rect,
        startAngle,
        sweepAngle * progress,
        false,
        activePaint,
      );
    }

    final tickPaint = Paint()
      ..color = Colors.white30
      ..strokeWidth = 2;

    for (int i = 0; i <= 18; i++) {
      final angle = startAngle + sweepAngle * i / 18;

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
    return oldDelegate.speed != speed;
  }
}
