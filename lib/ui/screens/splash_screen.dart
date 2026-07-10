import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _waveController;
  late AnimationController _introController;
  late Animation<double> _levelAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Loop wave phase animation continuously
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    if (!Platform.environment.containsKey('FLUTTER_TEST')) {
      _waveController.repeat();
    }

    // Intro/Filling animation sequence
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    // Water rises from 0% to 75%
    _levelAnimation = Tween<double>(
      begin: 0.0,
      end: 0.75,
    ).animate(CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
    ));

    // Logo & text fade in
    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
    ));

    // Logo & text slide up slightly
    _slideAnimation = Tween<double>(
      begin: 30.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.3, 0.8, curve: Curves.easeOutCubic),
    ));

    _introController.forward();

    // Navigate to gateway after splash completion
    Timer(const Duration(milliseconds: 2600), _navigateToNextScreen);
  }

  void _navigateToNextScreen() {
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const HydrioGateway(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  void dispose() {
    _waveController.dispose();
    _introController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppPalette.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: AnimatedBuilder(
          animation: Listenable.merge([_waveController, _introController]),
          builder: (context, child) {
            final level = _levelAnimation.value;
            final wavePhase = _waveController.value * 2 * math.pi;

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated Water Bowl Logo Container
                Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: palette.primary.withOpacity(isDark ? 0.15 : 0.08),
                        blurRadius: 24,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: CustomPaint(
                    painter: _SplashWaterBowlPainter(
                      progress: level,
                      wavePhase: wavePhase,
                      primaryColor: palette.primary,
                      successColor: palette.success,
                      trackColor: palette.panel,
                    ),
                  ),
                ),
                const SizedBox(height: 48),

                // Text branding with slide & fade
                Opacity(
                  opacity: _opacityAnimation.value,
                  child: Transform.translate(
                    offset: Offset(0, _slideAnimation.value),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Hydrio',
                          style: theme.textTheme.displayMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: palette.ink,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Stay hydrated, every day.',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: palette.muted,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SplashWaterBowlPainter extends CustomPainter {
  final double progress;
  final double wavePhase;
  final Color primaryColor;
  final Color successColor;
  final Color trackColor;

  _SplashWaterBowlPainter({
    required this.progress,
    required this.wavePhase,
    required this.primaryColor,
    required this.successColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    canvas.save();

    // 1. Clip circle boundary
    final clipPath = Path()..addOval(rect);
    canvas.clipPath(clipPath);

    // 2. Background track
    final bgPaint = Paint()..color = trackColor.withOpacity(0.2);
    canvas.drawCircle(center, radius, bgPaint);

    // Depth shade
    final bowlDepthPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.transparent,
          trackColor.withOpacity(0.15),
        ],
        stops: const [0.75, 1.0],
      ).createShader(rect);
    canvas.drawCircle(center, radius, bowlDepthPaint);

    // 3. Draw rising waves
    if (progress > 0.0) {
      final double targetY = size.height - (progress * size.height);
      final Color topWaterColor = primaryColor;
      final Color bottomWaterColor = primaryColor.withRed(15).withBlue(210);

      // Back wave
      final backWavePath = Path();
      const int steps = 100;
      final double waveHeight = 6.0 * (1.0 - (progress - 0.5).abs() * 1.5).clamp(0.2, 1.0);

      backWavePath.moveTo(0, targetY);
      for (int i = 0; i <= steps; i++) {
        final double x = (i / steps) * size.width;
        final double y = targetY + math.sin(x * 2.0 * math.pi / size.width + wavePhase + math.pi) * waveHeight;
        backWavePath.lineTo(x, y);
      }
      backWavePath.lineTo(size.width, size.height);
      backWavePath.lineTo(0, size.height);
      backWavePath.close();

      final backWavePaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            topWaterColor.withOpacity(0.35),
            bottomWaterColor.withOpacity(0.35),
          ],
        ).createShader(rect);
      canvas.drawPath(backWavePath, backWavePaint);

      // Front wave
      final frontWavePath = Path();
      frontWavePath.moveTo(0, targetY);
      for (int i = 0; i <= steps; i++) {
        final double x = (i / steps) * size.width;
        final double y = targetY + math.sin(x * 2.0 * math.pi / size.width - wavePhase) * waveHeight;
        frontWavePath.lineTo(x, y);
      }
      frontWavePath.lineTo(size.width, size.height);
      frontWavePath.lineTo(0, size.height);
      frontWavePath.close();

      final frontWavePaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            topWaterColor,
            bottomWaterColor,
          ],
        ).createShader(rect);
      canvas.drawPath(frontWavePath, frontWavePaint);
    }

    canvas.restore();

    // 4. Rim
    final rimPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(0.55),
          Colors.white.withOpacity(0.1),
          trackColor.withOpacity(0.2),
          trackColor.withOpacity(0.5),
        ],
        stops: const [0.0, 0.4, 0.6, 1.0],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;
    canvas.drawCircle(center, radius - 2, rimPaint);

    // Inner rim glow
    final innerRimPaint = Paint()
      ..color = primaryColor.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, radius - 4.5, innerRimPaint);

    // Draw central floating water drop icon inside the bowl
    final double opacity = math.max(0.0, 1.0 - progress);
    if (opacity > 0.0) {
      final textPainter = TextPainter(
        textDirection: TextDirection.ltr,
        text: TextSpan(
          text: String.fromCharCode(Icons.water_drop.codePoint),
          style: TextStyle(
            fontSize: 48,
            fontFamily: Icons.water_drop.fontFamily,
            package: Icons.water_drop.fontPackage,
            color: primaryColor.withOpacity(opacity * 0.95),
            shadows: [
              Shadow(
                offset: const Offset(0, 1),
                blurRadius: 4.0,
                color: Colors.black.withOpacity(opacity * 0.15),
              ),
            ],
          ),
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SplashWaterBowlPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.wavePhase != wavePhase ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.successColor != successColor ||
        oldDelegate.trackColor != trackColor;
  }
}
