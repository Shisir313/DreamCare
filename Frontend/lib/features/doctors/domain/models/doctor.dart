/// Doctor specialties
enum DoctorSpecialty {
  dermatologist,
  cosmetologist,
  aesthetician,
  trichologist;

  String get displayName {
    switch (this) {
      case DoctorSpecialty.dermatologist:
        return 'Dermatologist';
      case DoctorSpecialty.cosmetologist:
        return 'Cosmetologist';
      case DoctorSpecialty.aesthetician:
        return 'Aesthetician';
      case DoctorSpecialty.trichologist:
        return 'Trichologist';
    }
  }

  String get description {
    switch (this) {
      case DoctorSpecialty.dermatologist:
        return 'Medical skin conditions & treatment';
      case DoctorSpecialty.cosmetologist:
        return 'Cosmetic procedures & aesthetics';
      case DoctorSpecialty.aesthetician:
        return 'Skincare treatments & facials';
      case DoctorSpecialty.trichologist:
        return 'Hair & scalp specialist';
    }
  }
}

/// Doctor model
class Doctor {
  const Doctor({
    required this.id,
    required this.name,
    required this.specialty,
    required this.qualifications,
    required this.experience,
    required this.rating,
    required this.totalReviews,
    required this.consultationFee,
    required this.availableDays,
    this.photoUrl,
    this.hospital,
    this.about,
    this.languages = const ['English', 'Nepali'],
    this.isAvailableToday = false,
    this.nextAvailableDate,
  });

  final String id;
  final String name;
  final DoctorSpecialty specialty;
  final String qualifications;
  final int experience; // years
  final double rating;
  final int totalReviews;
  final int consultationFee; // NPR
  final List<int> availableDays; // 1=Monday, 7=Sunday
  final String? photoUrl;
  final String? hospital;
  final String? about;
  final List<String> languages;
  final bool isAvailableToday;
  final DateTime? nextAvailableDate;

  String get experienceText => '$experience+ years';
  String get feeText => 'Rs $consultationFee';
  String get ratingText => rating.toStringAsFixed(1);
  String get reviewsText => '$totalReviews reviews';

  Doctor copyWith({
    String? id,
    String? name,
    DoctorSpecialty? specialty,
    String? qualifications,
    int? experience,
    double? rating,
    int? totalReviews,
    int? consultationFee,
    List<int>? availableDays,
    String? photoUrl,
    String? hospital,
    String? about,
    List<String>? languages,
    bool? isAvailableToday,
    DateTime? nextAvailableDate,
  }) {
    return Doctor(
      id: id ?? this.id,
      name: name ?? this.name,
      specialty: specialty ?? this.specialty,
      qualifications: qualifications ?? this.qualifications,
      experience: experience ?? this.experience,
      rating: rating ?? this.rating,
      totalReviews: totalReviews ?? this.totalReviews,
      consultationFee: consultationFee ?? this.consultationFee,
      availableDays: availableDays ?? this.availableDays,
      photoUrl: photoUrl ?? this.photoUrl,
      hospital: hospital ?? this.hospital,
      about: about ?? this.about,
      languages: languages ?? this.languages,
      isAvailableToday: isAvailableToday ?? this.isAvailableToday,
      nextAvailableDate: nextAvailableDate ?? this.nextAvailableDate,
    );
  }
}

/// Doctor review
class DoctorReview {
  const DoctorReview({
    required this.id,
    required this.doctorId,
    required this.userId,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.response,
  });

  final String id;
  final String doctorId;
  final String userId;
  final String userName;
  final int rating; // 1-5
  final String comment;
  final DateTime createdAt;
  final String? response; // Doctor's response

  DoctorReview copyWith({
    String? id,
    String? doctorId,
    String? userId,
    String? userName,
    int? rating,
    String? comment,
    DateTime? createdAt,
    String? response,
  }) {
    return DoctorReview(
      id: id ?? this.id,
      doctorId: doctorId ?? this.doctorId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
      response: response ?? this.response,
    );
  }
}
