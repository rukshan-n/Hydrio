import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/providers/hydrio_provider.dart';
import '../../core/models/settings_model.dart';

class SetupScreen extends StatefulWidget {
  final int step;

  const SetupScreen({
    super.key,
    required this.step,
  });

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  late int _currentStep;

  // Wizard state matching mockups and HydrioSettings properties
  String _gender = 'Female';
  int _age = 28;
  String _wakeTime = '07:00';
  String _sleepTime = '23:00'; // maps to "11:00 PM"
  int _reminderIntervalMin = 90;
  int _cupSizeMl = 250;

  // Options lists matching mockup designs
  final List<String> _genderOptions = ['Female', 'Male'];
  
  final List<String> _wakeTimeOptions = ['05:00', '06:00', '07:00', '08:00'];
  
  final List<Map<String, String>> _sleepTimeOptions = [
    {'display': '9:00 PM', 'value': '21:00'},
    {'display': '10:00 PM', 'value': '22:00'},
    {'display': '11:00 PM', 'value': '23:00'},
    {'display': '12:00 AM', 'value': '00:00'},
  ];

  final List<Map<String, dynamic>> _reminderOptions = [
    {'display': '60 min', 'value': 60},
    {'display': '90 min', 'value': 90},
    {'display': '120 min', 'value': 120},
    {'display': '180 min', 'value': 180},
  ];

  final List<int> _cupSizeOptions = [100, 150, 200, 250, 500];

  @override
  void initState() {
    super.initState();
    _currentStep = widget.step;
  }

