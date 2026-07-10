import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
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
    final csvContent = generateCsvContent(
      summaries: summaries,
      logs: logs,
      unit: unit,
    );

    // Write to temporary file
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/hydrio_export_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv');
    await file.writeAsString(csvContent);

    // Trigger share sheet
    final xFile = XFile(file.path);
    await Share.shareXFiles(
      [xFile],
      text: 'Here is my Hydrio water log export.',
      subject: 'Hydrio Water Intake Export',
    );
  }

  /// Generates the raw CSV content string.
  static String generateCsvContent({
    required List<DailySummary> summaries,
    required List<DrinkLog> logs,
    required String unit,
  }) {
    final buffer = StringBuffer();

    // 1. Daily Summaries Section
    buffer.writeln('=== DAILY SUMMARIES ===');
    buffer.writeln('Date,Target ($unit),Total Intake ($unit),Completion,Status');

    for (final summary in summaries) {
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

    return buffer.toString();
  }

  /// Generates a structured plain text email content body.
  static String generateEmailContent({
    required List<DailySummary> summaries,
    required List<DrinkLog> logs,
    required String unit,
    required String period,
  }) {
    final buffer = StringBuffer();
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);

    if (period.toLowerCase() == 'daily') {
      final summary = summaries.isNotEmpty
          ? summaries.first
          : DailySummary(dayKey: todayStr, targetMl: 2000, totalMl: 0, completionPct: 0.0, status: 'missed');

      final target = unit == 'oz' ? (summary.targetMl * 0.033814).toStringAsFixed(1) : summary.targetMl.toString();
      final total = unit == 'oz' ? (summary.totalMl * 0.033814).toStringAsFixed(1) : summary.totalMl.toString();
      final percentage = '${(summary.completionPct * 100).toStringAsFixed(1)}%';

      buffer.writeln('=== HYDRATION SUMMARY ===');
      buffer.writeln('Date: ${summary.dayKey}');
      buffer.writeln('Daily Target: $target $unit');
      buffer.writeln('Total Consumed: $total $unit');
      buffer.writeln('Completion: $percentage');
      buffer.writeln('Status: ${summary.status.toUpperCase()}');
      buffer.writeln();
      buffer.writeln('=== INDIVIDUAL LOGS ===');
      buffer.writeln('Time | Amount');

      for (final log in logs) {
        final dateTime = DateTime.fromMillisecondsSinceEpoch(log.timestamp);
        final timeStr = DateFormat('HH:mm').format(dateTime);
        final amount = unit == 'oz' ? (log.amountMl * 0.033814).toStringAsFixed(1) : log.amountMl.toString();
        buffer.writeln('$timeStr | $amount $unit');
      }
    } else {
      final periodType = period.toLowerCase() == 'weekly' ? 'Weekly' : 'Monthly';
      String dateRange = '';
      if (summaries.isNotEmpty) {
        dateRange = '${summaries.first.dayKey} to ${summaries.last.dayKey}';
      } else {
        dateRange = todayStr;
      }

      int totalTargetMl = 0;
      int totalConsumedMl = 0;
      int successCount = 0;
      for (final s in summaries) {
        totalTargetMl += s.targetMl;
        totalConsumedMl += s.totalMl;
        if (s.status == 'success') {
          successCount++;
        }
      }

      final avgTargetMl = summaries.isNotEmpty ? (totalTargetMl / summaries.length).round() : 2000;
      final avgConsumedMl = summaries.isNotEmpty ? (totalConsumedMl / summaries.length).round() : 0;

      final target = unit == 'oz' ? (avgTargetMl * 0.033814).toStringAsFixed(1) : avgTargetMl.toString();
      final total = unit == 'oz' ? (totalConsumedMl * 0.033814).toStringAsFixed(1) : totalConsumedMl.toString();
      final average = unit == 'oz' ? (avgConsumedMl * 0.033814).toStringAsFixed(1) : avgConsumedMl.toString();

      buffer.writeln('=== HYDRATION SUMMARY ===');
      buffer.writeln('Period: $dateRange');
      buffer.writeln('Daily Target: $target $unit');
      buffer.writeln('Total Consumed: $total $unit');
      buffer.writeln('Daily Average: $average $unit');
      buffer.writeln('Days Met/Total Days: $successCount / ${summaries.length}');
      buffer.writeln();
      buffer.writeln('=== DAILY BREAKDOWN ===');
      buffer.writeln('Date | Target | Consumed | Progress | Status');
      for (final s in summaries) {
        final sTarget = unit == 'oz' ? (s.targetMl * 0.033814).toStringAsFixed(1) : s.targetMl.toString();
        final sTotal = unit == 'oz' ? (s.totalMl * 0.033814).toStringAsFixed(1) : s.totalMl.toString();
        final sPercentage = '${(s.completionPct * 100).toStringAsFixed(1)}%';
        buffer.writeln('${s.dayKey} | $sTarget $unit | $sTotal $unit | $sPercentage | ${s.status.toUpperCase()}');
      }
      buffer.writeln();
      buffer.writeln('=== INDIVIDUAL LOGS ===');
      buffer.writeln('Date | Time | Amount');
      for (final log in logs) {
        final dateTime = DateTime.fromMillisecondsSinceEpoch(log.timestamp);
        final dateStr = DateFormat('yyyy-MM-dd').format(dateTime);
        final timeStr = DateFormat('HH:mm').format(dateTime);
        final amount = unit == 'oz' ? (log.amountMl * 0.033814).toStringAsFixed(1) : log.amountMl.toString();
        buffer.writeln('$dateStr | $timeStr | $amount $unit');
      }
    }

    buffer.writeln();
    buffer.writeln('Sent from Hydrio - Stay hydrated, every day.');
    return buffer.toString();
  }

  /// Generates the subject line based on period and summaries.
  static String getEmailSubject({
    required List<DailySummary> summaries,
    required String period,
  }) {
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    if (period.toLowerCase() == 'daily') {
      return 'Hydrio Daily Summary - $todayStr';
    } else {
      final periodType = period.toLowerCase() == 'weekly' ? 'Weekly' : 'Monthly';
      String dateRange = '';
      if (summaries.isNotEmpty) {
        dateRange = '${summaries.first.dayKey} to ${summaries.last.dayKey}';
      } else {
        dateRange = todayStr;
      }
      return 'Hydrio $periodType Summary - $dateRange';
    }
  }

  /// Shares plain text using share_plus.
  static Future<void> shareContent({
    required String text,
    required String subject,
  }) async {
    await Share.share(
      text,
      subject: subject,
    );
  }

  /// Launches a mailto intent. Returns true if successful.
  static Future<bool> launchMailto({
    required String email,
    required String subject,
    required String body,
  }) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: email,
      query: encodeQueryParameters(<String, String>{
        'subject': subject,
        'body': body,
      }),
    );

    try {
      if (await canLaunchUrl(emailLaunchUri)) {
        return await launchUrl(emailLaunchUri);
      }
    } catch (_) {
      // Fallback
    }
    return false;
  }

  static String? encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((MapEntry<String, String> e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }
}
