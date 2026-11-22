import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/models/prescription.dart';
import '../../data/repositories/fake_prescriptions_repository.dart';

/// Prescriptions list screen
class PrescriptionsListScreen extends StatefulWidget {
  const PrescriptionsListScreen({super.key});

  @override
  State<PrescriptionsListScreen> createState() => _PrescriptionsListScreenState();
}

class _PrescriptionsListScreenState extends State<PrescriptionsListScreen> {
  final _repository = FakePrescriptionsRepository();
  List<Prescription>? _prescriptions;
  PrescriptionStatus? _selectedStatus;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPrescriptions();
  }

  Future<void> _loadPrescriptions() async {
    setState(() => _isLoading = true);
    final prescriptions = await _repository.getPrescriptions(status: _selectedStatus);
    setState(() {
      _prescriptions = prescriptions;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Prescriptions'),
      ),
      body: Column(
        children: [
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: _selectedStatus == null,
                  onSelected: (_) {
                    setState(() => _selectedStatus = null);
                    _loadPrescriptions();
                  },
                ),
                const SizedBox(width: AppSpacing.sm),
                ...PrescriptionStatus.values.map((status) {
                  return Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: FilterChip(
                      label: Text(status.displayName),
                      selected: _selectedStatus == status,
                      onSelected: (_) {
                        setState(() => _selectedStatus = status);
                        _loadPrescriptions();
                      },
                    ),
                  );
                }),
              ],
            ),
          ),

          // List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _prescriptions == null || _prescriptions!.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.medical_information_outlined, size: 64, color: colorScheme.onSurfaceVariant),
                            const SizedBox(height: AppSpacing.md),
                            Text('No prescriptions found', style: theme.textTheme.titleMedium),
                            Text(
                              'Your prescriptions will appear here',
                              style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadPrescriptions,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          itemCount: _prescriptions!.length,
                          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
                          itemBuilder: (context, index) {
                            final prescription = _prescriptions![index];
                            return _PrescriptionCard(
                              prescription: prescription,
                              onTap: () => context.push('/prescriptions/${prescription.id}'),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _PrescriptionCard extends StatelessWidget {
  const _PrescriptionCard({
    required this.prescription,
    required this.onTap,
  });

  final Prescription prescription;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Color statusColor;
    switch (prescription.status) {
      case PrescriptionStatus.active:
        statusColor = Colors.green;
        break;
      case PrescriptionStatus.completed:
        statusColor = Colors.blue;
        break;
      case PrescriptionStatus.expired:
        statusColor = Colors.orange;
        break;
      case PrescriptionStatus.cancelled:
        statusColor = Colors.red;
        break;
    }

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      prescription.diagnosis,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppRadius.small),
                    ),
                    child: Text(
                      prescription.status.displayName,
                      style: theme.textTheme.labelSmall?.copyWith(color: statusColor, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Icon(Icons.person_outline, size: 16, color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      prescription.doctor?.name ?? 'Unknown Doctor',
                      style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'Prescribed ${prescription.dateText}',
                    style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: prescription.medications.map((med) {
                  return Chip(
                    label: Text(med.name, style: theme.textTheme.bodySmall),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                }).toList(),
              ),
              if (prescription.hasFollowUp) ...[
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(AppRadius.small),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.event, size: 16, color: colorScheme.primary),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Follow-up: ${prescription.followUpDate!.day}/${prescription.followUpDate!.month}/${prescription.followUpDate!.year}',
                        style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.primary),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
