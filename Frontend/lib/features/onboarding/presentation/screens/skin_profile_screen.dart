import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../../../../core/widgets/onboarding/onboarding_step_indicator.dart';
import '../../../../core/widgets/onboarding/selection_chip_group.dart';
import '../../domain/models/skin_profile.dart';
import '../providers/onboarding_provider.dart';

/// Onboarding screen 1: Skin Profile
class SkinProfileScreen extends ConsumerStatefulWidget {
  const SkinProfileScreen({super.key});

  @override
  ConsumerState<SkinProfileScreen> createState() => _SkinProfileScreenState();
}

class _SkinProfileScreenState extends ConsumerState<SkinProfileScreen> {
  SkinType? _selectedSkinType;
  final Set<SkinConcern> _selectedConcerns = {};
  final Set<SkinGoal> _selectedGoals = {};

  bool get _canContinue =>
      _selectedSkinType != null &&
      _selectedConcerns.isNotEmpty &&
      _selectedGoals.isNotEmpty;

  void _continue() {
    if (!_canContinue) return;

    final skinProfile = SkinProfile(
      skinType: _selectedSkinType!,
      concerns: _selectedConcerns.toList(),
      goals: _selectedGoals.toList(),
    );

    ref.read(onboardingProvider.notifier).updateSkinProfile(skinProfile);
    context.push('/onboarding/lifestyle');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Your Skin Profile')),
      body: Column(
        children: [
          // Progress indicator
          const Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: OnboardingStepIndicator(currentStep: 1, totalSteps: 6),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Skin Type
                  Text(
                    'What is your skin type?',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Select the one that best describes your skin',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SelectionChipGroup<SkinType>(
                    items: SkinType.values,
                    selectedItems: _selectedSkinType != null
                        ? [_selectedSkinType!]
                        : [],
                    onSelectionChanged: (selected) {
                      setState(() {
                        _selectedSkinType = selected.isEmpty
                            ? null
                            : selected.first;
                      });
                    },
                    labelBuilder: (type) => type.label,
                    multiSelect: false,
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Skin Concerns
                  Text(
                    'What are your main skin concerns?',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Select all that apply',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SelectionChipGroup<SkinConcern>(
                    items: SkinConcern.values,
                    selectedItems: _selectedConcerns.toList(),
                    onSelectionChanged: (selected) {
                      setState(() {
                        _selectedConcerns.clear();
                        _selectedConcerns.addAll(selected);
                      });
                    },
                    labelBuilder: (concern) => concern.label,
                    multiSelect: true,
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Skin Goals
                  Text(
                    'What are your skincare goals?',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Select all that apply',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SelectionChipGroup<SkinGoal>(
                    items: SkinGoal.values,
                    selectedItems: _selectedGoals.toList(),
                    onSelectionChanged: (selected) {
                      setState(() {
                        _selectedGoals.clear();
                        _selectedGoals.addAll(selected);
                      });
                    },
                    labelBuilder: (goal) => goal.label,
                    multiSelect: true,
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
                label: 'Continue',
                onPressed: _canContinue ? _continue : null,
                isFullWidth: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
