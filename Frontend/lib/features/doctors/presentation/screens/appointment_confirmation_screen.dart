import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../../domain/models/appointment.dart';

/// Appointment confirmation screen
class AppointmentConfirmationScreen extends StatelessWidget {
  const AppointmentConfirmationScreen({
    required this.appointment,
    super.key,
  });

  final Appointment appointment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Success Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  size: 80,
                  color: Colors.green[600],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Success Message
              Text(
                'Appointment Confirmed!',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Your appointment has been successfully booked',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),

              // Appointment Details
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppRadius.large),
                ),
                child: Column(
                  children: [
                    _DetailRow(
                      icon: Icons.person,
                      label: 'Doctor',
                      value: appointment.doctor?.name ?? 'Unknown',
                    ),
                    const Divider(height: AppSpacing.lg),
                    _DetailRow(
                      icon: Icons.calendar_today,
                      label: 'Date',
                      value: appointment.dateText,
                    ),
                    const Divider(height: AppSpacing.lg),
                    _DetailRow(
                      icon: Icons.access_time,
                      label: 'Time',
                      value: appointment.timeText,
                    ),
                    const Divider(height: AppSpacing.lg),
                    _DetailRow(
                      icon: appointment.type == AppointmentType.video
                          ? Icons.videocam
                          : Icons.location_on,
                      label: 'Type',
                      value: appointment.type.displayName,
                    ),
                    const Divider(height: AppSpacing.lg),
                    _DetailRow(
                      icon: Icons.payment,
                      label: 'Fee',
                      value: appointment.feeText,
                    ),
                    if (appointment.type == AppointmentType.video &&
                        appointment.meetingLink != null) ...[
                      const Divider(height: AppSpacing.lg),
                      _DetailRow(
                        icon: Icons.link,
                        label: 'Meeting Link',
                        value: 'Sent to your email',
                        valueColor: colorScheme.primary,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Info note
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 20,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'A confirmation email has been sent to you',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),

              // Action Buttons
              PrimaryButton(
                label: 'Go to Home',
                onPressed: () => context.go('/home'),
                isFullWidth: true,
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton(
                onPressed: () {
                  // TODO: Navigate to appointments list
                  context.go('/home');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Appointments list coming soon'),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: const Text('View My Appointments'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: colorScheme.primary,
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: valueColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
