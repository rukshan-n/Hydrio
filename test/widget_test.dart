import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:hydrio/core/providers/hydrio_provider.dart';
import 'package:hydrio/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  testWidgets('Hydrio placeholder screen renders core text elements', (WidgetTester tester) async {
    print('WIDGET TEST: Starting in runAsync...');
    databaseFactory = databaseFactoryFfi;
    SharedPreferences.setMockInitialValues({});
    
    final provider = HydrioProvider();

    // Wrap real async calls in tester.runAsync so FFI can run in the real Dart VM zone
    await tester.runAsync(() async {
      print('WIDGET TEST: Initializing provider...');
      await provider.initialize();
      print('WIDGET TEST: Provider initialized successfully.');
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
    print('WIDGET TEST: All assertions passed!');
  });
}
