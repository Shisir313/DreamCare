/// Symptom severity
enum Severity {
  mild,
  moderate,
  severe;

  String get displayName {
    switch (this) {
      case Severity.mild:
        return 'Mild';
      case Severity.moderate:
        return 'Moderate';
      case Severity.severe:
        return 'Severe';
    }
  }

  int get level {
    switch (this) {
      case Severity.mild:
        return 1;
      case Severity.moderate:
        return 2;
      case Severity.severe:
        return 3;
    }
  }
}

/// Common skin symptoms
enum Symptom {
  acne,
  redness,
  dryness,
  oiliness,
  itching,
  burning,
  rash,
  darkSpots,
  wrinkles,
  puffiness,
  other;

  String get displayName {
    switch (this) {
      case Symptom.acne:
        return 'Acne/Breakouts';
      case Symptom.redness:
        return 'Redness';
      case Symptom.dryness:
        return 'Dryness';
      case Symptom.oiliness:
        return 'Oiliness';
      case Symptom.itching:
        return 'Itching';
      case Symptom.burning:
        return 'Burning';
      case Symptom.rash:
        return 'Rash';
      case Symptom.darkSpots:
        return 'Dark Spots';
      case Symptom.wrinkles:
        return 'Wrinkles';
      case Symptom.puffiness:
        return 'Puffiness';
      case Symptom.other:
        return 'Other';
    }
  }
}

/// Skin log entry
class SkinLog {
  const SkinLog({
    required this.id,
    required this.userId,
    required this.loggedAt,
    required this.symptoms,
    this.severity = Severity.mild,
    this.notes,
    this.triggers,
    this.mood,
    this.photoId,
  });

  final String id;
  final String userId;
  final DateTime loggedAt;
  final List<Symptom> symptoms;
  final Severity severity;
  final String? notes;
  final List<String>? triggers; // e.g., "stress", "new product", "weather"
  final int? mood; // 1-5 scale
  final String? photoId;

  String get dateText {
    final now = DateTime.now();
    final diff = now.difference(loggedAt).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return '$diff days ago';
    return '${loggedAt.day}/${loggedAt.month}/${loggedAt.year}';
  }

  String get symptomsText => symptoms.map((s) => s.displayName).join(', ');

  SkinLog copyWith({
    String? id,
    String? userId,
    DateTime? loggedAt,
    List<Symptom>? symptoms,
    Severity? severity,
    String? notes,
    List<String>? triggers,
    int? mood,
    String? photoId,
  }) {
    return SkinLog(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      loggedAt: loggedAt ?? this.loggedAt,
      symptoms: symptoms ?? this.symptoms,
      severity: severity ?? this.severity,
      notes: notes ?? this.notes,
      triggers: triggers ?? this.triggers,
      mood: mood ?? this.mood,
      photoId: photoId ?? this.photoId,
    );
  }
}
