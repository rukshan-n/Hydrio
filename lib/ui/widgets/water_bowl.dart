import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';

class WaterBowl extends StatefulWidget {
  final double progress;
  final int totalConsumed;
  final int dailyTarget;
  final String Function(int) formatVolume;

  const WaterBowl({
    super.key,
    required this.progress,
    required this.totalConsumed,
    required this.dailyTarget,
    required this.formatVolume,
  });

  @override
  State<WaterBowl> createState() => _WaterBowlState();
}

class _WaterBowlState extends State<WaterBowl> with TickerProviderStateMixin {
  late AnimationController _waveController;
  late AnimationController _levelController;
  late Animation<double> _levelAnimation;
  double _prevProgress = 0.0;

  @override
  void initState() {
    super.initState();
    // Continuous wave animation
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    if (!Platform.environment.containsKey('FLUTTER_TEST')) {
      _waveController.repeat();
    }

    // Progress level transition animation
    _levelController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _levelAnimation = Tween<double>(
      begin: 0.0,
      end: widget.progress.clamp(0.0, 1.0),
    ).animate(CurvedAnimation(
      parent: _levelController,
      curve: Curves.easeOutCubic,
    ));

    _levelController.forward();
  }

  @override
  void didUpdateWidget(covariant WaterBowl oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _prevProgress = oldWidget.progress.clamp(0.0, 1.0);
      _levelAnimation = Tween<double>(
        begin: _prevProgress,
        end: widget.progress.clamp(0.0, 1.0),
      ).animate(CurvedAnimation(
        parent: _levelController,
        curve: Curves.easeOutCubic,
      ));
      _levelController.reset();
      _levelController.forward();
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    _levelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Grab colors from theme configuration in AGENTS.md / theme.dart
    final primaryColor = theme.colorScheme.primary;
    final successColor = theme.colorScheme.secondary;
    final trackColor = theme.colorScheme.primaryContainer;
    
    final disableAnimations = MediaQuery.of(context).disableAnimations;

    return Center(
      child: AnimatedBuilder(
        animation: Listenable.merge([_waveController, _levelAnimation]),
        builder: (context, child) {
          final level = disableAnimations ? widget.progress.clamp(0.0, 1.0) : _levelAnimation.value;
          final wavePhase = _waveController.value * 2 * math.pi;
          
          final displayPct = (widget.progress * 100).round();

          return Stack(
            alignment: Alignment.center,
            children: [
              // Liquid / Wave Canvas
              SizedBox(
                width: 240,
                height: 240,
                child: CustomPaint(
                  painter: _WaterBowlPainter(
                    progress: level,
                    wavePhase: wavePhase,
                    primaryColor: primaryColor,
                    successColor: successColor,
                    trackColor: trackColor,
                    isCompleted: widget.progress >= 1.0,
                  ),
                ),
              ),
              // Inside Text Details
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$displayPct%',
                    style: TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                      shadows: [
                        Shadow(
                          offset: const Offset(0, 1.5),
                          blurRadius: 3.0,
                          color: isDark ? Colors.black.withOpacity(0.5) : Colors.white.withOpacity(0.8),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.formatVolume(widget.totalConsumed)} / ${widget.formatVolume(widget.dailyTarget)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          offset: const Offset(0, 1),
                          blurRadius: 2.0,
                          color: isDark ? Colors.black.withOpacity(0.5) : Colors.white.withOpacity(0.8),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _WaterBowlPainter extends CustomPainter {
  final double progress; // 0.0 to 1.0
  final double wavePhase; // 0.0 to 2*pi
  final Color primaryColor;
  final Color successColor;
  final Color trackColor;
  final bool isCompleted;

  _WaterBowlPainter({
    required this.progress,
    required this.wavePhase,
    required this.primaryColor,
    required this.successColor,
    required this.trackColor,
    required this.isCompleted,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Save layer to avoid blending issues when clipping
    canvas.save();
    
    // 1. Clip outer bowl boundary
    final clipPath = Path()..addOval(rect);
    canvas.clipPath(clipPath);

    // 2. Draw background fill for empty bowl
    final bgPaint = Paint()
      ..color = trackColor.withOpacity(0.15);
    canvas.drawCircle(center, radius, bgPaint);

    // Subtle internal shadow/glow for bowl depth
    final bowlDepthPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.transparent,
          trackColor.withOpacity(0.2),
        ],
        stops: const [0.7, 1.0],
      ).createShader(rect);
    canvas.drawCircle(center, radius, bowlDepthPaint);

    // 3. Draw Water Waves (Only if progress > 0)
    if (progress > 0.0) {
      // Calculate water level height
      final double targetY = size.height - (progress * size.height);
      
      // Determine water colors based on target completion
      final Color topWaterColor = isCompleted ? successColor : primaryColor;
      
      // Creating slightly darker bottom water colors for premium linear gradient
      final Color bottomWaterColor = isCompleted 
          ? successColor.withBlue(120).withGreen(180)
          : primaryColor.withRed(15).withBlue(210);

      // --- Draw Back Wave ---
      final backWavePath = Path();
      const int steps = 100;
      final double waveHeight = 8.0 * (1.0 - (progress - 0.5).abs() * 1.5).clamp(0.2, 1.0);
      
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
            topWaterColor.withOpacity(0.4),
            bottomWaterColor.withOpacity(0.4),
          ],
        ).createShader(rect);
      canvas.drawPath(backWavePath, backWavePaint);

      // --- Draw Front Wave ---
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

    // Restore layer
    canvas.restore();

    // 4. Draw outer rim (3D glass/plastic bowl effect)
    final rimPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(0.6),
          Colors.white.withOpacity(0.1),
          trackColor.withOpacity(0.2),
          trackColor.withOpacity(0.6),
        ],
        stops: const [0.0, 0.4, 0.6, 1.0],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0;
    canvas.drawCircle(center, radius - 3, rimPaint);

    // Inner rim glow for visual pop
    final innerRimPaint = Paint()
      ..color = (isCompleted ? successColor : primaryColor).withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, radius - 6, innerRimPaint);

    // Draw an extra glow halo for completion celebration
    if (isCompleted) {
      final glowPaint = Paint()
        ..color = successColor.withOpacity(0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0;
      canvas.drawCircle(center, radius + 4, glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _WaterBowlPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.wavePhase != wavePhase ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.successColor != successColor ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.isCompleted != isCompleted;
  }
}
