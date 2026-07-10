import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/providers/hydrio_provider.dart';
import 'add_water_screen.dart';
import '../widgets/water_bowl.dart';

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
                // Cool Animated Water Bowl
                WaterBowl(
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
      color: theme.cardTheme.color ?? (isDark ? const Color(0xff1B2430) : const Color(0xffF2F5F8)),
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
