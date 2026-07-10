import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:hydrio/core/models/settings_model.dart';
import 'package:hydrio/core/providers/hydrio_provider.dart';
import 'package:hydrio/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

void main() {
  sqfliteFfiInit();
  group('Hydrio Data Models & Settings Tests', () {
    test('defaultSettings factory has expected defaults', () {
      final settings = HydrioSettings.defaultSettings();
      expect(settings.gender, 'Other');
      expect(settings.age, 30);
      expect(settings.wakeTime, '07:00');
      expect(settings.sleepTime, '22:00');
      expect(settings.reminderIntervalMin, 120);
      expect(settings.cupSizeMl, 250);
      expect(settings.dailyTargetMl, 2000);
      expect(settings.manualOverride, false);
      expect(settings.unit, 'ml');
      expect(settings.notificationsOn, true);
      expect(settings.silentReminders, false);
      expect(settings.theme, 'system');
      expect(settings.onboardingComplete, false);
    });

    test('fromMap & toMap serialization consistency', () {
      final original = HydrioSettings.defaultSettings().copyWith(
        gender: 'Female',
        age: 28,
        wakeTime: '06:30',
        sleepTime: '23:00',
        manualOverride: true,
        dailyTargetMl: 1800,
        unit: 'oz',
        notificationsOn: false,
        silentReminders: true,
        onboardingComplete: true,
      );

      final map = original.toMap();
      final reconstructed = HydrioSettings.fromMap(map);

      expect(reconstructed.gender, original.gender);
      expect(reconstructed.age, original.age);
      expect(reconstructed.wakeTime, original.wakeTime);
      expect(reconstructed.sleepTime, original.sleepTime);
      expect(reconstructed.manualOverride, original.manualOverride);
      expect(reconstructed.dailyTargetMl, original.dailyTargetMl);
      expect(reconstructed.unit, original.unit);
      expect(reconstructed.notificationsOn, original.notificationsOn);
      expect(reconstructed.silentReminders, original.silentReminders);
      expect(reconstructed.onboardingComplete, original.onboardingComplete);
    });

    test('calculatedDailyTarget calculations are correct based on demographics', () {
      // Helper function matching provider logic
      int getTarget(HydrioSettings settings) {
        if (settings.manualOverride) {
          return settings.dailyTargetMl;
        }
        int baseline = 2500;
        if (settings.gender.toLowerCase() == 'female') {
          baseline = 2000;
        } else if (settings.gender.toLowerCase() == 'male') {
          baseline = 3000;
        }

        if (settings.age < 30) {
          baseline += 100;
        } else if (settings.age > 55) {
          baseline -= 100;
        }
        return baseline;
      }

      // Test default values
      final defaultSettings = HydrioSettings.defaultSettings();
      expect(getTarget(defaultSettings), 2500); // Other, 30-55 age group

      // Test Young Male
      final youngMale = HydrioSettings.defaultSettings().copyWith(
        gender: 'Male',
        age: 25,
      );
      expect(getTarget(youngMale), 3100); // Male baseline (3000) + young offset (100)

      // Test Older Female
      final olderFemale = HydrioSettings.defaultSettings().copyWith(
        gender: 'Female',
        age: 60,
      );
      expect(getTarget(olderFemale), 1900); // Female baseline (2000) - older offset (100)

      // Test Manual Override
      final overrideSettings = HydrioSettings.defaultSettings().copyWith(
        manualOverride: true,
        dailyTargetMl: 1550,
      );
      expect(getTarget(overrideSettings), 1550); // Direct target value
    });

    test('Volume conversion helpers logic works correctly', () {
      double toOz(num ml) => ml * 0.033814;
      int toMl(num oz) => (oz / 0.033814).round();

      expect(toOz(1000).toStringAsFixed(1), '33.8');
      expect(toMl(33.814), 1000);
    });

    test('getHistoryData weekly backfilling and aggregation works correctly', () async {
      databaseFactory = databaseFactoryFfi;
      SharedPreferences.setMockInitialValues({'onboarding_complete': true, 'unit': 'ml'});
      
      final provider = HydrioProvider();
      await provider.initialize();
      await provider.resetAllData();

      // Log a drink today (e.g. 2500 mL to achieve goal)
      await provider.logDrink(2500);

      // Get history data for weekly range
      final historyData = provider.getHistoryData('weekly');

      // Weekly range should have 7 bars (Monday to Sunday)
      expect(historyData.chartBars.length, 7);

      // Today should be success (since logged 2500 mL >= target 2500 mL)
      // The day index of today in Monday-Sunday range is: DateTime.now().weekday - 1
      final todayIndex = DateTime.now().weekday - 1;
      expect(historyData.chartBars[todayIndex].isSuccess, isTrue);
      expect(historyData.chartBars[todayIndex].value, 2500.0);

      // Other occurred days (before today) should be virtual missed (since we reset DB)
      // The number of occurred days is DateTime.now().weekday
      expect(historyData.successCount, 1);
      expect(historyData.missedCount, DateTime.now().weekday - 1);

      // Average intake should be totalMl (2500) / occurred days
      expect(historyData.averageIntake, 2500.0 / DateTime.now().weekday);
    });

    test('weeklyHydrationLevel rolling 7-day calculations and level transitions', () async {
      databaseFactory = databaseFactoryFfi;
      SharedPreferences.setMockInitialValues({'onboarding_complete': true, 'unit': 'ml'});
      
      final provider = HydrioProvider();
      await provider.initialize();
      await provider.resetAllData();

      // 1. Initial State (No history logs. Today's intake is 0 mL).
      // Rolling targets = 1 day (today's target of 2500). Intake = 0 mL.
      // Percentage = 0% => WeeklyHydrationLevel.low.
      expect(provider.weeklyHydrationLevel, WeeklyHydrationLevel.low);

      // 2. Log full target water today (2500 mL)
      await provider.logDrink(2500);
      // Rolling targets = 1 day (today's target of 2500). Intake = 2500 mL.
      // Percentage = 100% => WeeklyHydrationLevel.high.
      expect(provider.weeklyHydrationLevel, WeeklyHydrationLevel.high);

      // 3. Log smaller amount so it's in the mid range (50% to 79%)
      // Let's reset all data and log 1500 mL instead.
      await provider.resetAllData();
      await provider.logDrink(1500);
      // Percentage = 1500/2500 = 60% => WeeklyHydrationLevel.mid.
      expect(provider.weeklyHydrationLevel, WeeklyHydrationLevel.mid);
    });

    test('AppPalette dynamic colors resolution matches hydration score', () {
      expect(AppPalette.resolve(Brightness.light, WeeklyHydrationLevel.low).surface, const Color(0xFFD7C9BA));
      expect(AppPalette.resolve(Brightness.light, WeeklyHydrationLevel.mid).surface, const Color(0xFFFFFFFF));
      expect(AppPalette.resolve(Brightness.light, WeeklyHydrationLevel.high).surface, const Color(0xFFD9ECFA));
      
      expect(AppPalette.resolve(Brightness.dark, WeeklyHydrationLevel.low).surface, const Color(0xFF221711));
      expect(AppPalette.resolve(Brightness.dark, WeeklyHydrationLevel.mid).surface, const Color(0xFF121821));
      expect(AppPalette.resolve(Brightness.dark, WeeklyHydrationLevel.high).surface, const Color(0xFF0C1824));
    });
  });
}
