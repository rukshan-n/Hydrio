import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../models/settings_model.dart';
import '../models/drink_log_model.dart';
import '../models/daily_summary_model.dart';
import '../models/history_data_model.dart';
import '../database/db_helper.dart';
import '../notifications/notification_service.dart';
import '../utils/export_helper.dart';

class HydrioProvider with ChangeNotifier {
  final DbHelper _db = DbHelper.instance;
  late SharedPreferences _prefs;

  // State Variables
  HydrioSettings _settings = HydrioSettings.defaultSettings();
  List<DrinkLog> _todayLogs = [];
  List<DailySummary> _historySummaries = [];
  List<DrinkLog> _allHistoryLogs = [];
  DailySummary? _todaySummary;

  // Undo Delete State
  DrinkLog? _lastDeletedLog;

  // Getters
  HydrioSettings get settings => _settings;
  List<DrinkLog> get todayLogs => _todayLogs;
  List<DailySummary> get historySummaries => _historySummaries;
  List<DrinkLog> get allHistoryLogs => _allHistoryLogs;
  DailySummary? get todaySummary => _todaySummary;
  bool get hasUndoItem => _lastDeletedLog != null;

  /// Returns the user's weekly hydration level computed over a rolling 7-day window.
  WeeklyHydrationLevel get weeklyHydrationLevel {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    double totalIntake = 0.0;
    double totalTarget = 0.0;

    for (int i = 6; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      final dayKey = DateFormat('yyyy-MM-dd').format(date);

      if (dayKey == todayKey) {
        if (_todaySummary != null) {
          totalIntake += _todaySummary!.totalMl;
          totalTarget += _todaySummary!.targetMl;
        } else {
          totalTarget += calculatedDailyTarget;
        }
      } else {
        final matches = _historySummaries.where((s) => s.dayKey == dayKey);
        if (matches.isNotEmpty) {
          totalIntake += matches.first.totalMl;
          totalTarget += matches.first.targetMl;
        }
      }
    }

    if (totalTarget <= 0) {
      return WeeklyHydrationLevel.mid;
    }

    final percentage = totalIntake / totalTarget;
    if (percentage < 0.50) {
      return WeeklyHydrationLevel.low;
    } else if (percentage < 0.80) {
      return WeeklyHydrationLevel.mid;
    } else {
      return WeeklyHydrationLevel.high;
    }
  }

  // Helper to get today's key format "YYYY-MM-DD"
  String get todayKey => DateFormat('yyyy-MM-dd').format(DateTime.now());

