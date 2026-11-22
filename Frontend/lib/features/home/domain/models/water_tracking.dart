class WaterTracking {
  final DateTime date;
  final int glassesCompleted;
  final int dailyGoal;
  final List<DateTime> timestamps;

  WaterTracking({
    required this.date,
    required this.glassesCompleted,
    this.dailyGoal = 8,
    required this.timestamps,
  });

  double get progress => glassesCompleted / dailyGoal;
  int get remainingGlasses => dailyGoal - glassesCompleted;
  bool get goalReached => glassesCompleted >= dailyGoal;
  int get percentComplete => ((progress * 100).clamp(0, 100)).toInt();

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'glassesCompleted': glassesCompleted,
    'dailyGoal': dailyGoal,
    'timestamps': timestamps.map((t) => t.toIso8601String()).toList(),
  };

  factory WaterTracking.fromJson(Map<String, dynamic> json) {
    return WaterTracking(
      date: DateTime.parse(json['date']),
      glassesCompleted: json['glassesCompleted'],
      dailyGoal: json['dailyGoal'] ?? 8,
      timestamps: (json['timestamps'] as List)
          .map((t) => DateTime.parse(t as String))
          .toList(),
    );
  }

  WaterTracking copyWith({
    DateTime? date,
    int? glassesCompleted,
    int? dailyGoal,
    List<DateTime>? timestamps,
  }) {
    return WaterTracking(
      date: date ?? this.date,
      glassesCompleted: glassesCompleted ?? this.glassesCompleted,
      dailyGoal: dailyGoal ?? this.dailyGoal,
      timestamps: timestamps ?? this.timestamps,
    );
  }
}
