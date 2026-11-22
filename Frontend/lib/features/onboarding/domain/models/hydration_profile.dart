/// Hydration profile captured during onboarding
class HydrationProfile {
  const HydrationProfile({
    required this.weightKg,
    required this.dailyGoalML,
  });

  final double weightKg;
  final int dailyGoalML;

  /// Calculate recommended daily water intake based on weight
  /// Formula: 30ml per kg of body weight
  static int calculateRecommendedIntake(double weightKg) {
    return (weightKg * 30).round();
  }

  /// Convert goal to number of glasses (250ml each)
  int get glassesPerDay {
    return (dailyGoalML / 250).ceil();
  }

  HydrationProfile copyWith({
    double? weightKg,
    int? dailyGoalML,
  }) {
    return HydrationProfile(
      weightKg: weightKg ?? this.weightKg,
      dailyGoalML: dailyGoalML ?? this.dailyGoalML,
    );
  }
}
