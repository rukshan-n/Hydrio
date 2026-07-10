import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/providers/hydrio_provider.dart';
import 'add_water_screen.dart';

class TodayScreen extends StatefulWidget {
  final VoidCallback onSettingsTap;

  const TodayScreen({super.key, required this.onSettingsTap});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> with WidgetsBindingObserver {
  late String _lastDateKey;
  Timer? _rolloverTimer;

  @override
  void initState() {
    super.initState();
    _lastDateKey = _getCurrentDateKey();
    WidgetsBinding.instance.addObserver(this);
    
    // Check rollover every minute in case the app is left open
    _rolloverTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _checkRollover();
    });
  }

  @override
  void dispose() {
    _rolloverTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkRollover();
    }
  }

  String _getCurrentDateKey() {
    return DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  void _checkRollover() {
    final currentKey = _getCurrentDateKey();
    if (currentKey != _lastDateKey) {
      setState(() {
        _lastDateKey = currentKey;
      });
      final provider = Provider.of<HydrioProvider>(context, listen: false);
      provider.loadTodayData().then((_) {
        provider.loadHistoryData();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<HydrioProvider>();
    
    final summary = provider.todaySummary;
    final totalConsumed = summary?.totalMl ?? 0;
    final dailyTarget = provider.calculatedDailyTarget;
    final percentage = dailyTarget > 0 ? (totalConsumed / dailyTarget) : 0.0;
    final remaining = (dailyTarget - totalConsumed).clamp(0, dailyTarget);

    // Motivational messaging logic matching the spec thresholds
    String motivationalMessage;
    Color messageColor;
    
    if (totalConsumed >= dailyTarget) {
      motivationalMessage = 'Goal reached! 🎉';
      messageColor = theme.colorScheme.secondary; // Success color
    } else if (percentage < 0.5) {
      motivationalMessage = 'Keep going — ${provider.formatVolume(remaining)} to go';
      messageColor = theme.colorScheme.onSurfaceVariant; // Muted/Ink
    } else {
      motivationalMessage = 'Good progress! ${provider.formatVolume(remaining)} to go';
      messageColor = theme.colorScheme.secondary; // Success color
    }

    // Prep quick-add presets
    final cupSize = provider.settings.cupSizeMl;
    final List<int> presets = [100, 200, 250, 500];
    if (!presets.contains(cupSize)) {
      presets.add(cupSize);
    }
    presets.sort();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Today',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            iconSize: 28,
            onPressed: widget.onSettingsTap,
            tooltip: 'Settings',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              children: [
                const SizedBox(height: 16),
                // Animated Circular Progress Ring
                AnimatedProgressRing(
                  progress: percentage,
                  totalConsumed: totalConsumed,
                  dailyTarget: dailyTarget,
                  formatVolume: provider.formatVolume,
                ),
                const SizedBox(height: 24),
                // Motivational message
                Text(
                  motivationalMessage,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: messageColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                // Quick-add row
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Quick add',
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 48,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: presets.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final amount = presets[index];
                      return _QuickAddChip(
                        amount: amount,
                        displayLabel: provider.formatVolume(amount),
                        onTap: () {
                          provider.logDrink(amount);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Logged ${provider.formatVolume(amount)} of water! 💧'),
                              duration: const Duration(seconds: 1),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 32),
                // Pinned CTA Add Water Button
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const AddWaterScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 54),
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.brightness == Brightness.dark 
                        ? Colors.black 
                        : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add, size: 24),
                      SizedBox(width: 8),
                      Text(
                        'Add Water',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AnimatedProgressRing extends StatefulWidget {
  final double progress;
  final int totalConsumed;
  final int dailyTarget;
  final String Function(int) formatVolume;

  const AnimatedProgressRing({
    super.key,
    required this.progress,
    required this.totalConsumed,
    required this.dailyTarget,
    required this.formatVolume,
  });

  @override
  State<AnimatedProgressRing> createState() => _AnimatedProgressRingState();
}

class _AnimatedProgressRingState extends State<AnimatedProgressRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _prevProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animation = Tween<double>(begin: 0.0, end: widget.progress).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant AnimatedProgressRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _prevProgress = oldWidget.progress;
      _animation = Tween<double>(begin: _prevProgress, end: widget.progress).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final disableAnimations = MediaQuery.of(context).disableAnimations;

    final double displayProgress = disableAnimations ? widget.progress : widget.progress;

    return Center(
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final ringProgress = disableAnimations ? widget.progress : _animation.value;
          final displayPct = (widget.progress * 100).round();
          
          return Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 240,
                height: 240,
                child: CustomPaint(
                  painter: _RingPainter(
                    progress: ringProgress,
                    primaryColor: theme.colorScheme.primary,
                    trackColor: theme.brightness == Brightness.dark
                        ? const Color(0xff173448)
                        : const Color(0xffD6ECFB),
                    successColor: theme.colorScheme.secondary, // Success Color
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$displayPct%',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.formatVolume(widget.totalConsumed)} / ${widget.formatVolume(widget.dailyTarget)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
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

class _RingPainter extends CustomPainter {
  final double progress;
  final Color primaryColor;
  final Color trackColor;
  final Color successColor;

  _RingPainter({
    required this.progress,
    required this.primaryColor,
    required this.trackColor,
    required this.successColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 20) / 2;
    const strokeWidth = 20.0;

    // Draw background track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, trackPaint);

    // Draw active progress ring arc
    final activePaint = Paint()
      ..color = progress >= 1.0 ? successColor : primaryColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    // Determine sweep angle
    // Cap visual progress at 1.0 but support overflow animation values
    final double visualProgress = progress.clamp(0.0, 1.0);
    final double sweepAngle = 2 * 3.1415926535 * visualProgress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.1415926535 / 2, // Start at 12 o'clock
      sweepAngle,
      false,
      activePaint,
    );

    // Draw an extra glow/halo ring if there is an overflow (>100%)
    if (progress > 1.0) {
      final glowPaint = Paint()
        ..color = successColor.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0;
      canvas.drawCircle(center, radius + strokeWidth / 2 + 6, glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.successColor != successColor;
  }
}

class _QuickAddChip extends StatelessWidget {
  final int amount;
  final String displayLabel;
  final VoidCallback onTap;

  const _QuickAddChip({
    required this.amount,
    required this.displayLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: isDark ? const Color(0xff1B2430) : const Color(0xffF2F5F8),
      borderRadius: BorderRadius.circular(12.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.0),
        child: Container(
          constraints: const BoxConstraints(minWidth: 72),
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          alignment: Alignment.center,
          child: Text(
            displayLabel,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
