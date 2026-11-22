import '../../domain/models/progress_photo.dart';
import '../../domain/models/skin_log.dart';

/// Fake progress repository
class FakeProgressRepository {
  static final List<ProgressPhoto> _photos = [
    ProgressPhoto(
      id: 'photo_001',
      userId: 'user_sujana_001',
      photoUrl: 'https://placeholder.com/600x800',
      takenAt: DateTime.now().subtract(const Duration(days: 60)),
      bodyArea: BodyArea.face,
      type: PhotoType.before,
      notes: 'Starting acne treatment',
      tags: ['acne', 'forehead', 'cheeks'],
    ),
    ProgressPhoto(
      id: 'photo_002',
      userId: 'user_sujana_001',
      photoUrl: 'https://placeholder.com/600x800',
      takenAt: DateTime.now().subtract(const Duration(days: 30)),
      bodyArea: BodyArea.face,
      type: PhotoType.progress,
      notes: '1 month progress - some improvement visible',
      tags: ['acne', 'improvement'],
    ),
    ProgressPhoto(
      id: 'photo_003',
      userId: 'user_sujana_001',
      photoUrl: 'https://placeholder.com/600x800',
      takenAt: DateTime.now().subtract(const Duration(days: 7)),
      bodyArea: BodyArea.face,
      type: PhotoType.progress,
      notes: '7 weeks progress - significant improvement',
      tags: ['acne', 'clear'],
    ),
    ProgressPhoto(
      id: 'photo_004',
      userId: 'user_sujana_001',
      photoUrl: 'https://placeholder.com/600x800',
      takenAt: DateTime.now().subtract(const Duration(days: 90)),
      bodyArea: BodyArea.cheeks,
      type: PhotoType.before,
      notes: 'Dark spots before treatment',
      tags: ['hyperpigmentation', 'melasma'],
    ),
  ];

  static final List<SkinLog> _logs = [
    SkinLog(
      id: 'log_001',
      userId: 'user_sujana_001',
      loggedAt: DateTime.now().subtract(const Duration(days: 1)),
      symptoms: [Symptom.acne, Symptom.redness],
      severity: Severity.mild,
      notes: 'Small breakout on chin, likely due to stress',
      triggers: ['stress', 'lack of sleep'],
      mood: 3,
    ),
    SkinLog(
      id: 'log_002',
      userId: 'user_sujana_001',
      loggedAt: DateTime.now().subtract(const Duration(days: 5)),
      symptoms: [Symptom.dryness],
      severity: Severity.mild,
      notes: 'Skin feeling tight after cleansing',
      triggers: ['weather'],
      mood: 4,
    ),
    SkinLog(
      id: 'log_003',
      userId: 'user_sujana_001',
      loggedAt: DateTime.now().subtract(const Duration(days: 10)),
      symptoms: [Symptom.acne, Symptom.oiliness],
      severity: Severity.moderate,
      notes: 'Multiple new pimples on forehead and cheeks',
      triggers: ['new product', 'hormonal'],
      mood: 2,
    ),
    SkinLog(
      id: 'log_004',
      userId: 'user_sujana_001',
      loggedAt: DateTime.now().subtract(const Duration(days: 15)),
      symptoms: [Symptom.redness, Symptom.itching],
      severity: Severity.moderate,
      notes: 'Irritation after trying new moisturizer',
      triggers: ['new product'],
      mood: 2,
    ),
    SkinLog(
      id: 'log_005',
      userId: 'user_sujana_001',
      loggedAt: DateTime.now().subtract(const Duration(days: 20)),
      symptoms: [Symptom.acne],
      severity: Severity.mild,
      notes: 'Few small pimples, overall improvement',
      mood: 4,
    ),
  ];

  Future<List<ProgressPhoto>> getPhotos({
    BodyArea? bodyArea,
    PhotoType? type,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    var filtered = _photos;

    if (bodyArea != null) {
      filtered = filtered.where((p) => p.bodyArea == bodyArea).toList();
    }

    if (type != null) {
      filtered = filtered.where((p) => p.type == type).toList();
    }

    return filtered..sort((a, b) => b.takenAt.compareTo(a.takenAt));
  }

  Future<ProgressPhoto?> getPhoto(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      return _photos.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<List<SkinLog>> getLogs({
    int? limit,
    DateTime? since,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    var filtered = _logs;

    if (since != null) {
      filtered = filtered.where((l) => l.loggedAt.isAfter(since)).toList();
    }

    filtered.sort((a, b) => b.loggedAt.compareTo(a.loggedAt));

    if (limit != null && filtered.length > limit) {
      filtered = filtered.take(limit).toList();
    }

    return filtered;
  }

  Future<SkinLog?> getLog(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      return _logs.firstWhere((l) => l.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<PhotoComparison?> getComparison({
    required String beforePhotoId,
    required String afterPhotoId,
  }) async {
    final before = await getPhoto(beforePhotoId);
    final after = await getPhoto(afterPhotoId);

    if (before == null || after == null) return null;

    final daysBetween = after.takenAt.difference(before.takenAt).inDays;

    return PhotoComparison(
      beforePhoto: before,
      afterPhoto: after,
      daysBetween: daysBetween,
    );
  }

  Future<List<PhotoComparison>> getAutoComparisons() async {
    await Future.delayed(const Duration(milliseconds: 500));

    // Auto-generate comparisons from face photos
    final facePhotos = await getPhotos(bodyArea: BodyArea.face);
    if (facePhotos.length < 2) return [];

    final comparisons = <PhotoComparison>[];

    // Create comparison between first (before) and latest photo
    if (facePhotos.isNotEmpty) {
      final before = facePhotos.last; // Oldest
      final after = facePhotos.first; // Latest

      final daysBetween = after.takenAt.difference(before.takenAt).inDays;

      comparisons.add(PhotoComparison(
        beforePhoto: before,
        afterPhoto: after,
        daysBetween: daysBetween,
      ));
    }

    return comparisons;
  }
}
