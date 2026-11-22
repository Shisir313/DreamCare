import '../../../doctors/domain/models/doctor.dart';

/// Prescription status
enum PrescriptionStatus {
  active,
  completed,
  cancelled,
  expired;

  String get displayName {
    switch (this) {
      case PrescriptionStatus.active:
        return 'Active';
      case PrescriptionStatus.completed:
        return 'Completed';
      case PrescriptionStatus.cancelled:
        return 'Cancelled';
      case PrescriptionStatus.expired:
        return 'Expired';
    }
  }
}

/// Medication in a prescription
class Medication {
  const Medication({
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.duration,
    this.instructions,
    this.beforeMeal = false,
  });

  final String name;
  final String dosage;
  final String frequency; // e.g., "Twice daily", "Once at night"
  final String duration; // e.g., "7 days", "2 weeks"
  final String? instructions;
  final bool beforeMeal;

  Medication copyWith({
    String? name,
    String? dosage,
    String? frequency,
    String? duration,
    String? instructions,
    bool? beforeMeal,
  }) {
    return Medication(
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      frequency: frequency ?? this.frequency,
      duration: duration ?? this.duration,
      instructions: instructions ?? this.instructions,
      beforeMeal: beforeMeal ?? this.beforeMeal,
    );
  }
}

/// Prescription model
class Prescription {
  const Prescription({
    required this.id,
    required this.doctorId,
    required this.userId,
    required this.medications,
    required this.diagnosis,
    required this.prescribedDate,
    required this.status,
    this.doctor,
    this.notes,
    this.followUpDate,
    this.labTests,
  });

  final String id;
  final String doctorId;
  final String userId;
  final List<Medication> medications;
  final String diagnosis;
  final DateTime prescribedDate;
  final PrescriptionStatus status;
  final Doctor? doctor;
  final String? notes;
  final DateTime? followUpDate;
  final List<String>? labTests;

  String get dateText {
    final now = DateTime.now();
    final diff = now.difference(prescribedDate).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return '$diff days ago';
    if (diff < 30) return '${(diff / 7).floor()} weeks ago';
    return '${prescribedDate.day}/${prescribedDate.month}/${prescribedDate.year}';
  }

  bool get hasFollowUp => followUpDate != null;
  bool get isExpired => status == PrescriptionStatus.expired;

  Prescription copyWith({
    String? id,
    String? doctorId,
    String? userId,
    List<Medication>? medications,
    String? diagnosis,
    DateTime? prescribedDate,
    PrescriptionStatus? status,
    Doctor? doctor,
    String? notes,
    DateTime? followUpDate,
    List<String>? labTests,
  }) {
    return Prescription(
      id: id ?? this.id,
      doctorId: doctorId ?? this.doctorId,
      userId: userId ?? this.userId,
      medications: medications ?? this.medications,
      diagnosis: diagnosis ?? this.diagnosis,
      prescribedDate: prescribedDate ?? this.prescribedDate,
      status: status ?? this.status,
      doctor: doctor ?? this.doctor,
      notes: notes ?? this.notes,
      followUpDate: followUpDate ?? this.followUpDate,
      labTests: labTests ?? this.labTests,
    );
  }
}
