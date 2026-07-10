import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../../core/providers/hydrio_provider.dart';
import '../../core/utils/export_helper.dart';
import '../../core/models/daily_summary_model.dart';
import '../../core/models/drink_log_model.dart';

class ExportSummaryScreen extends StatefulWidget {
  final String initialPeriod;

  const ExportSummaryScreen({
    super.key,
    required this.initialPeriod,
  });

  @override
  State<ExportSummaryScreen> createState() => _ExportSummaryScreenState();
}

class _ExportSummaryScreenState extends State<ExportSummaryScreen> {
  late TextEditingController _emailController;
  late String _selectedPeriod;
  String _selectedFormat = 'Email text';
  String? _tempFilePath;
  late ScrollController _previewScrollController;

  // Formatted data states
  List<DailySummary> _summaries = [];
  List<DrinkLog> _logs = [];
  bool _isLoading = true;
  String _previewText = '';
  bool _isEmailValid = true;

  final RegExp _emailRegex = RegExp(
    r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
  );

  @override
  void initState() {
    super.initState();
    _selectedPeriod = widget.initialPeriod.toLowerCase();
    _emailController = TextEditingController();
    _emailController.addListener(_onEmailChanged);
    _previewScrollController = ScrollController();

    // Load initial settings pre-fill
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<HydrioProvider>(context, listen: false);
      _emailController.text = provider.settings.exportEmail;
      _updateData();
    });
  }

  @override
  void dispose() {
    _emailController.removeListener(_onEmailChanged);
    _emailController.dispose();
    _previewScrollController.dispose();
    _cleanupTempFile();
    super.dispose();
  }

  void _onEmailChanged() {
    final text = _emailController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _isEmailValid = true;
      });
    } else {
      setState(() {
        _isEmailValid = _emailRegex.hasMatch(text);
      });
    }
  }

  Future<void> _cleanupTempFile() async {
    if (_tempFilePath != null) {
      try {
        final file = File(_tempFilePath!);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {
        // Silent catch for deletion issues
      }
      _tempFilePath = null;
    }
  }

  Future<void> _updateData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final provider = Provider.of<HydrioProvider>(context, listen: false);
      final data = await provider.getPeriodData(_selectedPeriod);

      if (mounted) {
        setState(() {
          _summaries = data.summaries;
          _logs = data.logs;
          _isLoading = false;
          _generatePreview();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  void _generatePreview() {
    final provider = Provider.of<HydrioProvider>(context, listen: false);
    final unit = provider.settings.unit;

    if (_selectedFormat == 'Email text') {
      final subject = ExportHelper.getEmailSubject(summaries: _summaries, period: _selectedPeriod);
      final body = ExportHelper.generateEmailContent(
        summaries: _summaries,
        logs: _logs,
        unit: unit,
        period: _selectedPeriod,
      );
      _previewText = 'Subject: $subject\n\n$body';
    } else {
      _previewText = ExportHelper.generateCsvContent(
        summaries: _summaries,
        logs: _logs,
        unit: unit,
      );
    }
  }

  bool get _hasData => _summaries.isNotEmpty || _logs.isNotEmpty;

  Future<void> _onSharePressed() async {
    final provider = Provider.of<HydrioProvider>(context, listen: false);
    final unit = provider.settings.unit;
    final email = _emailController.text.trim();

    // Persist email back to settings if non-empty and valid
    if (email.isNotEmpty && _isEmailValid) {
      await provider.updateExportEmail(email);
    }

    if (email.isNotEmpty && _isEmailValid && _selectedFormat == 'Email text') {
      // Trigger mailto intent pre-fill path
      final subject = ExportHelper.getEmailSubject(summaries: _summaries, period: _selectedPeriod);
      final body = ExportHelper.generateEmailContent(
        summaries: _summaries,
        logs: _logs,
        unit: unit,
        period: _selectedPeriod,
      );

      final launched = await ExportHelper.launchMailto(
        email: email,
        subject: subject,
        body: body,
      );

      if (launched) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Opening mail application... ✉️')),
          );
        }
        return;
      }
      // Fallback if mailto: launcher fails (e.g. no mail app set up)
    }

    // Standard Share Sheet Fallback
    try {
      if (_selectedFormat == 'CSV file') {
        // Write temp CSV file
        await _cleanupTempFile();
        final tempDir = await getTemporaryDirectory();
        final fileName = 'hydrio_export_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv';
        final file = File('${tempDir.path}/$fileName');
        await file.writeAsString(_previewText);
        _tempFilePath = file.path;

        await ExportHelper.shareCsvExport(
          summaries: _summaries,
          logs: _logs,
          unit: unit,
          subjectEmail: email,
        );
      } else {
        // Email text share
        final subject = ExportHelper.getEmailSubject(summaries: _summaries, period: _selectedPeriod);
        await ExportHelper.shareContent(
          text: _previewText,
          subject: subject,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share: $e ⚠️'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    final panelBgColor = isLight ? const Color(0xffF2F5F8) : const Color(0xff1B2430);
    final surfaceColor = isLight ? const Color(0xffFFFFFF) : const Color(0xff121821);
    final errorColor = isLight ? const Color(0xffC5221F) : const Color(0xffF08A86);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Export Summary',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Send summary to Email Field
                      Text(
                        'Send summary to',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          hintText: 'Enter email address (optional)',
                          hintStyle: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                          ),
                          filled: true,
                          fillColor: panelBgColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14.0),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14.0),
                            borderSide: BorderSide(
                              color: _isEmailValid ? theme.colorScheme.primary : errorColor,
                              width: 1.5,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                        ),
                        style: TextStyle(
                          fontSize: 16,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      if (!_isEmailValid) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Please enter a valid email address.',
                          style: TextStyle(
                            fontSize: 14,
                            color: errorColor,
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),

                      // Period Selector
                      Text(
                        'Period',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: SegmentedButton<String>(
                          showSelectedIcon: false,
                          style: SegmentedButton.styleFrom(
                            backgroundColor: panelBgColor,
                            selectedBackgroundColor: theme.colorScheme.primary,
                            selectedForegroundColor: isLight ? Colors.white : Colors.black,
                            foregroundColor: theme.colorScheme.onSurfaceVariant,
                            side: BorderSide.none,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14.0),
                            ),
                          ),
                          segments: const [
                            ButtonSegment(value: 'daily', label: Text('Daily')),
                            ButtonSegment(value: 'weekly', label: Text('Weekly')),
                            ButtonSegment(value: 'monthly', label: Text('Monthly')),
                          ],
                          selected: {_selectedPeriod},
                          onSelectionChanged: (newSelection) {
                            setState(() {
                              _selectedPeriod = newSelection.first;
                            });
                            _updateData();
                          },
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Format Selector
                      Text(
                        'Format',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: SegmentedButton<String>(
                          showSelectedIcon: false,
                          style: SegmentedButton.styleFrom(
                            backgroundColor: panelBgColor,
                            selectedBackgroundColor: theme.colorScheme.primary,
                            selectedForegroundColor: isLight ? Colors.white : Colors.black,
                            foregroundColor: theme.colorScheme.onSurfaceVariant,
                            side: BorderSide.none,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14.0),
                            ),
                          ),
                          segments: const [
                            ButtonSegment(value: 'Email text', label: Text('Email text')),
                            ButtonSegment(value: 'CSV file', label: Text('CSV file')),
                          ],
                          selected: {_selectedFormat},
                          onSelectionChanged: (newSelection) {
                            setState(() {
                              _selectedFormat = newSelection.first;
                            });
                            _generatePreview();
                          },
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Preview Pane Label & Box
                      Text(
                        'Preview',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 220,
                        decoration: BoxDecoration(
                          color: panelBgColor,
                          borderRadius: BorderRadius.circular(16.0),
                          border: Border.all(
                            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16.0),
                          child: _hasData
                              ? Scrollbar(
                                  controller: _previewScrollController,
                                  thumbVisibility: true,
                                  child: SingleChildScrollView(
                                    controller: _previewScrollController,
                                    padding: const EdgeInsets.all(16.0),
                                    child: SelectableText(
                                      _previewText,
                                      style: TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 14,
                                        color: theme.colorScheme.onSurface.withOpacity(0.9),
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                )
                              : Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                                    child: Text(
                                      'No hydration records found for this period.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: theme.colorScheme.onSurfaceVariant,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Share Button
                      ElevatedButton(
                        onPressed: _hasData ? _onSharePressed : null,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 54.0),
                          backgroundColor: _hasData ? theme.colorScheme.primary : theme.colorScheme.onSurface.withOpacity(0.12),
                          foregroundColor: _hasData
                              ? (isLight ? Colors.white : Colors.black)
                              : theme.colorScheme.onSurface.withOpacity(0.38),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.0),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Open share sheet',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Privacy Note
                      Text(
                        "Uses your phone's mail / share app. Nothing is sent to any server.",
                        textAlign: Alignment.center == null ? null : TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
