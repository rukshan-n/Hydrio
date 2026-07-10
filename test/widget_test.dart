import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:hydrio/core/providers/hydrio_provider.dart';
import 'package:hydrio/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  group('Hydrio Navigation & Widget Tests', () {
    testWidgets('Hydrio placeholder screen renders core text elements when onboarding complete', (WidgetTester tester) async {
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

      // Verify presence of AppBar text
      expect(find.text('Hydrio Core'), findsOneWidget);
      
      // Verify progress text renders target
      expect(find.textContaining('Goal:'), findsOneWidget);
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

      // Verify we are redirected to Hydrio Core
      expect(find.text('Hydrio Core'), findsOneWidget);
      expect(provider.settings.onboardingComplete, isTrue);

      print('WIDGET TEST 3: Passed!');
    });
  });
}
