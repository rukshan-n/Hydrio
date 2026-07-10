class ChartBarItem {
  final String label;
  final double value; // in mL
  final bool isSuccess;
  final String tooltipText;
  final DateTime? date;

  const ChartBarItem({
    required this.label,
    required this.value,
    required this.isSuccess,
    required this.tooltipText,
    this.date,
  });
}

class HistoryPeriodData {
  final List<ChartBarItem> chartBars;
  final int successCount;
  final int missedCount;
  final double averageIntake; // in mL
  final double targetVolume; // in mL

  const HistoryPeriodData({
    required this.chartBars,
    required this.successCount,
    required this.missedCount,
    required this.averageIntake,
    required this.targetVolume,
  });
}
