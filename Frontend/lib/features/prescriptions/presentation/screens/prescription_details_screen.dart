import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/models/prescription.dart';
import '../../data/repositories/fake_prescriptions_repository.dart';

class PrescriptionDetailsScreen extends StatefulWidget {
  const PrescriptionDetailsScreen({required this.prescriptionId, super.key});

  final String prescriptionId;

  @override
  State<PrescriptionDetailsScreen> createState() => _PrescriptionDetailsScreenState();
}

class _PrescriptionDetailsScreenState extends State<PrescriptionDetailsScreen> {
  final _repository = FakePrescriptionsRepository();
  Prescription? _prescription;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPrescription();
  }

  Future<void> _loadPrescription() async {
    final prescription = await _repository.getPrescription(widget.prescriptionId);
    setState(() {
      _prescription = prescription;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator()));
    }

    if (_prescription == null) {
      return Scaffold(appBar: AppBar(), body: const Center(child: Text('Prescription not found')));
    }

    final prescription = _prescription!;

    return Scaffold(
      appBar: AppBar(title: const Text('Prescription Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Diagnosis', style: theme.textTheme.labelMedium),
                    const SizedBox(height: AppSpacing.xs),
                    Text(prescription.diagnosis, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const Divider(height: AppSpacing.lg),
                    Text('Prescribed by', style: theme.textTheme.labelMedium),
                    const SizedBox(height: AppSpacing.xs),
                    Text(prescription.doctor?.name ?? 'Unknown', style: theme.textTheme.bodyLarge),
                    Text(prescription.dateText, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Medications', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSpacing.sm),
            ...prescription.medications.map((med) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(med.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: AppSpacing.sm),
                        _InfoRow(label: 'Dosage', value: med.dosage),
                        _InfoRow(label: 'Frequency', value: med.frequency),
                        _InfoRow(label: 'Duration', value: med.duration),
                        if (med.instructions != null) ...[
                          const Divider(height: AppSpacing.md),
                          Text('Instructions:', style: theme.textTheme.labelSmall),
                          const SizedBox(height: AppSpacing.xs),
                          Text(med.instructions!, style: theme.textTheme.bodySmall),
                        ],
                      ],
                    ),
                  ),
                )),
            if (prescription.notes != null) ...[
              const SizedBox(height: AppSpacing.md),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Notes', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: AppSpacing.sm),
                      Text(prescription.notes!, style: theme.textTheme.bodyMedium),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 80, child: Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant))),
          Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
