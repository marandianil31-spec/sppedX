import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  runApp(const SpeedXApp());
}

class SpeedXApp extends StatelessWidget {
  const SpeedXApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SpeedX',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF080D14),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00F5A0),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const SpeedHomeScreen(),
    );
  }
}

class SpeedHomeScreen extends StatefulWidget {
  const SpeedHomeScreen({super.key});

  @override
  State<SpeedHomeScreen> createState() => _SpeedHomeScreenState();
}

class _SpeedHomeScreenState extends State<SpeedHomeScreen> {
  StreamSubscription<Position>? _subscription;

  double speed = 0;
  double maxSpeed = 0;
  double distance = 0;
  double totalSpeed = 0;
  int readings = 0;

  Position? previousPosition;
  bool isTracking = false;
  String gpsStatus = 'GPS band hai';

  double get averageSpeed =>
      readings == 0 ? 0 : totalSpeed / readings;

  Future<void> startTrip() async {
    bool enabled = await Geolocator.isLocationServiceEnabled();

    if (!enabled) {
      setState(() => gpsStatus = 'GPS ON karein');
      return;
    }

    LocationPermission permission =
        await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      setState(() => gpsStatus = 'Location permission chahiye');
      return;
    }

    const settings = LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 1,
    );

    setState(() {
      speed = 0;
      maxSpeed = 0;
      distance = 0;
      totalSpeed = 0;
      readings = 0;
      previousPosition = null;
      isTracking = true;
      gpsStatus = 'GPS connect ho raha hai...';
    });

    await _subscription?.cancel();

    _subscription = Geolocator.getPositionStream(
      locationSettings: settings,
    ).listen(
      (Position position) {
        if (!mounted || !isTracking) return;

        // GPS speed metres/second mein deta hai.
        final currentSpeed = position.speed.isFinite
            ? math.max(0.0, position.speed * 3.6)
            : 0.0;

        setState(() {
          speed = currentSpeed;

          if (currentSpeed > maxSpeed) {
            maxSpeed = currentSpeed;
          }

          final previous = previousPosition;

          if (previous != null) {
            final metres = Geolocator.distanceBetween(
              previous.latitude,
              previous.longitude,
              position.latitude,
              position.longitude,
            );

            // GPS ki chhoti inaccuracies ko distance mein na jodein.
            if (metres >= 2 && metres < 100) {
              distance += metres / 1000;
            }
          }

          previousPosition = position;
          totalSpeed += currentSpeed;
          readings++;
          gpsStatus = 'GPS connected';
        });
      },
      onError: (_) {
        if (mounted) {
          setState(() => gpsStatus = 'GPS signal nahi mil raha');
        }
      },
    );
  }

  Future<void> stopTrip() async {
    await _subscription?.cancel();
    _subscription = null;

    if (!mounted) return;

    setState(() {
      isTracking = false;
      speed = 0;
      gpsStatus = 'Trip band hai';
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
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
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00F5A0)
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(
                      Icons.speed,
                      color: Color(0xFF00F5A0),
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SpeedX',
                          style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'GPS SPEEDOMETER',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
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

              const SizedBox(height: 32),

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
                          height: 1.1,
                        ),
                      ),
                      const Text(
                        'km/h',
                        style: TextStyle(
                          fontSize: 18,
                          color: Color(0xFF00F5A0),
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
                    child: statCard(
                      'MAX SPEED',
                      '${maxSpeed.round()}',
                      'km/h',
                      Icons.trending_up,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: statCard(
                      'AVG SPEED',
                      '${averageSpeed.round()}',
                      'km/h',
                      Icons.show_chart,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              statCard(
                'TRIP DISTANCE',
                distance.toStringAsFixed(2),
                'km',
                Icons.route,
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
                        ? const Color(0xFFFF5252)
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
                'GPS accuracy aur phone signal ke anusaar badal sakti hai.',
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

  Widget statCard(
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
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF00F5A0), size: 25),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white54,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 23,
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

    final rect = Rect.fromCircle(center: center, radius: radius);

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
