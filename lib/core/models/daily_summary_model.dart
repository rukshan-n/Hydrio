class DailySummary {
  final String dayKey; // Format: "YYYY-MM-DD"
  final int targetMl;
  final int totalMl;
  final double completionPct; // e.g., 0.85 for 85%
  final String status; // "success" or "missed"

  const DailySummary({
    required this.dayKey,
    required this.targetMl,
    required this.totalMl,
    required this.completionPct,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'day_key': dayKey,
      'target_ml': targetMl,
      'total_ml': totalMl,
      'completion_pct': completionPct,
      'status': status,
    };
  }

  factory DailySummary.fromMap(Map<String, dynamic> map) {
    return DailySummary(
      dayKey: map['day_key'] as String,
      targetMl: map['target_ml'] as int,
      totalMl: map['total_ml'] as int,
      completionPct: (map['completion_pct'] as num).toDouble(),
      status: map['status'] as String,
    );
  }

  DailySummary copyWith({
    String? dayKey,
    int? targetMl,
    int? totalMl,
    double? completionPct,
    String? status,
  }) {
    return DailySummary(
      dayKey: dayKey ?? this.dayKey,
      targetMl: targetMl ?? this.targetMl,
      totalMl: totalMl ?? this.totalMl,
      completionPct: completionPct ?? this.completionPct,
      status: status ?? this.status,
    );
  }
}
