import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../../../../core/widgets/onboarding/onboarding_step_indicator.dart';
import '../../../../core/widgets/onboarding/selection_chip_group.dart';
import '../../domain/models/onboarding_data.dart';
import '../providers/onboarding_provider.dart';

/// Onboarding screen 4: Medical History
class MedicalHistoryScreen extends ConsumerStatefulWidget {
  const MedicalHistoryScreen({super.key});

  @override
  ConsumerState<MedicalHistoryScreen> createState() =>
      _MedicalHistoryScreenState();
}

class _MedicalHistoryScreenState extends ConsumerState<MedicalHistoryScreen> {
  final Set<Allergy> _allergies = {};
  final Set<SkinCondition> _conditions = {};
  final _medicationsController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isPregnant = false;
  bool _isBreastfeeding = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _medicationsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _complete() async {
    setState(() => _isSubmitting = true);

    final medicalHistory = MedicalHistory(
      allergies: _allergies.toList(),
      skinConditions: _conditions.toList(),
      currentMedications: _medicationsController.text.trim().isEmpty
          ? null
          : _medicationsController.text.trim(),
      isPregnant: _isPregnant,
      isBreastfeeding: _isBreastfeeding,
      additionalNotes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    await ref.read(onboardingProvider.notifier).complete(medicalHistory);

    if (!mounted) return;

    // Navigate to completion screen
    context.go('/onboarding/complete');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Medical History')),
      body: Column(
        children: [
          // Progress indicator
          const Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: OnboardingStepIndicator(currentStep: 4, totalSteps: 6),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Info note
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withValues(
                        alpha: 0.3,
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.medium),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.lock_outline,
                          size: 20,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            'Your medical information is confidential and helps us provide better recommendations',
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Allergies
                  Text(
                    'Do you have any allergies? (Optional)',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Select all that apply',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SelectionChipGroup<Allergy>(
                    items: Allergy.values,
                    selectedItems: _allergies.toList(),
                    onSelectionChanged: (selected) {
                      setState(() {
                        _allergies.clear();
                        _allergies.addAll(selected);
                      });
                    },
                    labelBuilder: (allergy) => allergy.displayName,
                    multiSelect: true,
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Skin Conditions
                  Text(
                    'Existing skin conditions? (Optional)',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Select all that apply',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SelectionChipGroup<SkinCondition>(
                    items: SkinCondition.values,
                    selectedItems: _conditions.toList(),
                    onSelectionChanged: (selected) {
                      setState(() {
                        _conditions.clear();
                        _conditions.addAll(selected);
                      });
                    },
                    labelBuilder: (condition) => condition.displayName,
                    multiSelect: true,
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Current Medications
                  Text(
                    'Current Medications (Optional)',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _medicationsController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText:
                          'List any medications you\'re currently taking...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.medium),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Pregnancy/Breastfeeding
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        children: [
                          CheckboxListTile(
                            value: _isPregnant,
                            onChanged: (value) {
                              setState(() => _isPregnant = value ?? false);
                            },
                            title: const Text('I am pregnant'),
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                          ),
                          CheckboxListTile(
                            value: _isBreastfeeding,
                            onChanged: (value) {
                              setState(() => _isBreastfeeding = value ?? false);
                            },
                            title: const Text('I am breastfeeding'),
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Additional Notes
                  Text(
                    'Additional Notes (Optional)',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Any other information you\'d like to share...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.medium),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),

          // Bottom CTA
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: SafeArea(
              child: PrimaryButton(
                label: 'Complete Setup',
                onPressed: _isSubmitting ? null : _complete,
                isLoading: _isSubmitting,
                isFullWidth: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
