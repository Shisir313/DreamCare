import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../../../../core/widgets/onboarding/onboarding_step_indicator.dart';
import '../../../../core/widgets/onboarding/selection_chip_group.dart';
import '../../domain/models/lifestyle_profile.dart';
import '../providers/onboarding_provider.dart';

/// Onboarding screen 2: Lifestyle
class LifestyleScreen extends ConsumerStatefulWidget {
  const LifestyleScreen({super.key});

  @override
  ConsumerState<LifestyleScreen> createState() => _LifestyleScreenState();
}

class _LifestyleScreenState extends ConsumerState<LifestyleScreen> {
  int _sleepHours = 7;
  ActivityLevel? _activityLevel;
  StressLevel? _stressLevel;

  bool get _canContinue => _activityLevel != null && _stressLevel != null;

  void _continue() {
    if (!_canContinue) return;

    final lifestyleProfile = LifestyleProfile(
      sleepHours: _sleepHours,
      activityLevel: _activityLevel!,
      stressLevel: _stressLevel!,
    );

    ref
        .read(onboardingProvider.notifier)
        .updateLifestyleProfile(lifestyleProfile);
    context.push('/onboarding/hydration');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Your Lifestyle')),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: OnboardingStepIndicator(currentStep: 2, totalSteps: 6),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'How many hours do you sleep per night?',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: _sleepHours > 4
                            ? () => setState(() => _sleepHours--)
                            : null,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Text(
                        '$_sleepHours hours',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: _sleepHours < 12
                            ? () => setState(() => _sleepHours++)
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    'What is your activity level?',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SelectionChipGroup<ActivityLevel>(
                    items: ActivityLevel.values,
                    selectedItems: _activityLevel != null
                        ? [_activityLevel!]
                        : [],
                    onSelectionChanged: (selected) => setState(
                      () => _activityLevel = selected.isEmpty
                          ? null
                          : selected.first,
                    ),
                    labelBuilder: (level) => level.label,
                    multiSelect: false,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    'What is your typical stress level?',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SelectionChipGroup<StressLevel>(
                    items: StressLevel.values,
                    selectedItems: _stressLevel != null ? [_stressLevel!] : [],
                    onSelectionChanged: (selected) => setState(
                      () => _stressLevel = selected.isEmpty
                          ? null
                          : selected.first,
                    ),
                    labelBuilder: (stress) => stress.label,
                    multiSelect: false,
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
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
