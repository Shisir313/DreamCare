import '../../domain/models/doctor.dart';
import '../../domain/models/appointment.dart';

/// Fake doctors repository with sample data
class FakeDoctorsRepository {
  // Sample doctors
  static final List<Doctor> _doctors = [
    Doctor(
      id: 'doc_001',
      name: 'Dr. Anjali Sharma',
      specialty: DoctorSpecialty.dermatologist,
      qualifications: 'MBBS, MD (Dermatology)',
      experience: 12,
      rating: 4.8,
      totalReviews: 156,
      consultationFee: 1500,
      availableDays: [1, 2, 3, 4, 6], // Mon-Thu, Sat
      hospital: 'Nepal Mediciti Hospital',
      about: 'Specialized in acne treatment, skin allergies, and anti-aging procedures. Over 12 years of experience treating various skin conditions.',
      languages: ['English', 'Nepali', 'Hindi'],
      isAvailableToday: true,
    ),
    Doctor(
      id: 'doc_002',
      name: 'Dr. Rajesh Thapa',
      specialty: DoctorSpecialty.dermatologist,
      qualifications: 'MBBS, MD (Dermatology), Fellowship (UK)',
      experience: 15,
      rating: 4.9,
      totalReviews: 203,
      consultationFee: 2000,
      availableDays: [1, 3, 5], // Mon, Wed, Fri
      hospital: 'Grande International Hospital',
      about: 'Expert in treating complex skin conditions, psoriasis, eczema, and cosmetic dermatology.',
      languages: ['English', 'Nepali'],
      isAvailableToday: false,
      nextAvailableDate: DateTime.now().add(const Duration(days: 2)),
    ),
    Doctor(
      id: 'doc_003',
      name: 'Dr. Sushma Karki',
      specialty: DoctorSpecialty.cosmetologist,
      qualifications: 'MBBS, PG Diploma (Aesthetic Medicine)',
      experience: 8,
      rating: 4.7,
      totalReviews: 98,
      consultationFee: 1200,
      availableDays: [2, 4, 6, 7], // Tue, Thu, Sat, Sun
      hospital: 'Skin & Aesthetics Clinic',
      about: 'Specializes in laser treatments, chemical peels, and non-surgical face lifts.',
      languages: ['English', 'Nepali'],
      isAvailableToday: true,
    ),
    Doctor(
      id: 'doc_004',
      name: 'Dr. Binod Adhikari',
      specialty: DoctorSpecialty.dermatologist,
      qualifications: 'MBBS, MD (Dermatology)',
      experience: 10,
      rating: 4.6,
      totalReviews: 142,
      consultationFee: 1000,
      availableDays: [1, 2, 3, 4, 5, 6], // Mon-Sat
      hospital: 'Patan Hospital',
      about: 'Experienced in treating skin infections, fungal conditions, and hair loss problems.',
      languages: ['English', 'Nepali', 'Newari'],
      isAvailableToday: true,
    ),
    Doctor(
      id: 'doc_005',
      name: 'Dr. Meera Shrestha',
      specialty: DoctorSpecialty.trichologist,
      qualifications: 'MBBS, Certified Trichologist',
      experience: 6,
      rating: 4.5,
      totalReviews: 67,
      consultationFee: 800,
      availableDays: [1, 3, 5, 6], // Mon, Wed, Fri, Sat
      hospital: 'Hair & Skin Clinic Pvt. Ltd.',
      about: 'Specialist in hair loss treatment, scalp disorders, and hair transplantation.',
      languages: ['English', 'Nepali'],
      isAvailableToday: false,
      nextAvailableDate: DateTime.now().add(const Duration(days: 1)),
    ),
  ];

  // Sample reviews
  static final List<DoctorReview> _reviews = [
    DoctorReview(
      id: 'rev_001',
      doctorId: 'doc_001',
      userId: 'user_sujana_001',
      userName: 'Sujana S.',
      rating: 5,
      comment: 'Excellent doctor! Very thorough examination and clear explanation of treatment.',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      response: 'Thank you for your kind words!',
    ),
    DoctorReview(
      id: 'rev_002',
      doctorId: 'doc_001',
      userId: 'user_triyog_002',
      userName: 'Triyog S.',
      rating: 5,
      comment: 'Dr. Sharma is very patient and knowledgeable. Highly recommended!',
      createdAt: DateTime.now().subtract(const Duration(days: 12)),
    ),
    DoctorReview(
      id: 'rev_003',
      doctorId: 'doc_002',
      userId: 'user_rasmi_003',
      userName: 'Rasmi T.',
      rating: 5,
      comment: 'Best dermatologist in Kathmandu! My skin condition improved significantly.',
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
    ),
  ];

  Future<List<Doctor>> getDoctors({
    DoctorSpecialty? specialty,
    bool? availableToday,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    var filtered = _doctors;

    if (specialty != null) {
      filtered = filtered.where((d) => d.specialty == specialty).toList();
    }

    if (availableToday == true) {
      filtered = filtered.where((d) => d.isAvailableToday).toList();
    }

    return filtered;
  }

  Future<Doctor?> getDoctor(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      return _doctors.firstWhere((d) => d.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<List<DoctorReview>> getDoctorReviews(String doctorId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _reviews.where((r) => r.doctorId == doctorId).toList();
  }

  Future<List<TimeSlot>> getAvailableSlots(String doctorId, DateTime date) async {
    await Future.delayed(const Duration(milliseconds: 500));

    // Generate sample time slots for the day
    final slots = <TimeSlot>[];
    final now = DateTime.now();
    
    // Morning slots: 9 AM - 12 PM
    for (int hour = 9; hour < 12; hour++) {
      final start = DateTime(date.year, date.month, date.day, hour, 0);
      final end = DateTime(date.year, date.month, date.day, hour, 30);
      
      // Make some slots unavailable randomly
      final isAvailable = start.isAfter(now) && (hour % 2 == 0 || hour == 11);
      
      slots.add(TimeSlot(
        startTime: start,
        endTime: end,
        isAvailable: isAvailable,
      ));
    }

    // Afternoon slots: 2 PM - 5 PM
    for (int hour = 14; hour < 17; hour++) {
      final start = DateTime(date.year, date.month, date.day, hour, 0);
      final end = DateTime(date.year, date.month, date.day, hour, 30);
      
      final isAvailable = start.isAfter(now) && (hour % 3 != 0);
      
      slots.add(TimeSlot(
        startTime: start,
        endTime: end,
        isAvailable: isAvailable,
      ));
    }

    return slots;
  }

  Future<Appointment> bookAppointment({
    required String doctorId,
    required DateTime dateTime,
    required AppointmentType type,
    String? symptoms,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));

    final doctor = await getDoctor(doctorId);

    return Appointment(
      id: 'apt_${DateTime.now().millisecondsSinceEpoch}',
      doctorId: doctorId,
      userId: 'current_user', // Would come from auth
      dateTime: dateTime,
      type: type,
      status: AppointmentStatus.scheduled,
      fee: doctor?.consultationFee ?? 1000,
      doctor: doctor,
      symptoms: symptoms,
      createdAt: DateTime.now(),
      meetingLink: type == AppointmentType.video
          ? 'https://meet.dermacare.com/${DateTime.now().millisecondsSinceEpoch}'
          : null,
    );
  }
}
