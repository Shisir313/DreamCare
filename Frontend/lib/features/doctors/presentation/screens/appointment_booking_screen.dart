import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../../domain/models/doctor.dart';
import '../../domain/models/appointment.dart';
import '../../data/repositories/fake_doctors_repository.dart';

/// Appointment booking screen with calendar and time slots
class AppointmentBookingScreen extends StatefulWidget {
  const AppointmentBookingScreen({
    required this.doctorId,
    super.key,
  });

  final String doctorId;

  @override
  State<AppointmentBookingScreen> createState() => _AppointmentBookingScreenState();
}

class _AppointmentBookingScreenState extends State<AppointmentBookingScreen> {
  final _repository = FakeDoctorsRepository();
  final _symptomsController = TextEditingController();
  
  Doctor? _doctor;
  DateTime _selectedDate = DateTime.now();
  TimeSlot? _selectedSlot;
  List<TimeSlot> _availableSlots = [];
  AppointmentType _selectedType = AppointmentType.video;
  bool _isLoading = true;
  bool _isBooking = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _symptomsController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final doctor = await _repository.getDoctor(widget.doctorId);
    final slots = await _repository.getAvailableSlots(widget.doctorId, _selectedDate);

    setState(() {
      _doctor = doctor;
      _availableSlots = slots;
      _isLoading = false;
    });
  }

  Future<void> _loadSlots(DateTime date) async {
    final slots = await _repository.getAvailableSlots(widget.doctorId, date);
    setState(() {
      _selectedDate = date;
      _availableSlots = slots;
      _selectedSlot = null;
    });
  }

  Future<void> _bookAppointment() async {
    if (_selectedSlot == null) return;

    setState(() => _isBooking = true);

    try {
      final appointment = await _repository.bookAppointment(
        doctorId: widget.doctorId,
        dateTime: _selectedSlot!.startTime,
        type: _selectedType,
        symptoms: _symptomsController.text.isEmpty ? null : _symptomsController.text,
      );

      if (!mounted) return;

      // Navigate to confirmation
      context.go('/appointments/${appointment.id}/confirmed', extra: appointment);
    } finally {
      if (mounted) {
        setState(() => _isBooking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isLoading || _doctor == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Book Appointment')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final doctor = _doctor!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Appointment'),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Doctor info
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: colorScheme.primaryContainer,
                            child: Text(
                              doctor.name.substring(4, 6).toUpperCase(),
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: colorScheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  doctor.name,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  doctor.specialty.displayName,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            doctor.feeText,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Appointment Type
                  Text(
                    'Appointment Type',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: _AppointmentTypeCard(
                          type: AppointmentType.video,
                          isSelected: _selectedType == AppointmentType.video,
                          onTap: () => setState(() => _selectedType = AppointmentType.video),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _AppointmentTypeCard(
                          type: AppointmentType.inPerson,
                          isSelected: _selectedType == AppointmentType.inPerson,
                          onTap: () => setState(() => _selectedType = AppointmentType.inPerson),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Date Selection
                  Text(
                    'Select Date',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    height: 80,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: 7,
                      separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        final date = DateTime.now().add(Duration(days: index));
                        final isSelected = _selectedDate.year == date.year &&
                            _selectedDate.month == date.month &&
                            _selectedDate.day == date.day;

                        return _DateCard(
                          date: date,
                          isSelected: isSelected,
                          onTap: () => _loadSlots(date),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Time Slots
                  Text(
                    'Available Time Slots',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (_availableSlots.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Text(
                        'No available slots for this date',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: _availableSlots.map((slot) {
                        return _TimeSlotChip(
                          slot: slot,
                          isSelected: _selectedSlot == slot,
                          onTap: slot.isAvailable
                              ? () => setState(() => _selectedSlot = slot)
                              : null,
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: AppSpacing.lg),

                  // Symptoms/Notes
                  Text(
                    'Reason for Visit (Optional)',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _symptomsController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Describe your symptoms or concerns...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.medium),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom CTA
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_selectedSlot != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total:',
                          style: theme.textTheme.titleMedium,
                        ),
                        Text(
                          doctor.feeText,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  PrimaryButton(
                    label: 'Confirm Booking',
                    onPressed: _selectedSlot == null || _isBooking ? null : _bookAppointment,
                    isLoading: _isBooking,
                    isFullWidth: true,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Appointment type card
class _AppointmentTypeCard extends StatelessWidget {
  const _AppointmentTypeCard({
    required this.type,
    required this.isSelected,
    required this.onTap,
  });

  final AppointmentType type;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primaryContainer : colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.medium),
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.outline,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              type == AppointmentType.video ? Icons.videocam : Icons.location_on,
              color: isSelected ? colorScheme.primary : colorScheme.onSurface,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              type.displayName.split(' ').first,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Date selection card
class _DateCard extends StatelessWidget {
  const _DateCard({
    required this.date,
    required this.isSelected,
    required this.onTap,
  });

  final DateTime date;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final dayName = dayNames[(date.weekday - 1) % 7];

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 60,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.medium),
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.outline,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              dayName,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${date.day}',
              style: theme.textTheme.titleLarge?.copyWith(
                color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Time slot chip
class _TimeSlotChip extends StatelessWidget {
  const _TimeSlotChip({
    required this.slot,
    required this.isSelected,
    required this.onTap,
  });

  final TimeSlot slot;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: !slot.isAvailable
              ? colorScheme.surfaceContainerHighest
              : isSelected
                  ? colorScheme.primary
                  : colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.medium),
          border: Border.all(
            color: !slot.isAvailable
                ? colorScheme.outline.withValues(alpha: 0.3)
                : isSelected
                    ? colorScheme.primary
                    : colorScheme.outline,
          ),
        ),
        child: Text(
          slot.timeRange.split(' - ').first,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: !slot.isAvailable
                ? colorScheme.onSurfaceVariant
                : isSelected
                    ? colorScheme.onPrimary
                    : colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            decoration: !slot.isAvailable ? TextDecoration.lineThrough : null,
          ),
        ),
      ),
    );
  }
}
