import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/providers/hydrio_provider.dart';
import '../../core/models/history_data_model.dart';
import 'export_summary_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _selectedPeriod = 'weekly';

  String _formatAverage(double ml, String unit) {
    if (unit == 'oz') {
      final oz = ml * 0.033814;
      return '${oz.toStringAsFixed(1)} oz';
    } else {
      if (ml >= 1000.0) {
        final l = ml / 1000.0;
        return '${l.toStringAsFixed(1)} L';
      } else {
        return '${ml.toStringAsFixed(0)} mL';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<HydrioProvider>();
    final unit = provider.settings.unit;
    final historyData = provider.getHistoryData(_selectedPeriod);

    // Dynamic maxY logic to give bars breathing room above the target line
    double maxVal = historyData.chartBars.fold<double>(0.0, (m, bar) => bar.value > m ? bar.value : m);
    double maxY = (maxVal > historyData.targetVolume ? maxVal : historyData.targetVolume) * 1.25;
    if (maxY == 0.0) {
      maxY = 2000.0;
    }

    // Check if the period has any logged water intake
    final bool isEmpty = historyData.chartBars.every((bar) => bar.value == 0.0);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'History',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Segmented control
                Center(
                  child: SegmentedButton<String>(
                    showSelectedIcon: false,
                    style: SegmentedButton.styleFrom(
                      backgroundColor: theme.cardTheme.color ?? (theme.brightness == Brightness.light ? const Color(0xffF2F5F8) : const Color(0xff1B2430)),
                      selectedBackgroundColor: theme.colorScheme.primary,
                      selectedForegroundColor: theme.brightness == Brightness.light ? Colors.white : Colors.black,
                      foregroundColor: theme.colorScheme.onSurfaceVariant,
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
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
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // Target Indicator & Chart Block
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Target: ${provider.formatVolume(historyData.targetVolume.toInt())}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Chart Area Container
                Container(
                  height: 240,
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: theme.cardTheme.color ?? (theme.brightness == Brightness.light ? const Color(0xffF2F5F8) : const Color(0xff1B2430)),
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  child: isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.water_drop_outlined,
                                size: 48,
                                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No intake logged yet.\nStart tracking today! 💧',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: maxY,
                            barTouchData: BarTouchData(
                              touchTooltipData: BarTouchTooltipData(
                                getTooltipColor: (_) => theme.colorScheme.surface.withOpacity(0.95),
                                tooltipRoundedRadius: 8,
                                tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                  final bar = historyData.chartBars[groupIndex];
                                  return BarTooltipItem(
                                    bar.tooltipText,
                                    TextStyle(
                                      color: theme.colorScheme.onSurface,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  );
                                },
                              ),
                            ),
                            titlesData: FlTitlesData(
                              show: true,
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    final index = value.toInt();
                                    if (index < 0 || index >= historyData.chartBars.length) {
                                      return const SizedBox.shrink();
                                    }
                                    final label = historyData.chartBars[index].label;

                                    if (_selectedPeriod == 'monthly') {
                                      final day = int.tryParse(label) ?? 0;
                                      if (day % 5 != 0 && day != 1 && day != historyData.chartBars.length) {
                                        return const SizedBox.shrink();
                                      }
                                    }

                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        label,
                                        style: TextStyle(
                                          color: theme.colorScheme.onSurfaceVariant,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    );
                                  },
                                  reservedSize: 24,
                                ),
                              ),
                              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            ),
                            gridData: const FlGridData(show: false),
                            borderData: FlBorderData(show: false),
                            extraLinesData: ExtraLinesData(
                              horizontalLines: [
                                HorizontalLine(
                                  y: historyData.targetVolume,
                                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
                                  strokeWidth: 1.5,
                                  dashArray: [6, 4],
                                ),
                              ],
                            ),
                            barGroups: historyData.chartBars.asMap().entries.map((entry) {
                              final idx = entry.key;
                              final bar = entry.value;
                              final successColor = theme.colorScheme.secondary;
                              final primaryColor = theme.colorScheme.primary;

                              return BarChartGroupData(
                                x: idx,
                                barRods: [
                                  BarChartRodData(
                                    toY: bar.value,
                                    color: bar.isSuccess ? successColor : primaryColor,
                                    width: _selectedPeriod == 'monthly' ? 5 : (_selectedPeriod == 'weekly' ? 20 : 12),
                                    borderRadius: const BorderRadius.all(Radius.circular(4)),
                                    backDrawRodData: BackgroundBarChartRodData(
                                      show: true,
                                      toY: maxY,
                                      color: theme.colorScheme.onSurfaceVariant.withOpacity(0.05),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                ),
                const SizedBox(height: 24),

                // Stat Cards Row
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        context,
                        title: 'Success',
                        value: historyData.successCount.toString(),
                        labelColor: theme.colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        context,
                        title: 'Missed',
                        value: historyData.missedCount.toString(),
                        labelColor: theme.colorScheme.error,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        context,
                        title: 'Avg/day',
                        value: _formatAverage(historyData.averageIntake, unit),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Export Button
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ExportSummaryScreen(
                          initialPeriod: _selectedPeriod,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    height: 54,
                    decoration: BoxDecoration(
                      color: theme.brightness == Brightness.light ? Colors.white : const Color(0xff1B2430),
                      border: Border.all(
                        color: theme.colorScheme.onSurfaceVariant.withOpacity(0.15),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(14.0),
                      boxShadow: theme.brightness == Brightness.light
                          ? [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              )
                            ]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Export / Email summary',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    Color? labelColor,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? (theme.brightness == Brightness.light ? const Color(0xffF2F5F8) : const Color(0xff1B2430)),
        borderRadius: BorderRadius.circular(14.0),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: labelColor ?? theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
