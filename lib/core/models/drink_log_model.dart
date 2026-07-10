class DrinkLog {
  final int? id;
  final int amountMl;
  final int timestamp; // Unix timestamp in milliseconds
  final String dayKey; // Format: "YYYY-MM-DD"

  const DrinkLog({
    this.id,
    required this.amountMl,
    required this.timestamp,
    required this.dayKey,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'amount_ml': amountMl,
      'timestamp': timestamp,
      'day_key': dayKey,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  factory DrinkLog.fromMap(Map<String, dynamic> map) {
    return DrinkLog(
      id: map['id'] as int?,
      amountMl: map['amount_ml'] as int,
      timestamp: map['timestamp'] as int,
      dayKey: map['day_key'] as String,
    );
  }

  DrinkLog copyWith({
    int? id,
    int? amountMl,
    int? timestamp,
    String? dayKey,
  }) {
    return DrinkLog(
      id: id ?? this.id,
      amountMl: amountMl ?? this.amountMl,
      timestamp: timestamp ?? this.timestamp,
      dayKey: dayKey ?? this.dayKey,
    );
  }
}
