import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:hydrio/core/providers/hydrio_provider.dart';
import 'package:hydrio/core/models/settings_model.dart';
import 'package:hydrio/ui/screens/settings_screen.dart';

void main() {
  sqfliteFfiInit();

  group('Hydrio Settings Screen Tests', () {
    testWidgets('Settings screen renders all rows and values', (WidgetTester tester) async {
      databaseFactory = databaseFactoryFfi;
      SharedPreferences.setMockInitialValues({
        'onboarding_complete': true,
        'gender': 'Female',
        'age': 28,
        'daily_target_ml': 2200,
        'unit': 'ml',
        'wake_time': '07:00',
        'sleep_time': '23:00',
        'cup_size_ml': 250,
        'notifications_on': true,
        'export_email': 'me@mail.com',
      });

      final provider = HydrioProvider();
      await tester.runAsync(() async {
        await provider.initialize();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<HydrioProvider>.value(
            value: provider,
            child: const SettingsScreen(),
          ),
        ),
      );

      await tester.pump();

      // Verify page titles and elements
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Gender'), findsOneWidget);
      expect(find.text('Female'), findsOneWidget);
      expect(find.text('Age'), findsOneWidget);
      expect(find.text('28'), findsOneWidget);
      expect(find.text('Daily target'), findsOneWidget);
      expect(find.text('2200 ml'), findsOneWidget); // volume formatted
      expect(find.text('Clear local history'), findsOneWidget);
      expect(find.text('Your data stays on your phone.'), findsOneWidget);
    });

    testWidgets('Settings clearHistoryOnly clears database but preserves settings', (WidgetTester tester) async {
      databaseFactory = databaseFactoryFfi;
      SharedPreferences.setMockInitialValues({
        'onboarding_complete': true,
        'gender': 'Female',
        'age': 28,
        'daily_target_ml': 2200,
        'unit': 'ml',
      });

      final provider = HydrioProvider();
      await tester.runAsync(() async {
        await provider.initialize();
        // Log a drink first
        await provider.logDrink(250);
        // Verify we have logs
        expect(provider.todayLogs.length, 1);
        expect(provider.todaySummary?.totalMl, 250);

        // Perform clearHistoryOnly
        await provider.clearHistoryOnly();

        // Verify history and today logs are reset
        expect(provider.todayLogs.isEmpty, true);
        expect(provider.todaySummary?.totalMl, 0);

        // Verify settings are intact
        expect(provider.settings.gender, 'Female');
        expect(provider.settings.age, 28);
        expect(provider.settings.dailyTargetMl, 2200);
      });
    });

    testWidgets('Liters unit setting formatting', (WidgetTester tester) async {
      databaseFactory = databaseFactoryFfi;
      SharedPreferences.setMockInitialValues({
        'onboarding_complete': true,
        'unit': 'l',
      });

      final provider = HydrioProvider();
      await tester.runAsync(() async {
        await provider.initialize();
        // 2000 ml formatted to Liters
        expect(provider.formatVolume(2000), '2 L');
        // 250 ml formatted to Liters
        expect(provider.formatVolume(250), '0.25 L');
        // 1200 ml formatted to Liters
        expect(provider.formatVolume(1200), '1.2 L');
      });
    });
  });
}