  // Dynamic daily target recommendation logic (matches calculatedDailyTarget in provider)
  int get _calculatedTarget {
    int baseline = 2500;
    if (_gender.toLowerCase() == 'female') {
      baseline = 2000;
    } else if (_gender.toLowerCase() == 'male') {
      baseline = 3000;
    }

    if (_age < 30) {
      baseline += 100;
    } else if (_age > 55) {
      baseline -= 100;
    }
    return baseline;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () {
            if (_currentStep > 1) {
              setState(() => _currentStep--);
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        title: Text(
          'Set up Hydrio',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Step indicator & progress bar
                        Text(
                          'Step $_currentStep of 3',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _currentStep / 3.0,
                            backgroundColor: colorScheme.primaryContainer,
                            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                            minHeight: 6,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Wizard Step Content
                        Expanded(
                          child: _buildStepContent(theme, colorScheme),
                        ),

                        const SizedBox(height: 24),

                        // Bottom Navigation Action Button
                        ElevatedButton(
                          style: theme.elevatedButtonTheme.style?.copyWith(
                            shape: MaterialStateProperty.all(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16.0),
                              ),
                            ),
                          ),
                          onPressed: () async {
                            if (_currentStep < 3) {
                              setState(() => _currentStep++);
                            } else {
                              // Save configurations to settings in provider and complete onboarding
                              final provider = context.read<HydrioProvider>();
                              final newSettings = provider.settings.copyWith(
                                gender: _gender,
                                age: _age,
                                wakeTime: _wakeTime,
                                sleepTime: _sleepTime,
                                reminderIntervalMin: _reminderIntervalMin,
                                cupSizeMl: _cupSizeMl,
                                dailyTargetMl: _calculatedTarget,
                                manualOverride: false, // target calculated dynamically initially
                              );

                              await provider.updateSettings(newSettings);
                              await provider.completeOnboarding();

                              if (context.mounted) {
                                Navigator.of(context).popUntil((route) => route.isFirst);
                              }
                            }
                          },
                          child: Text(
                            _currentStep < 3 ? 'Continue' : 'Start Tracking',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStepContent(ThemeData theme, ColorScheme colorScheme) {
    switch (_currentStep) {
      case 1:
        return _buildStep1(theme, colorScheme);
      case 2:
        return _buildStep2(theme, colorScheme);
      case 3:
        return _buildStep3(theme, colorScheme);
      default:
        return const SizedBox.shrink();
    }
  }

  // --- Step 1: Personal Details (Gender & Age) ---
  Widget _buildStep1(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Gender Title
        Text(
          'Gender',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        // Gender Selectors Row
        Row(
          children: _genderOptions.map((gender) {
            final isActive = _gender == gender;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: InkWell(
                  onTap: () => setState(() => _gender = gender),
                  borderRadius: BorderRadius.circular(16.0),
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: isActive ? colorScheme.primary : theme.cardTheme.color,
                      borderRadius: BorderRadius.circular(16.0),
                      border: isActive
                          ? null
                          : Border.all(color: colorScheme.onSurface.withOpacity(0.12)),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      gender,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: isActive ? colorScheme.onPrimary : colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 32),

        // Age Title
        Text(
          'Age',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        // Age Selector Card
        Container(
          width: double.infinity,
          height: 72,
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: colorScheme.onSurface.withOpacity(0.08)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Decrement Button
                InkWell(
                  onTap: _age > 1 ? () => setState(() => _age--) : null,
                  borderRadius: BorderRadius.circular(24.0),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: colorScheme.onSurface.withOpacity(0.06),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.remove, color: colorScheme.onSurface),
                  ),
                ),

                // Age Display
                Text(
                  '$_age',
                  style: theme.textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),

                // Increment Button
                InkWell(
                  onTap: _age < 120 ? () => setState(() => _age++) : null,
                  borderRadius: BorderRadius.circular(24.0),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: colorScheme.onSurface.withOpacity(0.06),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.add, color: colorScheme.onSurface),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- Step 2: Wake & Sleep Time & Reminder Interval ---
  Widget _buildStep2(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Wake-up Time Header
        Text(
          'Wake-up time',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _wakeTimeOptions.map((time) {
            final isActive = _wakeTime == time;
            return _buildSelectionOption(time, isActive, () {
              setState(() => _wakeTime = time);
            }, theme, colorScheme);
          }).toList(),
        ),
        const SizedBox(height: 24),

        // Sleep Time Header
        Text(
          'Sleep time',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _sleepTimeOptions.map((opt) {
            final isActive = _sleepTime == opt['value'];
            return _buildSelectionOption(opt['display']!, isActive, () {
              setState(() => _sleepTime = opt['value']!);
            }, theme, colorScheme);
          }).toList(),
        ),
        const SizedBox(height: 24),

        // Reminder Interval Header
        Text(
          'Reminder interval',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _reminderOptions.map((opt) {
            final isActive = _reminderIntervalMin == opt['value'];
            return _buildSelectionOption(opt['display']!, isActive, () {
              setState(() => _reminderIntervalMin = opt['value'] as int);
            }, theme, colorScheme);
          }).toList(),
        ),
      ],
    );
  }

  // --- Step 3: Usual Cup Size & Target Presentation ---
  Widget _buildStep3(ThemeData theme, ColorScheme colorScheme) {
    final formattedTarget = NumberFormat('#,###').format(_calculatedTarget);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cup Size Selection Header
        Text(
          'Usual cup / bottle size',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _cupSizeOptions.map((size) {
            final isActive = _cupSizeMl == size;
            return _buildSelectionOption('$size ml', isActive, () {
              setState(() => _cupSizeMl = size);
            }, theme, colorScheme);
          }).toList(),
        ),
        const SizedBox(height: 40),

        // Target Presentation Panel Card
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: colorScheme.onSurface.withOpacity(0.08)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
          child: Column(
            children: [
              Text(
                'YOUR DAILY TARGET',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  fontSize: 12.0,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '$formattedTarget mL',
                style: theme.textTheme.displayLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: colorScheme.onSurface,
                  fontSize: 34.0,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Based on your profile — you can change this anytime',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 13.0,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Common UI builder helper for grid-like selectable pills
  Widget _buildSelectionOption(
    String displayLabel,
    bool isActive,
    VoidCallback onTap,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
        decoration: BoxDecoration(
          color: isActive ? colorScheme.primary : theme.cardTheme.color,
          borderRadius: BorderRadius.circular(16.0),
          border: isActive
              ? null
              : Border.all(color: colorScheme.onSurface.withOpacity(0.12)),
        ),
        child: Text(
          displayLabel,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isActive ? colorScheme.onPrimary : colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
