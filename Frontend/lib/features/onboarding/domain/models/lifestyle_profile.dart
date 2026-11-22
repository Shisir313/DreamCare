/// Lifestyle profile captured during onboarding
class LifestyleProfile {
  const LifestyleProfile({
    required this.sleepHours,
    required this.stressLevel,
    required this.activityLevel,
  });

  final int sleepHours;
  final StressLevel stressLevel;
  final ActivityLevel activityLevel;

  LifestyleProfile copyWith({
    int? sleepHours,
    StressLevel? stressLevel,
    ActivityLevel? activityLevel,
  }) {
    return LifestyleProfile(
      sleepHours: sleepHours ?? this.sleepHours,
      stressLevel: stressLevel ?? this.stressLevel,
      activityLevel: activityLevel ?? this.activityLevel,
    );
  }
}

/// Stress level enum
enum StressLevel {
  low('Low', 'Rarely stressed, calm most days'),
  moderate('Moderate', 'Some stress, manageable'),
  high('High', 'Often stressed, hard to relax');

  const StressLevel(this.label, this.description);
  final String label;
  final String description;
}

/// Activity level enum
enum ActivityLevel {
  sedentary('Sedentary', 'Mostly sitting, minimal exercise'),
  light('Light', 'Light exercise 1-2 days/week'),
  moderate('Moderate', 'Moderate exercise 3-4 days/week'),
  active('Active', 'Intense exercise 5+ days/week');

  const ActivityLevel(this.label, this.description);
  final String label;
  final String description;
}
