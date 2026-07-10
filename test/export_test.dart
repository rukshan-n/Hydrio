import 'package:flutter_test/flutter_test.dart';
import 'package:hydrio/core/models/daily_summary_model.dart';
import 'package:hydrio/core/models/drink_log_model.dart';
import 'package:hydrio/core/utils/export_helper.dart';

void main() {
  group('ExportHelper Content Generation Tests', () {
    final testSummaries = [
      DailySummary(
        dayKey: '2026-07-08',
        targetMl: 2000,
        totalMl: 2500,
        completionPct: 1.25,
        status: 'success',
      ),
      DailySummary(
        dayKey: '2026-07-09',
        targetMl: 2000,
        totalMl: 1500,
        completionPct: 0.75,
        status: 'missed',
      ),
    ];

    final testLogs = [
      DrinkLog(
        id: 1,
        amountMl: 500,
        timestamp: DateTime(2026, 7, 8, 8, 30).millisecondsSinceEpoch,
        dayKey: '2026-07-08',
      ),
      DrinkLog(
        id: 2,
        amountMl: 2000,
        timestamp: DateTime(2026, 7, 8, 14, 0).millisecondsSinceEpoch,
        dayKey: '2026-07-08',
      ),
      DrinkLog(
        id: 3,
        amountMl: 1500,
        timestamp: DateTime(2026, 7, 9, 10, 15).millisecondsSinceEpoch,
        dayKey: '2026-07-09',
      ),
    ];

    test('generateCsvContent format is correct (mL unit)', () {
      final csv = ExportHelper.generateCsvContent(
        summaries: testSummaries,
        logs: testLogs,
        unit: 'ml',
      );

      expect(csv, contains('=== DAILY SUMMARIES ==='));
      expect(csv, contains('Date,Target (ml),Total Intake (ml),Completion,Status'));
      expect(csv, contains('2026-07-08,2000,2500,125.0%,success'));
      expect(csv, contains('2026-07-09,2000,1500,75.0%,missed'));
      expect(csv, contains('=== INDIVIDUAL INTAKE LOGS ==='));
      expect(csv, contains('Date,Time,Amount (ml)'));
      expect(csv, contains('2026-07-08,08:30:00,500'));
      expect(csv, contains('2026-07-08,14:00:00,2000'));
      expect(csv, contains('2026-07-09,10:15:00,1500'));
    });

    test('generateCsvContent format converts properly (oz unit)', () {
      final csv = ExportHelper.generateCsvContent(
        summaries: testSummaries,
        logs: testLogs,
        unit: 'oz',
      );

      expect(csv, contains('Target (oz),Total Intake (oz)'));
      // 2000 mL * 0.033814 = 67.6 oz
      expect(csv, contains('2026-07-08,67.6,84.5,125.0%,success'));
      expect(csv, contains('Amount (oz)'));
      // 500 mL * 0.033814 = 16.9 oz
      expect(csv, contains('2026-07-08,08:30:00,16.9'));
    });

    test('generateEmailContent formats Daily period correctly', () {
      final emailText = ExportHelper.generateEmailContent(
        summaries: [testSummaries.first],
        logs: [testLogs[0], testLogs[1]],
        unit: 'ml',
        period: 'daily',
      );

      expect(emailText, contains('=== HYDRATION SUMMARY ==='));
      expect(emailText, contains('Date: 2026-07-08'));
      expect(emailText, contains('Daily Target: 2000 ml'));
      expect(emailText, contains('Total Consumed: 2500 ml'));
      expect(emailText, contains('Completion: 125.0%'));
      expect(emailText, contains('Status: SUCCESS'));
      expect(emailText, contains('=== INDIVIDUAL LOGS ==='));
      expect(emailText, contains('08:30 | 500 ml'));
      expect(emailText, contains('14:00 | 2000 ml'));
    });

    test('generateEmailContent formats Weekly period correctly', () {
      final emailText = ExportHelper.generateEmailContent(
        summaries: testSummaries,
        logs: testLogs,
        unit: 'ml',
        period: 'weekly',
      );

      expect(emailText, contains('=== HYDRATION SUMMARY ==='));
      expect(emailText, contains('Period: 2026-07-08 to 2026-07-09'));
      expect(emailText, contains('Daily Average: 2000 ml')); // average of 2500 and 1500 is 2000
      expect(emailText, contains('Days Met/Total Days: 1 / 2'));
      expect(emailText, contains('=== DAILY BREAKDOWN ==='));
      expect(emailText, contains('2026-07-08 | 2000 ml | 2500 ml | 125.0% | SUCCESS'));
      expect(emailText, contains('=== INDIVIDUAL LOGS ==='));
      expect(emailText, contains('2026-07-08 | 08:30 | 500 ml'));
    });

    test('getEmailSubject produces appropriate subject lines', () {
      final subjectDaily = ExportHelper.getEmailSubject(
        summaries: testSummaries,
        period: 'daily',
      );
      final subjectWeekly = ExportHelper.getEmailSubject(
        summaries: testSummaries,
        period: 'weekly',
      );

      expect(subjectDaily, startsWith('Hydrio Daily Summary -'));
      expect(subjectWeekly, equals('Hydrio Weekly Summary - 2026-07-08 to 2026-07-09'));
    });
  });
}
