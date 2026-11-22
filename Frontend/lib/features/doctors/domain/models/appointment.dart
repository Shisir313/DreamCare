import 'doctor.dart';

/// Appointment status
enum AppointmentStatus {
  scheduled,
  confirmed,
  inProgress,
  completed,
  cancelled,
  noShow;

  String get displayName {
    switch (this) {
      case AppointmentStatus.scheduled:
        return 'Scheduled';
      case AppointmentStatus.confirmed:
        return 'Confirmed';
      case AppointmentStatus.inProgress:
        return 'In Progress';
      case AppointmentStatus.completed:
        return 'Completed';
      case AppointmentStatus.cancelled:
        return 'Cancelled';
      case AppointmentStatus.noShow:
        return 'No Show';
    }
  }
}

/// Appointment type
enum AppointmentType {
  video,
  inPerson;

  String get displayName {
    switch (this) {
      case AppointmentType.video:
        return 'Video Consultation';
      case AppointmentType.inPerson:
        return 'In-Person Visit';
    }
  }
}

/// Time slot for appointments
class TimeSlot {
  const TimeSlot({
    required this.startTime,
    required this.endTime,
    required this.isAvailable,
  });

  final DateTime startTime;
  final DateTime endTime;
  final bool isAvailable;

  String get timeRange {
    final start = '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
    final end = '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
    return '$start - $end';
  }

  TimeSlot copyWith({
    DateTime? startTime,
    DateTime? endTime,
    bool? isAvailable,
  }) {
    return TimeSlot(
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }
}

/// Appointment model
class Appointment {
  const Appointment({
    required this.id,
    required this.doctorId,
    required this.userId,
    required this.dateTime,
    required this.type,
    required this.status,
    required this.fee,
    this.doctor,
    this.symptoms,
    this.notes,
    this.prescriptionId,
    this.meetingLink,
    this.createdAt,
  });

  final String id;
  final String doctorId;
  final String userId;
  final DateTime dateTime;
  final AppointmentType type;
  final AppointmentStatus status;
  final int fee; // NPR
  final Doctor? doctor;
  final String? symptoms;
  final String? notes;
  final String? prescriptionId;
  final String? meetingLink;
  final DateTime? createdAt;

  String get dateText {
    final now = DateTime.now();
    final diff = dateTime.difference(now).inDays;
    
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  String get timeText {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String get feeText => 'Rs $fee';

  bool get isPast => dateTime.isBefore(DateTime.now());
  bool get isToday {
    final now = DateTime.now();
    return dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day;
  }

  Appointment copyWith({
    String? id,
    String? doctorId,
    String? userId,
    DateTime? dateTime,
    AppointmentType? type,
    AppointmentStatus? status,
    int? fee,
    Doctor? doctor,
    String? symptoms,
    String? notes,
    String? prescriptionId,
    String? meetingLink,
    DateTime? createdAt,
  }) {
    return Appointment(
      id: id ?? this.id,
      doctorId: doctorId ?? this.doctorId,
      userId: userId ?? this.userId,
      dateTime: dateTime ?? this.dateTime,
      type: type ?? this.type,
      status: status ?? this.status,
      fee: fee ?? this.fee,
      doctor: doctor ?? this.doctor,
      symptoms: symptoms ?? this.symptoms,
      notes: notes ?? this.notes,
      prescriptionId: prescriptionId ?? this.prescriptionId,
      meetingLink: meetingLink ?? this.meetingLink,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
