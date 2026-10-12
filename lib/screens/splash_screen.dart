import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _logoController;
  late final AnimationController _pulseController;
  late final Animation<double> _logoAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _logoAnimation = CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeOutBack,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeIn,
    );

    _logoController.forward();

    Future.delayed(const Duration(milliseconds: 2600), () {
      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const MainNavigation(),
          transitionsBuilder:
              (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const cyan = Color(0xFF35D9FF);
    const background = Color(0xFF070C14);

    return Scaffold(
      backgroundColor: background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.2),
            radius: 0.9,
            colors: [
              Color(0xFF142D43),
              background,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: AnimatedBuilder(
              animation: Listenable.merge([
                _logoController,
                _pulseController,
              ]),
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: Transform.scale(
                    scale: _logoAnimation.value,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 220,
                          height: 220,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 190 +
                                    (_pulseController.value * 12),
                                height: 190 +
                                    (_pulseController.value * 12),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: cyan.withValues(
                                      alpha: 0.12 +
                                          (_pulseController.value * 0.18),
                                    ),
                                    width: 2,
                                  ),
                                ),
                              ),
                              Container(
                                width: 165,
                                height: 165,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFF101D2B),
                                  border: Border.all(
                                    color: cyan.withValues(alpha: 0.65),
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: cyan.withValues(
                                        alpha: 0.12 +
                                            (_pulseController.value * 0.18),
                                      ),
                                      blurRadius: 30,
                                      spreadRadius: 3,
                                    ),
                                  ],
                                ),
                              ),
                              CustomPaint(
                                size: const Size(155, 155),
                                painter: _SplashGaugePainter(
                                  progress: _pulseController.value,
                                ),
                              ),
                              const Icon(
                                Icons.speed_rounded,
                                size: 83,
                                color: cyan,
                              ),
                              Positioned(
                                bottom: 35,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: background,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: cyan.withValues(alpha: 0.5),
                                    ),
                                  ),
                                  child: const Text(
                                    'GPS',
                                    style: TextStyle(
                                      color: cyan,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 3,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),
                        const Text(
                          'SpeedX',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 42,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'YOUR JOURNEY. YOUR SPEED.',
                          style: TextStyle(
                            color: cyan,
                            fontSize: 11,
                            letterSpacing: 2.2,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 55),
                        SizedBox(
                          width: 130,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: null,
                              minHeight: 3,
                              backgroundColor: Colors.white10,
                              color: cyan,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'INITIALIZING SPEEDX',
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: 9,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _SplashGaugePainter extends CustomPainter {
  final double progress;

  _SplashGaugePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;

    const startAngle = math.pi * 0.75;
    const sweepAngle = math.pi * 1.5;

    final paint = Paint()
      ..color = const Color(0xFF35D9FF)
          .withValues(alpha: 0.5 + progress * 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      paint,
    );

    final needleAngle =
        startAngle + sweepAngle * (0.15 + progress * 0.7);

    final needlePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final needleEnd = Offset(
      center.dx + math.cos(needleAngle) * (radius - 15),
      center.dy + math.sin(needleAngle) * (radius - 15),
    );

    canvas.drawLine(center, needleEnd, needlePaint);

    canvas.drawCircle(
      center,
      5,
      Paint()..color = const Color(0xFF35D9FF),
    );
  }

  @override
  bool shouldRepaint(covariant _SplashGaugePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