  /// Initialize state from local databases and SharedPreferences
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadSettingsFromPrefs();
    await loadTodayData();
    await loadHistoryData();
  }

  // --- Settings Persistence ---

  Future<void> _loadSettingsFromPrefs() async {
    try {
      final gender = _prefs.getString('gender') ?? 'Other';
      final age = _prefs.getInt('age') ?? 30;
      final wakeTime = _prefs.getString('wake_time') ?? '07:00';
      final sleepTime = _prefs.getString('sleep_time') ?? '22:00';
      final reminderInterval = _prefs.getInt('reminder_interval_min') ?? 120;
      final cupSize = _prefs.getInt('cup_size_ml') ?? 250;
      final dailyTarget = _prefs.getInt('daily_target_ml') ?? 2000;
      final manualOverride = _prefs.getBool('manual_override') ?? false;
      final unit = _prefs.getString('unit') ?? 'ml';
      final notificationsOn = _prefs.getBool('notifications_on') ?? true;
      final silentReminders = _prefs.getBool('silent_reminders') ?? false;
      final exportEmail = _prefs.getString('export_email') ?? '';
      final theme = _prefs.getString('theme') ?? 'system';
      final onboardingComplete = _prefs.getBool('onboarding_complete') ?? false;

      _settings = HydrioSettings(
        gender: gender,
        age: age,
        wakeTime: wakeTime,
        sleepTime: sleepTime,
        reminderIntervalMin: reminderInterval,
        cupSizeMl: cupSize,
        dailyTargetMl: dailyTarget,
        manualOverride: manualOverride,
        unit: unit,
        notificationsOn: notificationsOn,
        silentReminders: silentReminders,
        exportEmail: exportEmail,
        theme: theme,
        onboardingComplete: onboardingComplete,
      );
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading settings from SharedPreferences: $e');
      }
    }
  }

  Future<void> updateSettings(HydrioSettings newSettings) async {
    _settings = newSettings;
    notifyListeners();

    // Persist to SharedPreferences
    await _prefs.setString('gender', _settings.gender);
    await _prefs.setInt('age', _settings.age);
    await _prefs.setString('wake_time', _settings.wakeTime);
    await _prefs.setString('sleep_time', _settings.sleepTime);
    await _prefs.setInt('reminder_interval_min', _settings.reminderIntervalMin);
    await _prefs.setInt('cup_size_ml', _settings.cupSizeMl);
    await _prefs.setInt('daily_target_ml', _settings.dailyTargetMl);
    await _prefs.setBool('manual_override', _settings.manualOverride);
    await _prefs.setString('unit', _settings.unit);
    await _prefs.setBool('notifications_on', _settings.notificationsOn);
    await _prefs.setBool('silent_reminders', _settings.silentReminders);
    await _prefs.setString('export_email', _settings.exportEmail);
    await _prefs.setString('theme', _settings.theme);
    await _prefs.setBool('onboarding_complete', _settings.onboardingComplete);

    // Whenever settings are updated, recalculate/re-schedule notifications
    await NotificationService.instance.scheduleWindowReminders(_settings);

    // Also update today's daily target in database if it changed
    await _syncTodaySummary();
  }

  /// Sets onboarding completion status to true and persists it.
  Future<void> completeOnboarding() async {
    _settings = _settings.copyWith(onboardingComplete: true);
    notifyListeners();
    await _prefs.setBool('onboarding_complete', true);
  }

  /// Calculates dynamic daily water target if manual override is disabled.
  int get calculatedDailyTarget {
    if (_settings.manualOverride) {
      return _settings.dailyTargetMl;
    }

    // Recommendation logic:
    // Standard guideline: Females: ~2000ml, Males: ~3000ml, Other/Default: ~2500ml
    // Age adjustments:
    // Younger adults (< 30) have higher metabolic rate (+100ml)
    // Older adults (> 55) require slightly less fluid baseline (-100ml)
    int baseline = 2500;
    if (_settings.gender.toLowerCase() == 'female') {
      baseline = 2000;
    } else if (_settings.gender.toLowerCase() == 'male') {
      baseline = 3000;
    }

    if (_settings.age < 30) {
      baseline += 100;
    } else if (_settings.age > 55) {
      baseline -= 100;
    }

    return baseline;
  }

  // --- Data Loading ---

  Future<void> loadTodayData() async {
    final key = todayKey;
    _todayLogs = await _db.getDrinkLogsForDay(key);

    final summary = await _db.getDailySummary(key);
    if (summary != null) {
      _todaySummary = summary;
    } else {
      // Initialize today's summary in SQLite if missing
      final target = calculatedDailyTarget;
      _todaySummary = DailySummary(
        dayKey: key,
        targetMl: target,
        totalMl: 0,
        completionPct: 0.0,
        status: 'missed', // default status
      );
      await _db.upsertDailySummary(_todaySummary!);
    }
    notifyListeners();
  }

  Future<void> loadHistoryData() async {
    _historySummaries = await _db.getAllDailySummaries();
    _allHistoryLogs = await _db.getAllDrinkLogs();
    notifyListeners();
  }

  // --- Drink Log Actions ---

  /// Logs a drink with a given volume. If null, logs default cup size.
  Future<void> logDrink([int? amountMl]) async {
    final logAmount = amountMl ?? _settings.cupSizeMl;
    final log = DrinkLog(
      amountMl: logAmount,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      dayKey: todayKey,
    );

    await _db.insertDrinkLog(log);
    await _syncTodaySummary();
    await loadHistoryData();

    // After logging a drink, we can reschedule alarms to shift reminders out.
    await NotificationService.instance.scheduleWindowReminders(_settings);
  }

  /// Deletes a logged drink and updates the summary (supporting undo state).
  Future<void> deleteDrink(int id) async {
    // Find the log in our current cache
    final index = _todayLogs.indexWhere((element) => element.id == id);
    if (index != -1) {
      _lastDeletedLog = _todayLogs[index];
    }

    await _db.deleteDrinkLog(id);
    await _syncTodaySummary();
    await loadHistoryData();

    // Reschedule alerts since logs have been altered
    await NotificationService.instance.scheduleWindowReminders(_settings);
  }

  /// Restores the last deleted drink log.
  Future<void> undoDelete() async {
    if (_lastDeletedLog == null) return;

    final logToRestore = DrinkLog(
      amountMl: _lastDeletedLog!.amountMl,
      timestamp: _lastDeletedLog!.timestamp,
      dayKey: _lastDeletedLog!.dayKey,
    );

    await _db.insertDrinkLog(logToRestore);
    _lastDeletedLog = null; // Clear undo cache

    await _syncTodaySummary();
    await loadHistoryData();

    await NotificationService.instance.scheduleWindowReminders(_settings);
  }

  /// Clears the undo delete cache state
  void clearUndoCache() {
    _lastDeletedLog = null;
    notifyListeners();
  }

  // --- Internal Sync Logic ---

  Future<void> _syncTodaySummary() async {
    final key = todayKey;
    final logs = await _db.getDrinkLogsForDay(key);
    _todayLogs = logs;

    final total = logs.fold<int>(0, (sum, log) => sum + log.amountMl);
    final target = calculatedDailyTarget;
    final pct = target > 0 ? (total / target) : 0.0;
    // Status is 'success' if completed, 'missed' if incomplete
    final status = total >= target ? 'success' : 'missed';

    _todaySummary = DailySummary(
      dayKey: key,
      targetMl: target,
      totalMl: total,
      completionPct: pct > 1.0 ? 1.0 : pct,
      status: status,
    );

    await _db.upsertDailySummary(_todaySummary!);
    notifyListeners();
  }

  // --- Encouraging Tone Copy Generator ---

  String get encouragingMessage {
    if (_todaySummary == null) return "Let's start tracking your hydration today!";
    final pct = _todaySummary!.completionPct;
    final total = _todaySummary!.totalMl;
    final target = _todaySummary!.targetMl;

    if (total == 0) {
      return "Let's start strong with your first glass of water today! 💧";
    } else if (pct < 0.25) {
      return "Good start! Every sip gets you closer to your goal. 🥤";
    } else if (pct < 0.50) {
      return "Great progress! You are moving steadily toward your target. 👍";
    } else if (pct < 0.75) {
      return "Over halfway there! You're doing a fantastic job today. ✨";
    } else if (pct < 1.0) {
      return "So close! Just a little more to meet your daily goal. You've got this! 🚀";
    } else {
      return "Goal achieved! Outstanding job keeping yourself hydrated today! 🎉";
    }
  }

  // --- Unit Formatting Helpers ---

  /// Convert ml to oz
  double toOz(num ml) {
    return ml * 0.033814;
  }

  /// Convert oz to ml
  int toMl(num oz) {
    return (oz / 0.033814).round();
  }

  /// Get formatted amount based on settings
  String formatVolume(int amountMl) {
    if (_settings.unit == 'oz') {
      return '${toOz(amountMl).toStringAsFixed(1)} fl oz';
    }
    if (_settings.unit == 'l') {
      final double l = amountMl / 1000.0;
      if (l == l.toInt()) {
        return '${l.toStringAsFixed(0)} L';
      } else if ((l * 10) == (l * 10).toInt()) {
        return '${l.toStringAsFixed(1)} L';
      } else {
        return '${l.toStringAsFixed(2)} L';
      }
    }
    return '$amountMl ml';
  }

  /// Get unit suffix
  String get unitSuffix {
    if (_settings.unit == 'oz') return 'fl oz';
    if (_settings.unit == 'l') return 'L';
    return 'ml';
  }  /// Retrieves aggregated data for the history screen based on the selected period.
  HistoryPeriodData getHistoryData(String period) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = calculatedDailyTarget.toDouble();

    if (period.toLowerCase() == 'daily') {
      // 1. Daily View (Today)
      final List<ChartBarItem> bars = [];

      // Group into 2-hour slots: 02:00, 04:00, ..., 24:00 (12 slots)
      for (int h = 2; h <= 24; h += 2) {
        double slotSum = 0.0;
        for (final log in _todayLogs) {
          final time = DateTime.fromMillisecondsSinceEpoch(log.timestamp);
          if (time.hour < h) {
            slotSum += log.amountMl;
          }
        }
        final label = h.toString().padLeft(2, '0');
        final isSuccess = slotSum >= target;
        final formattedVal = formatVolume(slotSum.toInt());
        final tooltip = 'Up to $label:00: $formattedVal';

        bars.add(ChartBarItem(
          label: label,
          value: slotSum,
          isSuccess: isSuccess,
          tooltipText: tooltip,
          date: today,
        ));
      }

      final successCount = _todaySummary?.status == 'success' ? 1 : 0;
      final missedCount = _todaySummary?.status == 'missed' ? 1 : 0;
      final averageIntake = _todaySummary?.totalMl.toDouble() ?? 0.0;

      return HistoryPeriodData(
        chartBars: bars,
        successCount: successCount,
        missedCount: missedCount,
        averageIntake: averageIntake,
        targetVolume: target,
      );
    } else if (period.toLowerCase() == 'weekly') {
      // 2. Weekly View (Monday to Sunday)
      final List<ChartBarItem> bars = [];
      int successCount = 0;
      int missedCount = 0;
      double totalSum = 0.0;
      int validDays = 0;

      final monday = today.subtract(Duration(days: today.weekday - 1));
      final weekdayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

      for (int i = 0; i < 7; i++) {
        final date = monday.add(Duration(days: i));
        final dayKey = DateFormat('yyyy-MM-dd').format(date);
        final isFuture = date.isAfter(today);

        double value = 0.0;
        bool isSuccess = false;
        String tooltip = '';

        if (!isFuture) {
          DailySummary? summary;
          if (dayKey == todayKey) {
            summary = _todaySummary;
          } else {
            final matches = _historySummaries.where((s) => s.dayKey == dayKey);
            if (matches.isNotEmpty) {
              summary = matches.first;
            } else {
              summary = DailySummary(
                dayKey: dayKey,
                targetMl: calculatedDailyTarget,
                totalMl: 0,
                completionPct: 0.0,
                status: 'missed',
              );
            }
          }

          if (summary != null) {
            value = summary.totalMl.toDouble();
            isSuccess = summary.status == 'success';
            if (isSuccess) {
              successCount++;
            } else {
              missedCount++;
            }
            totalSum += value;
            validDays++;
            final formattedVal = formatVolume(summary.totalMl);
            final formattedPct = (summary.completionPct * 100).toStringAsFixed(0);
            tooltip = '${DateFormat('MMM d').format(date)}: $formattedVal ($formattedPct%)';
          }
        } else {
          tooltip = '${DateFormat('MMM d').format(date)}: -';
        }

        bars.add(ChartBarItem(
          label: weekdayLabels[i],
          value: value,
          isSuccess: isSuccess,
          tooltipText: tooltip,
          date: date,
        ));
      }

      final averageIntake = validDays > 0 ? totalSum / validDays : 0.0;

      return HistoryPeriodData(
        chartBars: bars,
        successCount: successCount,
        missedCount: missedCount,
        averageIntake: averageIntake,
        targetVolume: target,
      );
    } else {
      // 3. Monthly View (1st to last day of month)
      final List<ChartBarItem> bars = [];
      int successCount = 0;
      int missedCount = 0;
      double totalSum = 0.0;
      int validDays = 0;

      final startOfMonth = DateTime(now.year, now.month, 1);
      final lastOfMonth = DateTime(now.year, now.month + 1, 0);
      final daysInMonth = lastOfMonth.day;

      for (int i = 1; i <= daysInMonth; i++) {
        final date = DateTime(now.year, now.month, i);
        final dayKey = DateFormat('yyyy-MM-dd').format(date);
        final isFuture = date.isAfter(today);

        double value = 0.0;
        bool isSuccess = false;
        String tooltip = '';

        if (!isFuture) {
          DailySummary? summary;
          if (dayKey == todayKey) {
            summary = _todaySummary;
          } else {
            final matches = _historySummaries.where((s) => s.dayKey == dayKey);
            if (matches.isNotEmpty) {
              summary = matches.first;
            } else {
              summary = DailySummary(
                dayKey: dayKey,
                targetMl: calculatedDailyTarget,
                totalMl: 0,
                completionPct: 0.0,
                status: 'missed',
              );
            }
          }

          if (summary != null) {
            value = summary.totalMl.toDouble();
            isSuccess = summary.status == 'success';
            if (isSuccess) {
              successCount++;
            } else {
              missedCount++;
            }
            totalSum += value;
            validDays++;
            final formattedVal = formatVolume(summary.totalMl);
            final formattedPct = (summary.completionPct * 100).toStringAsFixed(0);
            tooltip = '${DateFormat('MMM d').format(date)}: $formattedVal ($formattedPct%)';
          }
        } else {
          tooltip = '${DateFormat('MMM d').format(date)}: -';
        }

        bars.add(ChartBarItem(
          label: i.toString(),
          value: value,
          isSuccess: isSuccess,
          tooltipText: tooltip,
          date: date,
        ));
      }

      final averageIntake = validDays > 0 ? totalSum / validDays : 0.0;

      return HistoryPeriodData(
        chartBars: bars,
        successCount: successCount,
        missedCount: missedCount,
        averageIntake: averageIntake,
        targetVolume: target,
      );
    }
  }

  // --- Export Actions ---

  Future<void> triggerCsvExport() async {
    await loadHistoryData();
    await ExportHelper.shareCsvExport(
      summaries: _historySummaries,
      logs: _allHistoryLogs,
      unit: _settings.unit,
      subjectEmail: _settings.exportEmail,
    );
  }

  Future<void> exportPeriodData(String period) async {
    final data = await getPeriodData(period);
    await ExportHelper.shareCsvExport(
      summaries: data.summaries,
      logs: data.logs,
      unit: _settings.unit,
      subjectEmail: _settings.exportEmail,
    );
  }

  Future<ExportPeriodDataResult> getPeriodData(String period) async {
    await loadHistoryData();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    DateTime startDate;

    if (period.toLowerCase() == 'daily') {
      startDate = today;
    } else if (period.toLowerCase() == 'weekly') {
      startDate = today.subtract(Duration(days: today.weekday - 1));
    } else {
      startDate = DateTime(now.year, now.month, 1);
    }

    final filteredSummaries = _historySummaries.where((s) {
      final date = DateTime.tryParse(s.dayKey);
      if (date == null) return false;
      return !date.isBefore(startDate) && !date.isAfter(today);
    }).toList();

    // Make sure today's summary is included
    if (_todaySummary != null && !filteredSummaries.any((s) => s.dayKey == todayKey)) {
      filteredSummaries.add(_todaySummary!);
    }
    filteredSummaries.sort((a, b) => a.dayKey.compareTo(b.dayKey));

    final filteredLogs = _allHistoryLogs.where((l) {
      final time = DateTime.fromMillisecondsSinceEpoch(l.timestamp);
      final date = DateTime(time.year, time.month, time.day);
      return !date.isBefore(startDate) && !date.isAfter(today);
    }).toList();
    filteredLogs.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return ExportPeriodDataResult(
      summaries: filteredSummaries,
      logs: filteredLogs,
    );
  }

  Future<void> updateExportEmail(String email) async {
    final updated = _settings.copyWith(exportEmail: email);
    await updateSettings(updated);
  }

  // --- System Maintenance ---

  Future<void> resetAllData() async {
    await _db.clearAllData();
    _settings = HydrioSettings.defaultSettings();
    await _prefs.clear();
    await initialize();
  }

  Future<void> clearHistoryOnly() async {
    await _db.clearAllData();
    await loadTodayData();
    await loadHistoryData();
  }
}

class ExportPeriodDataResult {
  final List<DailySummary> summaries;
  final List<DrinkLog> logs;

  ExportPeriodDataResult({
    required this.summaries,
    required this.logs,
  });
}

enum WeeklyHydrationLevel { low, mid, high }

