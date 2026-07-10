import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/daily_summary_model.dart';
import '../models/drink_log_model.dart';

class ExportHelper {
  /// Generates a CSV file summarizing daily history and drink logs, then triggers share sheet.
  static Future<void> shareCsvExport({
    required List<DailySummary> summaries,
    required List<DrinkLog> logs,
    required String unit,
    String? subjectEmail,
  }) async {
    final buffer = StringBuffer();

    // 1. Daily Summaries Section
    buffer.writeln('=== DAILY SUMMARIES ===');
    buffer.writeln('Date,Target ($unit),Total Intake ($unit),Completion,Status');

    for (final summary in summaries) {
      // Format targets/totals based on current unit
      final target = unit == 'oz' ? (summary.targetMl * 0.033814).toStringAsFixed(1) : summary.targetMl.toString();
      final total = unit == 'oz' ? (summary.totalMl * 0.033814).toStringAsFixed(1) : summary.totalMl.toString();
      final percentage = '${(summary.completionPct * 100).toStringAsFixed(1)}%';
      buffer.writeln('${summary.dayKey},$target,$total,$percentage,${summary.status}');
    }

    buffer.writeln(); // Blank line separator

    // 2. Individual Logs Section
    buffer.writeln('=== INDIVIDUAL INTAKE LOGS ===');
    buffer.writeln('Date,Time,Amount ($unit)');

    for (final log in logs) {
      final dateTime = DateTime.fromMillisecondsSinceEpoch(log.timestamp);
      final dateStr = DateFormat('yyyy-MM-dd').format(dateTime);
      final timeStr = DateFormat('HH:mm:ss').format(dateTime);
      final amount = unit == 'oz' ? (log.amountMl * 0.033814).toStringAsFixed(1) : log.amountMl.toString();
      buffer.writeln('$dateStr,$timeStr,$amount');
    }

    // 3. Write to temporary file
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/hydrio_export_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv');
    await file.writeAsString(buffer.toString());

    // 4. Trigger share sheet
    final xFile = XFile(file.path);
    await Share.shareXFiles(
      [xFile],
      text: 'Here is my Hydrio water log export.',
      subject: 'Hydrio Water Intake Export',
    );
  }
}
