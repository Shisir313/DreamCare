import '../../domain/models/prescription.dart';
import '../../../doctors/domain/models/doctor.dart';

/// Fake prescriptions repository
class FakePrescriptionsRepository {
  static final List<Prescription> _prescriptions = [
    Prescription(
      id: 'presc_001',
      doctorId: 'doc_001',
      userId: 'user_sujana_001',
      diagnosis: 'Acne Vulgaris (Moderate)',
      prescribedDate: DateTime.now().subtract(const Duration(days: 3)),
      status: PrescriptionStatus.active,
      medications: [
        const Medication(
          name: 'Adapalene Gel 0.1%',
          dosage: 'Apply thin layer',
          frequency: 'Once daily at night',
          duration: '8 weeks',
          instructions: 'Apply to clean, dry skin. Avoid sun exposure.',
        ),
        const Medication(
          name: 'Clindamycin Gel 1%',
          dosage: 'Apply thin layer',
          frequency: 'Twice daily',
          duration: '8 weeks',
          instructions: 'Use morning and evening after cleansing.',
        ),
        const Medication(
          name: 'Doxycycline',
          dosage: '100mg',
          frequency: 'Once daily',
          duration: '4 weeks',
          instructions: 'Take with food to avoid stomach upset.',
          beforeMeal: false,
        ),
      ],
      notes: 'Avoid excessive sun exposure. Use sunscreen daily. Follow up in 4 weeks to assess progress.',
      followUpDate: DateTime.now().add(const Duration(days: 25)),
      doctor: const Doctor(
        id: 'doc_001',
        name: 'Dr. Anjali Sharma',
        specialty: DoctorSpecialty.dermatologist,
        qualifications: 'MBBS, MD (Dermatology)',
        experience: 12,
        rating: 4.8,
        totalReviews: 156,
        consultationFee: 1500,
        availableDays: [1, 2, 3, 4, 6],
        hospital: 'Nepal Mediciti Hospital',
      ),
    ),
    Prescription(
      id: 'presc_002',
      doctorId: 'doc_003',
      userId: 'user_sujana_001',
      diagnosis: 'Melasma',
      prescribedDate: DateTime.now().subtract(const Duration(days: 45)),
      status: PrescriptionStatus.completed,
      medications: [
        const Medication(
          name: 'Hydroquinone Cream 4%',
          dosage: 'Apply thin layer',
          frequency: 'Once daily at night',
          duration: '6 weeks',
          instructions: 'Apply only to darkened areas. Use sunscreen daily.',
        ),
        const Medication(
          name: 'Vitamin C Serum',
          dosage: '2-3 drops',
          frequency: 'Once daily in morning',
          duration: 'Ongoing',
          instructions: 'Apply before moisturizer and sunscreen.',
        ),
      ],
      notes: 'Completed successfully. Significant improvement observed. Continue vitamin C for maintenance.',
      doctor: const Doctor(
        id: 'doc_003',
        name: 'Dr. Sushma Karki',
        specialty: DoctorSpecialty.cosmetologist,
        qualifications: 'MBBS, PG Diploma (Aesthetic Medicine)',
        experience: 8,
        rating: 4.7,
        totalReviews: 98,
        consultationFee: 1200,
        availableDays: [2, 4, 6, 7],
      ),
    ),
    Prescription(
      id: 'presc_003',
      doctorId: 'doc_002',
      userId: 'user_sujana_001',
      diagnosis: 'Eczema (Atopic Dermatitis)',
      prescribedDate: DateTime.now().subtract(const Duration(days: 120)),
      status: PrescriptionStatus.expired,
      medications: [
        const Medication(
          name: 'Hydrocortisone Cream 1%',
          dosage: 'Apply thin layer',
          frequency: 'Twice daily',
          duration: '2 weeks',
          instructions: 'Apply to affected areas only. Do not use on face.',
        ),
        const Medication(
          name: 'Cetaphil Moisturizing Cream',
          dosage: 'Generous amount',
          frequency: 'Multiple times daily',
          duration: 'Ongoing',
          instructions: 'Keep skin well moisturized at all times.',
        ),
      ],
      notes: 'Prescription expired. Please book follow-up if symptoms persist.',
      doctor: const Doctor(
        id: 'doc_002',
        name: 'Dr. Rajesh Thapa',
        specialty: DoctorSpecialty.dermatologist,
        qualifications: 'MBBS, MD (Dermatology), Fellowship (UK)',
        experience: 15,
        rating: 4.9,
        totalReviews: 203,
        consultationFee: 2000,
        availableDays: [1, 3, 5],
      ),
    ),
  ];

  Future<List<Prescription>> getPrescriptions({
    PrescriptionStatus? status,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    var filtered = _prescriptions;

    if (status != null) {
      filtered = filtered.where((p) => p.status == status).toList();
    }

    return filtered..sort((a, b) => b.prescribedDate.compareTo(a.prescribedDate));
  }

  Future<Prescription?> getPrescription(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      return _prescriptions.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<List<Prescription>> getActivePrescriptions() async {
    return getPrescriptions(status: PrescriptionStatus.active);
  }
}
