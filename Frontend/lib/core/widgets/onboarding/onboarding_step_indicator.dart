import 'package:flutter/material.dart';
import '../../theme/app_spacing.dart';

/// Step indicator for onboarding flow
class OnboardingStepIndicator extends StatelessWidget {
  const OnboardingStepIndicator({
    required this.currentStep,
    required this.totalSteps,
    super.key,
  });

  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        totalSteps,
        (index) => Container(
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          width: currentStep == index ? 32 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: currentStep == index
                ? colorScheme.primary
                : colorScheme.outlineVariant,
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
        ),
      ),
    );
  }
}
