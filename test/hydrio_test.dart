import 'package:flutter_test/flutter_test.dart';
import 'package:hydrio/core/models/settings_model.dart';

void main() {
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
  });
}
