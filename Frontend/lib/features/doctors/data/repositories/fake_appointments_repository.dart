import '../../domain/models/appointment.dart';
import 'fake_doctors_repository.dart';

class FakeAppointmentsRepository {
  FakeAppointmentsRepository._();

  static final FakeAppointmentsRepository instance =
      FakeAppointmentsRepository._();
  final FakeDoctorsRepository _doctorsRepository = FakeDoctorsRepository();
  final List<Appointment> _appointments = [
    Appointment(
      id: 'apt_upcoming_001',
      doctorId: 'doc_001',
      userId: 'current_user',
      dateTime: DateTime.now().add(const Duration(days: 2, hours: 3)),
      type: AppointmentType.video,
      status: AppointmentStatus.confirmed,
      fee: 1500,
      symptoms: 'Redness and dryness around cheeks',
      createdAt: DateTime.now(),
    ),
    Appointment(
      id: 'apt_upcoming_002',
      doctorId: 'doc_003',
      userId: 'current_user',
      dateTime: DateTime.now().add(const Duration(days: 9, hours: 1)),
      type: AppointmentType.inPerson,
      status: AppointmentStatus.scheduled,
      fee: 1200,
      symptoms: 'Skin treatment follow-up',
      createdAt: DateTime.now(),
    ),
    Appointment(
      id: 'apt_past_001',
      doctorId: 'doc_002',
      userId: 'current_user',
      dateTime: DateTime.now().subtract(const Duration(days: 18)),
      type: AppointmentType.video,
      status: AppointmentStatus.completed,
      fee: 2000,
      notes: 'Continue gentle moisturizer and sunscreen.',
      createdAt: DateTime.now().subtract(const Duration(days: 25)),
    ),
  ];

  Future<List<Appointment>> getAppointments() async {
    await Future.delayed(const Duration(milliseconds: 350));
    final result = <Appointment>[];
    for (final appointment in _appointments) {
      final doctor = await _doctorsRepository.getDoctor(appointment.doctorId);
      result.add(appointment.copyWith(doctor: doctor));
    }
    return result;
  }

  Future<Appointment?> getAppointment(String id) async {
    await Future.delayed(const Duration(milliseconds: 250));
    try {
      final appointment = _appointments.firstWhere((item) => item.id == id);
      final doctor = await _doctorsRepository.getDoctor(appointment.doctorId);
      return appointment.copyWith(doctor: doctor);
    } catch (_) {
      return null;
    }
  }

  Future<void> cancelAppointment(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _appointments.indexWhere(
      (appointment) => appointment.id == id,
    );
    if (index != -1) {
      _appointments[index] = _appointments[index].copyWith(
        status: AppointmentStatus.cancelled,
      );
    }
  }

  Future<void> rescheduleAppointment(String id, DateTime dateTime) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _appointments.indexWhere(
      (appointment) => appointment.id == id,
    );
    if (index != -1) {
      _appointments[index] = _appointments[index].copyWith(
        dateTime: dateTime,
        status: AppointmentStatus.scheduled,
      );
    }
  }
}
