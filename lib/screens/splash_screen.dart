import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _logoController;
  late final AnimationController _pulseController;

  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _logoController.forward();
    _pulseController.repeat(reverse: true);

    _navigationTimer = Timer(
      const Duration(milliseconds: 2600),
      () {
        if (!mounted) return;

        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => const MainNavigation(),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _logoController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B111B),
      body: Center(
        child: FadeTransition(
          opacity: CurvedAnimation(
            parent: _logoController,
            curve: Curves.easeIn,
          ),
          child: ScaleTransition(
            scale: Tween<double>(
              begin: 0.75,
              end: 1.0,
            ).animate(
              CurvedAnimation(
                parent: _logoController,
                curve: Curves.easeOutBack,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Container(
                      width: 142 +
                          (_pulseController.value * 8),
                      height: 142 +
                          (_pulseController.value * 8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF35D9FF)
                              .withValues(
                            alpha: 0.35 +
                                (_pulseController.value * 0.4),
                          ),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF35D9FF)
                                .withValues(
                              alpha: 0.08 +
                                  (_pulseController.value * 0.12),
                            ),
                            blurRadius: 30,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                      child: CustomPaint(
                        painter: _SplashGaugePainter(
                          progress: _pulseController.value,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.speed_rounded,
                            size: 64,
                            color: Color(0xFF35D9FF),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 30),
                const Text(
                  'SpeedX',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'YOUR SPEED. YOUR JOURNEY.',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 2.2,
                    color: Color(0xFF91A5BB),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 38),
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Color(0xFF35D9FF),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SplashGaugePainter extends CustomPainter {
  final double progress;

  const _SplashGaugePainter({
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(
      size.width / 2,
      size.height / 2,
    );

    final radius = size.width * 0.38;

    final backgroundPaint = Paint()
      ..color = const Color(0xFF253447)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = const Color(0xFF35D9FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    const startAngle = math.pi * 0.75;
    const sweepAngle = math.pi * 1.5;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      backgroundPaint,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle * (0.65 + progress * 0.25),
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(
    covariant _SplashGaugePainter oldDelegate,
  ) {
    return oldDelegate.progress != progress;
  }
}
