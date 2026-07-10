import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:hydrio/core/providers/hydrio_provider.dart';
import 'package:hydrio/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:hydrio/ui/screens/add_water_screen.dart';

void main() {
  sqfliteFfiInit();

  group('Hydrio Navigation & Widget Tests', () {
    testWidgets('Hydrio Today screen renders core elements when onboarding complete', (WidgetTester tester) async {
      print('WIDGET TEST 1: Starting in runAsync...');
      databaseFactory = databaseFactoryFfi;
      SharedPreferences.setMockInitialValues({'onboarding_complete': true});
      
      final provider = HydrioProvider();

      // Wrap real async calls in tester.runAsync so FFI can run in the real Dart VM zone
      await tester.runAsync(() async {
        print('WIDGET TEST 1: Initializing provider...');
        await provider.initialize();
        print('WIDGET TEST 1: Provider initialized successfully.');
      });

      await tester.pumpWidget(
        ChangeNotifierProvider<HydrioProvider>.value(
          value: provider,
          child: const HydrioApp(),
        ),
      );

      await tester.pump();

      // Verify presence of AppBar text and Bottom Navigation Tab label
      expect(find.text('Today'), findsNWidgets(2));
      
      // Verify quick add section exists
      expect(find.text('Quick add'), findsOneWidget);

      // Verify add water button exists
      expect(find.text('Add Water'), findsOneWidget);
      print('WIDGET TEST 1: Passed!');
    });

    testWidgets('Welcome screen renders when onboarding not complete', (WidgetTester tester) async {
      print('WIDGET TEST 2: Starting in runAsync...');
      databaseFactory = databaseFactoryFfi;
      SharedPreferences.setMockInitialValues({});
      
      final provider = HydrioProvider();

      await tester.runAsync(() async {
        print('WIDGET TEST 2: Initializing provider...');
        await provider.initialize();
      });

      await tester.pumpWidget(
        ChangeNotifierProvider<HydrioProvider>.value(
          value: provider,
          child: const HydrioApp(),
        ),
      );

      await tester.pump();

      // Verify presence of branding and text elements
      expect(find.text('Hydrio'), findsOneWidget);
      expect(find.text('Stay hydrated, every day.'), findsOneWidget);
      expect(find.text('Private · Offline · Simple'), findsOneWidget);
      expect(find.text('Get Started'), findsOneWidget);
      expect(find.text('Your data stays on your phone.'), findsOneWidget);

      print('WIDGET TEST 2: Passed!');
    });

    testWidgets('Welcome screen navigates to setup step-by-step and completes onboarding', (WidgetTester tester) async {
      print('WIDGET TEST 3: Starting in runAsync...');
      databaseFactory = databaseFactoryFfi;
      SharedPreferences.setMockInitialValues({});
      
      final provider = HydrioProvider();

      await tester.runAsync(() async {
        print('WIDGET TEST 3: Initializing provider...');
        await provider.initialize();
      });

      await tester.pumpWidget(
        ChangeNotifierProvider<HydrioProvider>.value(
          value: provider,
          child: const HydrioApp(),
        ),
      );

      await tester.pump();

      // Tap Get Started
      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();

      // Verify Step 1 of 3
      expect(find.text('Step 1 of 3'), findsOneWidget);
      expect(find.text('Gender'), findsOneWidget);
      expect(find.text('Age'), findsOneWidget);

      // Tap Continue to Step 2
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Step 2 of 3'), findsOneWidget);
      expect(find.text('Wake-up time'), findsOneWidget);
      expect(find.text('Sleep time'), findsOneWidget);

      // Tap Continue to Step 3
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Step 3 of 3'), findsOneWidget);
      expect(find.text('Usual cup / bottle size'), findsOneWidget);
      expect(find.text('YOUR DAILY TARGET'), findsOneWidget);
      expect(find.text('Start Tracking'), findsOneWidget);

      // Tap Start Tracking to complete onboarding
      await tester.runAsync(() async {
        await tester.tap(find.text('Start Tracking'));
        await Future.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();

      // Verify we are redirected to Today screen and tab label exists
      expect(find.text('Today'), findsNWidgets(2));
      expect(provider.settings.onboardingComplete, isTrue);

      print('WIDGET TEST 3: Passed!');
    });

    testWidgets('AddWaterScreen presets log immediately and pop', (WidgetTester tester) async {
      print('WIDGET TEST 4: Starting in runAsync...');
      databaseFactory = databaseFactoryFfi;
      SharedPreferences.setMockInitialValues({'onboarding_complete': true});
      final provider = HydrioProvider();
      await tester.runAsync(() async {
        await provider.initialize();
      });

      await tester.pumpWidget(
        ChangeNotifierProvider<HydrioProvider>.value(
          value: provider,
          child: const MaterialApp(
            home: AddWaterScreen(),
          ),
        ),
      );

      await tester.pump();

      // Verify chips exist
      expect(find.text('100 mL'), findsOneWidget);
      expect(find.text('200 mL'), findsOneWidget);
      expect(find.text('250 mL'), findsOneWidget);
      expect(find.text('500 mL'), findsOneWidget);
      expect(find.text('Bottle'), findsOneWidget);
      expect(find.text('Custom'), findsOneWidget);

      // Tap 100 mL preset chip
      await tester.runAsync(() async {
        await tester.tap(find.text('100 mL'));
        await Future.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();

      // Check if logged successfully
      expect(provider.todayLogs.last.amountMl, 100);
      print('WIDGET TEST 4: Passed!');
    });

    testWidgets('AddWaterScreen custom amount validation logic', (WidgetTester tester) async {
      print('WIDGET TEST 5: Starting in runAsync...');
      databaseFactory = databaseFactoryFfi;
      SharedPreferences.setMockInitialValues({'onboarding_complete': true});
      final provider = HydrioProvider();
      await tester.runAsync(() async {
        await provider.initialize();
      });

      await tester.pumpWidget(
        ChangeNotifierProvider<HydrioProvider>.value(
          value: provider,
          child: const MaterialApp(
            home: AddWaterScreen(),
          ),
        ),
      );

      await tester.pump();

      // Tap Custom chip
      await tester.tap(find.text('Custom'));
      await tester.pumpAndSettle();

      // Custom numeric input field should be visible
      expect(find.byType(TextField), findsOneWidget);

      // Button should be disabled because field is empty/invalid initially
      final Finder addBtnFinder = find.widgetWithText(ElevatedButton, 'Add');
      ElevatedButton addBtn = tester.widget<ElevatedButton>(addBtnFinder);
      expect(addBtn.onPressed, isNull);

      // Enter zero
      await tester.enterText(find.byType(TextField), '0');
      await tester.pumpAndSettle();
      addBtn = tester.widget<ElevatedButton>(addBtnFinder);
      expect(addBtn.onPressed, isNull);
      expect(find.text('Please enter a positive number'), findsOneWidget);

      // Enter out-of-range value 2500 mL
      await tester.enterText(find.byType(TextField), '2500');
      await tester.pumpAndSettle();
      addBtn = tester.widget<ElevatedButton>(addBtnFinder);
      expect(addBtn.onPressed, isNull);
      expect(find.text('Amount must be between 1 and 2000 ml'), findsOneWidget);

      // Enter valid custom value 350 mL
      await tester.enterText(find.byType(TextField), '350');
      await tester.pumpAndSettle();
      addBtn = tester.widget<ElevatedButton>(addBtnFinder);
      expect(addBtn.onPressed, isNotNull);

      // Tap the Add button
      await tester.runAsync(() async {
        await tester.ensureVisible(addBtnFinder);
        await tester.tap(addBtnFinder);
        await Future.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();

      // Check if custom amount logged successfully
      expect(provider.todayLogs.last.amountMl, 350);
      print('WIDGET TEST 5: Passed!');
    });
  });
}
