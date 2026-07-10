class HydrioSettings {
  final String gender;
  final int age;
  final String wakeTime; // Format: "HH:mm"
  final String sleepTime; // Format: "HH:mm"
  final int reminderIntervalMin;
  final int cupSizeMl;
  final int dailyTargetMl;
  final bool manualOverride;
  final String unit; // "ml" or "fl oz"
  final bool notificationsOn;
  final bool silentReminders;
  final String exportEmail;
  final String theme; // "system", "light", "dark"

  const HydrioSettings({
    required this.gender,
    required this.age,
    required this.wakeTime,
    required this.sleepTime,
    required this.reminderIntervalMin,
    required this.cupSizeMl,
    required this.dailyTargetMl,
    required this.manualOverride,
    required this.unit,
    required this.notificationsOn,
    required this.silentReminders,
    required this.exportEmail,
    required this.theme,
  });

  factory HydrioSettings.defaultSettings() {
    return const HydrioSettings(
      gender: 'Other',
      age: 30,
      wakeTime: '07:00',
      sleepTime: '22:00',
      reminderIntervalMin: 120,
      cupSizeMl: 250,
      dailyTargetMl: 2000,
      manualOverride: false,
      unit: 'ml',
      notificationsOn: true,
      silentReminders: false,
      exportEmail: '',
      theme: 'system',
    );
  }

  HydrioSettings copyWith({
    String? gender,
    int? age,
    String? wakeTime,
    String? sleepTime,
    int? reminderIntervalMin,
    int? cupSizeMl,
    int? dailyTargetMl,
    bool? manualOverride,
    String? unit,
    bool? notificationsOn,
    bool? silentReminders,
    String? exportEmail,
    String? theme,
  }) {
    return HydrioSettings(
      gender: gender ?? this.gender,
      age: age ?? this.age,
      wakeTime: wakeTime ?? this.wakeTime,
      sleepTime: sleepTime ?? this.sleepTime,
      reminderIntervalMin: reminderIntervalMin ?? this.reminderIntervalMin,
      cupSizeMl: cupSizeMl ?? this.cupSizeMl,
      dailyTargetMl: dailyTargetMl ?? this.dailyTargetMl,
      manualOverride: manualOverride ?? this.manualOverride,
      unit: unit ?? this.unit,
      notificationsOn: notificationsOn ?? this.notificationsOn,
      silentReminders: silentReminders ?? this.silentReminders,
      exportEmail: exportEmail ?? this.exportEmail,
      theme: theme ?? this.theme,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'gender': gender,
      'age': age,
      'wake_time': wakeTime,
      'sleep_time': sleepTime,
      'reminder_interval_min': reminderIntervalMin,
      'cup_size_ml': cupSizeMl,
      'daily_target_ml': dailyTargetMl,
      'manual_override': manualOverride ? 1 : 0,
      'unit': unit,
      'notifications_on': notificationsOn ? 1 : 0,
      'silent_reminders': silentReminders ? 1 : 0,
      'export_email': exportEmail,
      'theme': theme,
    };
  }

  factory HydrioSettings.fromMap(Map<String, dynamic> map) {
    return HydrioSettings(
      gender: map['gender'] as String? ?? 'Other',
      age: map['age'] as int? ?? 30,
      wakeTime: map['wake_time'] as String? ?? '07:00',
      sleepTime: map['sleep_time'] as String? ?? '22:00',
      reminderIntervalMin: map['reminder_interval_min'] as int? ?? 120,
      cupSizeMl: map['cup_size_ml'] as int? ?? 250,
      dailyTargetMl: map['daily_target_ml'] as int? ?? 2000,
      manualOverride: (map['manual_override'] is int)
          ? (map['manual_override'] as int) == 1
          : (map['manual_override'] as bool? ?? false),
      unit: map['unit'] as String? ?? 'ml',
      notificationsOn: (map['notifications_on'] is int)
          ? (map['notifications_on'] as int) == 1
          : (map['notifications_on'] as bool? ?? true),
      silentReminders: (map['silent_reminders'] is int)
          ? (map['silent_reminders'] as int) == 1
          : (map['silent_reminders'] as bool? ?? false),
      exportEmail: map['export_email'] as String? ?? '',
      theme: map['theme'] as String? ?? 'system',
    );
  }
}
