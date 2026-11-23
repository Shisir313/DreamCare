import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/cards/standard_card.dart';
import '../../data/repositories/fake_appointments_repository.dart';
import '../../domain/models/appointment.dart';

class AppointmentDetailScreen extends StatefulWidget {
  const AppointmentDetailScreen({
    required this.appointmentId,
    this.appointment,
    super.key,
  });

  final String appointmentId;
  final Appointment? appointment;

  @override
  State<AppointmentDetailScreen> createState() =>
      _AppointmentDetailScreenState();
}

class _AppointmentDetailScreenState extends State<AppointmentDetailScreen> {
  final _repository = FakeAppointmentsRepository.instance;
  Appointment? _appointment;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final appointment =
        widget.appointment ??
        await _repository.getAppointment(widget.appointmentId);
    if (!mounted) return;
    setState(() {
      _appointment = appointment;
      _isLoading = false;
    });
  }

  Future<void> _cancel() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel appointment?'),
        content: const Text('This appointment slot will be released.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep Appointment'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Cancel Appointment'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await _repository.cancelAppointment(widget.appointmentId);
    await _load();
  }

  Future<void> _reschedule() async {
    final initial =
        _appointment?.dateTime ?? DateTime.now().add(const Duration(days: 1));
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 180)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return;
    await _repository.rescheduleAppointment(
      widget.appointmentId,
      DateTime(date.year, date.month, date.day, time.hour, time.minute),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Appointment')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _appointment == null
          ? const Center(child: Text('Appointment not found'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  StandardCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _appointment!.doctor?.name ?? 'Unknown Doctor',
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          _appointment!.doctor?.specialty.displayName ?? '',
                          style: theme.textTheme.bodyMedium,
                        ),
                        const Divider(height: AppSpacing.lg),
                        _DetailRow(
                          icon: Icons.calendar_today,
                          label: _appointment!.dateText,
                        ),
                        _DetailRow(
                          icon: Icons.access_time,
                          label: _appointment!.timeText,
                        ),
                        _DetailRow(
                          icon: _appointment!.type == AppointmentType.video
                              ? Icons.videocam
                              : Icons.location_on,
                          label: _appointment!.type.displayName,
                        ),
                        _DetailRow(
                          icon: Icons.info_outline,
                          label: _appointment!.status.displayName,
                        ),
                      ],
                    ),
                  ),
                  if (_appointment!.symptoms != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    StandardCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Symptoms', style: theme.textTheme.titleMedium),
                          const SizedBox(height: AppSpacing.sm),
                          Text(_appointment!.symptoms!),
                        ],
                      ),
                    ),
                  ],
                  if (_appointment!.notes != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    StandardCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Doctor Notes',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(_appointment!.notes!),
                        ],
                      ),
                    ),
                  ],
                  if (!_appointment!.isPast &&
                      _appointment!.status != AppointmentStatus.cancelled) ...[
                    const SizedBox(height: AppSpacing.xl),
                    OutlinedButton(
                      onPressed: _reschedule,
                      child: const Text('Reschedule'),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.colorScheme.error,
                      ),
                      onPressed: _cancel,
                      child: const Text('Cancel Appointment'),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(label)),
        ],
      ),
    );
  }
}
