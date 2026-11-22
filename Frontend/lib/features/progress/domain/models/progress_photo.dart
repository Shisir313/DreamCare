/// Body area for progress photos
enum BodyArea {
  face,
  forehead,
  cheeks,
  chin,
  neck,
  chest,
  back,
  arms,
  hands,
  legs,
  other;

  String get displayName {
    switch (this) {
      case BodyArea.face:
        return 'Face';
      case BodyArea.forehead:
        return 'Forehead';
      case BodyArea.cheeks:
        return 'Cheeks';
      case BodyArea.chin:
        return 'Chin';
      case BodyArea.neck:
        return 'Neck';
      case BodyArea.chest:
        return 'Chest';
      case BodyArea.back:
        return 'Back';
      case BodyArea.arms:
        return 'Arms';
      case BodyArea.hands:
        return 'Hands';
      case BodyArea.legs:
        return 'Legs';
      case BodyArea.other:
        return 'Other';
    }
  }
}

/// Photo type
enum PhotoType {
  before,
  progress,
  after;

  String get displayName {
    switch (this) {
      case PhotoType.before:
        return 'Before';
      case PhotoType.progress:
        return 'Progress';
      case PhotoType.after:
        return 'After';
    }
  }
}

/// Progress photo model
class ProgressPhoto {
  const ProgressPhoto({
    required this.id,
    required this.userId,
    required this.photoUrl,
    required this.takenAt,
    required this.bodyArea,
    required this.type,
    this.notes,
    this.tags = const [],
    this.isPrivate = true,
  });

  final String id;
  final String userId;
  final String photoUrl;
  final DateTime takenAt;
  final BodyArea bodyArea;
  final PhotoType type;
  final String? notes;
  final List<String> tags;
  final bool isPrivate;

  String get dateText {
    final now = DateTime.now();
    final diff = now.difference(takenAt).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return '$diff days ago';
    if (diff < 30) return '${(diff / 7).floor()} weeks ago';
    return '${takenAt.day}/${takenAt.month}/${takenAt.year}';
  }

  ProgressPhoto copyWith({
    String? id,
    String? userId,
    String? photoUrl,
    DateTime? takenAt,
    BodyArea? bodyArea,
    PhotoType? type,
    String? notes,
    List<String>? tags,
    bool? isPrivate,
  }) {
    return ProgressPhoto(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      photoUrl: photoUrl ?? this.photoUrl,
      takenAt: takenAt ?? this.takenAt,
      bodyArea: bodyArea ?? this.bodyArea,
      type: type ?? this.type,
      notes: notes ?? this.notes,
      tags: tags ?? this.tags,
      isPrivate: isPrivate ?? this.isPrivate,
    );
  }
}

/// Photo comparison model
class PhotoComparison {
  const PhotoComparison({
    required this.beforePhoto,
    required this.afterPhoto,
    required this.daysBetween,
  });

  final ProgressPhoto beforePhoto;
  final ProgressPhoto afterPhoto;
  final int daysBetween;

  String get durationText {
    if (daysBetween < 7) return '$daysBetween days';
    if (daysBetween < 30) return '${(daysBetween / 7).floor()} weeks';
    return '${(daysBetween / 30).floor()} months';
  }
}
