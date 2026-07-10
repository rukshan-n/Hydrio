import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/providers/hydrio_provider.dart';
import '../../core/models/settings_model.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Common theme color references
  Color _getPanelColor(ThemeData theme) {
    return theme.brightness == Brightness.light
        ? const Color(0xffF2F5F8)
        : const Color(0xff1B2430);
  }

  Color _getInkColor(ThemeData theme) {
    return theme.brightness == Brightness.light
        ? const Color(0xff1F2933)
        : const Color(0xffE8EDF2);
  }

  Color _getMutedColor(ThemeData theme) {
    return theme.brightness == Brightness.light
        ? const Color(0xff7B8794)
        : const Color(0xff9AA5B1);
  }

  Color _getDangerColor(ThemeData theme) {
    return theme.brightness == Brightness.light
        ? const Color(0xffC5221F)
        : const Color(0xffF08A86);
  }

  // Recommendation calculator for automatic daily target
  int _calculateRecommendedTarget(String gender, int age) {
    int baseline = 2500;
    if (gender.toLowerCase() == 'female') {
      baseline = 2000;
    } else if (gender.toLowerCase() == 'male') {
      baseline = 3000;
    }

    if (age < 30) {
      baseline += 100;
    } else if (age > 55) {
      baseline -= 100;
    }
    return baseline;
  }

  // Handle Gender/Age changes with Manual Override checks
  Future<void> _handleGenderAgeChange(
    BuildContext context,
    HydrioProvider provider,
    HydrioSettings newSettings,
  ) async {
    final oldSettings = provider.settings;
    if (oldSettings.manualOverride) {
      // Show confirmation dialog to reset daily target
      final bool? reset = await showDialog<bool>(
        context: context,
        builder: (context) => _buildConfirmDialog(
          context,
          title: 'Reset Daily Target?',
          message:
              'You previously configured a custom daily target. Would you like to reset it to the recommended automatic target based on your new profile?',
          confirmLabel: 'Reset to Auto',
          cancelLabel: 'Keep Custom',
          isDestructive: false,
        ),
      );

      if (reset == true) {
        final recTarget = _calculateRecommendedTarget(newSettings.gender, newSettings.age);
        await provider.updateSettings(newSettings.copyWith(
          dailyTargetMl: recTarget,
          manualOverride: false,
        ));
      } else {
        await provider.updateSettings(newSettings);
      }
    } else {
      final recTarget = _calculateRecommendedTarget(newSettings.gender, newSettings.age);
      await provider.updateSettings(newSettings.copyWith(
        dailyTargetMl: recTarget,
        manualOverride: false,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<HydrioProvider>();
    final settings = provider.settings;

    // Unit string conversion
    String displayUnit = 'mL';
    if (settings.unit == 'l') {
      displayUnit = 'L';
    } else if (settings.unit == 'oz') {
      displayUnit = 'fl oz';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Preference Group List Card
                    Container(
                      decoration: BoxDecoration(
                        color: _getPanelColor(theme),
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                      child: Column(
                        children: [
                          _buildSettingRow(
                            label: 'Gender',
                            value: settings.gender,
                            onTap: () => _showGenderPicker(context, provider, settings),
                          ),
                          _buildDivider(theme),
                          _buildSettingRow(
                            label: 'Age',
                            value: '${settings.age}',
                            onTap: () => _showAgePicker(context, provider, settings),
                          ),
                          _buildDivider(theme),
                          _buildSettingRow(
                            label: 'Daily target',
                            value: provider.formatVolume(settings.dailyTargetMl),
                            onTap: () => _showDailyTargetPicker(context, provider, settings),
                          ),
                          _buildDivider(theme),
                          _buildSettingRow(
                            label: 'Reminder window',
                            value: '${settings.wakeTime} – ${settings.sleepTime}',
                            onTap: () => _showReminderWindowPicker(context, provider, settings),
                          ),
                          _buildDivider(theme),
                          _buildSettingRow(
                            label: 'Cup / bottle size',
                            value: provider.formatVolume(settings.cupSizeMl),
                            onTap: () => _showCupSizePicker(context, provider, settings),
                          ),
                          _buildDivider(theme),
                          _buildSettingRow(
                            label: 'Unit (mL/L)',
                            value: displayUnit,
                            onTap: () => _showUnitPicker(context, provider, settings),
                          ),
                          _buildDivider(theme),
                          _buildSettingRow(
                            label: 'Notifications',
                            value: settings.notificationsOn ? 'On' : 'Off',
                            onTap: () => _showNotificationsToggle(context, provider, settings),
                          ),
                          _buildDivider(theme),
                          _buildSettingRow(
                            label: 'Export email',
                            value: settings.exportEmail.isNotEmpty
                                ? settings.exportEmail
                                : 'Not set',
                            onTap: () => _showExportEmailPicker(context, provider, settings),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Destructive Clear History Action
                    InkWell(
                      onTap: () => _showClearHistoryConfirmation(context, provider),
                      borderRadius: BorderRadius.circular(16.0),
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          color: _getDangerColor(theme).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16.0),
                          border: Border.all(
                            color: _getDangerColor(theme).withOpacity(0.3),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Clear local history',
                          style: TextStyle(
                            color: _getDangerColor(theme),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Pinned Privacy Note
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Your data stays on your phone.',
                style: TextStyle(
                  color: _getMutedColor(theme),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Setting Row Builder ---
  Widget _buildSettingRow({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.0),
      child: Container(
        constraints: const BoxConstraints(minHeight: 52),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: _getInkColor(theme),
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                color: _getMutedColor(theme),
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: _getMutedColor(theme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(ThemeData theme) {
    return Divider(
      height: 1,
      thickness: 1,
      color: theme.brightness == Brightness.light
          ? Colors.black.withOpacity(0.04)
          : Colors.white.withOpacity(0.04),
    );
  }

  // --- Reusable Styled Dialog Wrapper ---
  Widget _buildDialogWrapper({
    required String title,
    required Widget content,
    required VoidCallback onSave,
    String saveLabel = 'Save',
  }) {
    final theme = Theme.of(context);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      backgroundColor: theme.scaffoldBackgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _getInkColor(theme),
              ),
            ),
            const SizedBox(height: 20),
            content,
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: _getMutedColor(theme),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(80, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.brightness == Brightness.light
                        ? Colors.white
                        : Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  onPressed: onSave,
                  child: Text(
                    saveLabel,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- Confirmation Dialog ---
  Widget _buildConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    required String cancelLabel,
    required bool isDestructive,
  }) {
    final theme = Theme.of(context);
    final confirmColor = isDestructive ? _getDangerColor(theme) : theme.colorScheme.primary;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      backgroundColor: theme.scaffoldBackgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _getInkColor(theme),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                color: _getMutedColor(theme),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    cancelLabel,
                    style: TextStyle(
                      color: _getMutedColor(theme),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(80, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    backgroundColor: confirmColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(
                    confirmLabel,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- Gender Picker Modal ---
  void _showGenderPicker(
    BuildContext context,
    HydrioProvider provider,
    HydrioSettings settings,
  ) {
    String localGender = settings.gender;
    final List<String> genders = ['Female', 'Male', 'Other'];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return _buildDialogWrapper(
              title: 'Select Gender',
              content: Row(
                children: genders.map((g) {
                  final isSelected = localGender == g;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: InkWell(
                        onTap: () => setModalState(() => localGender = g),
                        borderRadius: BorderRadius.circular(12.0),
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : _getPanelColor(Theme.of(context)),
                            borderRadius: BorderRadius.circular(12.0),
                            border: isSelected
                                ? null
                                : Border.all(
                                    color: _getMutedColor(Theme.of(context)).withOpacity(0.2),
                                  ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            g,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : _getInkColor(Theme.of(context)),
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              onSave: () {
                Navigator.of(context).pop();
                _handleGenderAgeChange(
                  context,
                  provider,
                  settings.copyWith(gender: localGender),
                );
              },
            );
          },
        );
      },
    );
  }

  // --- Age Picker Modal ---
  void _showAgePicker(
    BuildContext context,
    HydrioProvider provider,
    HydrioSettings settings,
  ) {
    int localAge = settings.age;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return _buildDialogWrapper(
              title: 'Select Age',
              content: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: localAge > 13
                        ? () => setModalState(() => localAge--)
                        : null,
                    icon: const Icon(Icons.remove_circle_outline, size: 36),
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 24),
                  Text(
                    '$localAge',
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 24),
                  IconButton(
                    onPressed: localAge < 100
                        ? () => setModalState(() => localAge++)
                        : null,
                    icon: const Icon(Icons.add_circle_outline, size: 36),
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
              onSave: () {
                Navigator.of(context).pop();
                _handleGenderAgeChange(
                  context,
                  provider,
                  settings.copyWith(age: localAge),
                );
              },
            );
          },
        );
      },
    );
  }

  // --- Daily Target Picker Modal ---
  void _showDailyTargetPicker(
    BuildContext context,
    HydrioProvider provider,
    HydrioSettings settings,
  ) {
    final TextEditingController targetController = TextEditingController();
    String? localError;

    // Convert existing target for controller presentation
    final isOz = settings.unit == 'oz';
    final isL = settings.unit == 'l';
    if (isL) {
      targetController.text = (settings.dailyTargetMl / 1000.0).toStringAsFixed(1);
    } else if (isOz) {
      targetController.text = provider.toOz(settings.dailyTargetMl).toStringAsFixed(1);
    } else {
      targetController.text = '${settings.dailyTargetMl}';
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return _buildDialogWrapper(
              title: 'Edit Daily Target',
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: targetController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      hintText: 'Enter target',
                      suffixText: provider.unitSuffix,
                      errorText: localError,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    onChanged: (val) {
                      final double? parsed = double.tryParse(val);
                      if (parsed == null || parsed <= 0) {
                        setModalState(() => localError = 'Please enter a valid amount');
                        return;
                      }

                      int ml;
                      if (isL) {
                        ml = (parsed * 1000).round();
                      } else if (isOz) {
                        ml = provider.toMl(parsed);
                      } else {
                        ml = parsed.round();
                      }

                      if (ml < 500 || ml > 6000) {
                        // Dynamic bounds formatting based on user unit preference
                        String limitStr = '500 mL – 6,000 mL';
                        if (isL) {
                          limitStr = '0.5 L – 6.0 L';
                        } else if (isOz) {
                          limitStr = '${provider.toOz(500).toStringAsFixed(1)} fl oz – ${provider.toOz(6000).toStringAsFixed(1)} fl oz';
                        }
                        setModalState(() {
                          localError = 'Target must be between $limitStr';
                        });
                      } else {
                        setModalState(() => localError = null);
                      }
                    },
                  ),
                ],
              ),
              onSave: () {
                final double? parsed = double.tryParse(targetController.text);
                if (parsed == null || parsed <= 0) return;

                int ml;
                if (isL) {
                  ml = (parsed * 1000).round();
                } else if (isOz) {
                  ml = provider.toMl(parsed);
                } else {
                  ml = parsed.round();
                }

                if (ml < 500 || ml > 6000) return;

                provider.updateSettings(settings.copyWith(
                  dailyTargetMl: ml,
                  manualOverride: true,
                ));
                Navigator.of(context).pop();
              },
            );
          },
        );
      },
    );
  }

  // --- Reminder Window Picker Modal ---
  void _showReminderWindowPicker(
    BuildContext context,
    HydrioProvider provider,
    HydrioSettings settings,
  ) {
    String localWake = settings.wakeTime;
    String localSleep = settings.sleepTime;
    String? localError;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            // Sane bounds validation check
            void validateTimes() {
              try {
                final wakeParts = localWake.split(':');
                final sleepParts = localSleep.split(':');

                final wakeMin = int.parse(wakeParts[0]) * 60 + int.parse(wakeParts[1]);
                final sleepMin = int.parse(sleepParts[0]) * 60 + int.parse(sleepParts[1]);

                var awakeDurationMin = sleepMin - wakeMin;
                if (sleepMin < wakeMin) {
                  awakeDurationMin = (24 * 60 - wakeMin) + sleepMin;
                }

                if (awakeDurationMin < 4 * 60) {
                  setModalState(() => localError = 'Awake window must be at least 4 hours');
                } else if (awakeDurationMin > 20 * 60) {
                  setModalState(() => localError = 'Awake window cannot exceed 20 hours');
                } else {
                  setModalState(() => localError = null);
                }
              } catch (_) {
                setModalState(() => localError = 'Invalid time bounds');
              }
            }

            Future<void> pickTime(bool isWake) async {
              final activeTime = isWake ? localWake : localSleep;
              final parts = activeTime.split(':');
              final tod = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));

              final picked = await showTimePicker(
                context: context,
                initialTime: tod,
              );

              if (picked != null) {
                final hourStr = picked.hour.toString().padLeft(2, '0');
                final minStr = picked.minute.toString().padLeft(2, '0');
                setModalState(() {
                  if (isWake) {
                    localWake = '$hourStr:$minStr';
                  } else {
                    localSleep = '$hourStr:$minStr';
                  }
                });
                validateTimes();
              }
            }

            return _buildDialogWrapper(
              title: 'Reminder Schedule',
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => pickTime(true),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.all(16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Column(
                            children: [
                              const Text('WAKE UP'),
                              const SizedBox(height: 8),
                              Text(
                                localWake,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => pickTime(false),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.all(16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Column(
                            children: [
                              const Text('SLEEP'),
                              const SizedBox(height: 8),
                              Text(
                                localSleep,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (localError != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      localError!,
                      style: TextStyle(
                        color: _getDangerColor(Theme.of(context)),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
              onSave: () {
                if (localError != null) return;
                provider.updateSettings(settings.copyWith(
                  wakeTime: localWake,
                  sleepTime: localSleep,
                ));
                Navigator.of(context).pop();
              },
            );
          },
        );
      },
    );
  }

  // --- Cup / Bottle Size Picker Modal ---
  void _showCupSizePicker(
    BuildContext context,
    HydrioProvider provider,
    HydrioSettings settings,
  ) {
    final TextEditingController controller = TextEditingController();
    String? localError;

    final isOz = settings.unit == 'oz';
    final isL = settings.unit == 'l';
    if (isL) {
      controller.text = (settings.cupSizeMl / 1000.0).toStringAsFixed(2);
    } else if (isOz) {
      controller.text = provider.toOz(settings.cupSizeMl).toStringAsFixed(1);
    } else {
      controller.text = '${settings.cupSizeMl}';
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return _buildDialogWrapper(
              title: 'Edit Custom Cup Size',
              content: TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  hintText: 'Enter cup size',
                  suffixText: provider.unitSuffix,
                  errorText: localError,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                onChanged: (val) {
                  final double? parsed = double.tryParse(val);
                  if (parsed == null || parsed <= 0) {
                    setModalState(() => localError = 'Must be a positive amount');
                    return;
                  }

                  int ml;
                  if (isL) {
                    ml = (parsed * 1000).round();
                  } else if (isOz) {
                    ml = provider.toMl(parsed);
                  } else {
                    ml = parsed.round();
                  }

                  if (ml <= 0) {
                    setModalState(() => localError = 'Cup size must be greater than 0');
                  } else {
                    setModalState(() => localError = null);
                  }
                },
              ),
              onSave: () {
                final double? parsed = double.tryParse(controller.text);
                if (parsed == null || parsed <= 0) return;

                int ml;
                if (isL) {
                  ml = (parsed * 1000).round();
                } else if (isOz) {
                  ml = provider.toMl(parsed);
                } else {
                  ml = parsed.round();
                }

                if (ml <= 0) return;

                provider.updateSettings(settings.copyWith(cupSizeMl: ml));
                Navigator.of(context).pop();
              },
            );
          },
        );
      },
    );
  }

  // --- Unit Picker Modal ---
  void _showUnitPicker(
    BuildContext context,
    HydrioProvider provider,
    HydrioSettings settings,
  ) {
    String localUnit = settings.unit;
    final List<Map<String, String>> units = [
      {'value': 'ml', 'display': 'mL (Milliliters)'},
      {'value': 'l', 'display': 'L (Liters)'},
      {'value': 'oz', 'display': 'fl oz (Ounces)'},
    ];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return _buildDialogWrapper(
              title: 'Select Unit',
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: units.map((u) {
                  final isSelected = localUnit == u['value'];
                  return RadioListTile<String>(
                    title: Text(
                      u['display']!,
                      style: TextStyle(
                        color: _getInkColor(Theme.of(context)),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    value: u['value']!,
                    groupValue: localUnit,
                    activeColor: Theme.of(context).colorScheme.primary,
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() => localUnit = val);
                      }
                    },
                  );
                }).toList(),
              ),
              onSave: () {
                provider.updateSettings(settings.copyWith(unit: localUnit));
                Navigator.of(context).pop();
              },
            );
          },
        );
      },
    );
  }

  // --- Notifications Toggle Modal ---
  void _showNotificationsToggle(
    BuildContext context,
    HydrioProvider provider,
    HydrioSettings settings,
  ) {
    bool localOn = settings.notificationsOn;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return _buildDialogWrapper(
              title: 'Hydration Reminders',
              content: SegmentedButton<bool>(
                showSelectedIcon: false,
                style: SegmentedButton.styleFrom(
                  backgroundColor: _getPanelColor(Theme.of(context)),
                  selectedBackgroundColor: Theme.of(context).colorScheme.primary,
                  selectedForegroundColor: Colors.white,
                  foregroundColor: _getMutedColor(Theme.of(context)),
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                segments: const [
                  ButtonSegment(value: true, label: Text('On')),
                  ButtonSegment(value: false, label: Text('Off')),
                ],
                selected: {localOn},
                onSelectionChanged: (selection) {
                  setModalState(() => localOn = selection.first);
                },
              ),
              onSave: () {
                provider.updateSettings(settings.copyWith(notificationsOn: localOn));
                Navigator.of(context).pop();
              },
            );
          },
        );
      },
    );
  }

  // --- Export Email Picker Modal ---
  void _showExportEmailPicker(
    BuildContext context,
    HydrioProvider provider,
    HydrioSettings settings,
  ) {
    final TextEditingController controller = TextEditingController(text: settings.exportEmail);
    String? localError;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return _buildDialogWrapper(
              title: 'Export Email',
              content: TextField(
                controller: controller,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'Enter email address',
                  errorText: localError,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                onChanged: (val) {
                  if (val.isEmpty) {
                    setModalState(() => localError = null); // allowed to clear
                    return;
                  }
                  final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                  if (!emailRegex.hasMatch(val)) {
                    setModalState(() => localError = 'Please enter a valid email format');
                  } else {
                    setModalState(() => localError = null);
                  }
                },
              ),
              onSave: () {
                final val = controller.text;
                if (val.isNotEmpty) {
                  final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                  if (!emailRegex.hasMatch(val)) return;
                }
                provider.updateSettings(settings.copyWith(exportEmail: val));
                Navigator.of(context).pop();
              },
            );
          },
        );
      },
    );
  }

  // --- Clear History Confirmation Dialogue ---
  Future<void> _showClearHistoryConfirmation(
    BuildContext context,
    HydrioProvider provider,
  ) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => _buildConfirmDialog(
        context,
        title: 'Clear Local History?',
        message:
            'Are you sure you want to delete all hydration logs and daily summaries? This action is permanent and cannot be undone.',
        confirmLabel: 'Clear All',
        cancelLabel: 'Keep Logs',
        isDestructive: true,
      ),
    );

    if (confirm == true) {
      await provider.clearHistoryOnly();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Local hydration history cleared successfully! 👍'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
