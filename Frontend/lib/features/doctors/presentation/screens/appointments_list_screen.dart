import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../data/repositories/fake_appointments_repository.dart';
import '../../domain/models/appointment.dart';

class AppointmentsListScreen extends StatefulWidget {
  const AppointmentsListScreen({super.key});

  @override
  State<AppointmentsListScreen> createState() => _AppointmentsListScreenState();
}

class _AppointmentsListScreenState extends State<AppointmentsListScreen>
    with SingleTickerProviderStateMixin {
  final _repository = FakeAppointmentsRepository.instance;
  late final TabController _tabController;
  List<Appointment> _appointments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final appointments = await _repository.getAppointments();
    if (!mounted) return;
    setState(() {
      _appointments = appointments;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final upcoming = _appointments
        .where(
          (appointment) =>
              appointment.status != AppointmentStatus.completed &&
              appointment.status != AppointmentStatus.cancelled &&
              !appointment.isPast,
        )
        .toList();
    final past = _appointments
        .where(
          (appointment) =>
              appointment.status == AppointmentStatus.completed ||
              appointment.status == AppointmentStatus.cancelled ||
              appointment.isPast,
        )
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Appointments'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Past'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                RefreshIndicator(
                  onRefresh: _load,
                  child: _AppointmentList(
                    appointments: upcoming,
                    emptyMessage: 'No upcoming appointments',
                  ),
                ),
                RefreshIndicator(
                  onRefresh: _load,
                  child: _AppointmentList(
                    appointments: past,
                    emptyMessage: 'No past appointments',
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/doctors'),
        icon: const Icon(Icons.add),
        label: const Text('Book Appointment'),
      ),
    );
  }
}

class _AppointmentList extends StatelessWidget {
  const _AppointmentList({
    required this.appointments,
    required this.emptyMessage,
  });

  final List<Appointment> appointments;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (appointments.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 160),
          Icon(
            Icons.event_available,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(emptyMessage, textAlign: TextAlign.center),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: appointments.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        final appointment = appointments[index];
        final doctor = appointment.doctor;
        return Card(
          child: ListTile(
            contentPadding: const EdgeInsets.all(AppSpacing.md),
            leading: CircleAvatar(
              child: Text(
                doctor?.name.replaceAll('Dr. ', '').substring(0, 1) ?? '?',
              ),
            ),
            title: Text(doctor?.name ?? 'Unknown Doctor'),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                '${appointment.dateText} at ${appointment.timeText}\n'
                '${appointment.type.displayName} • ${appointment.status.displayName}',
              ),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(
              '/appointments/${appointment.id}',
              extra: appointment,
            ),
          ),
        );
      },
    );
  }
}
