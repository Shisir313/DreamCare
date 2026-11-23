import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../providers/onboarding_provider.dart';

/// Onboarding complete screen - final step
class OnboardingCompleteScreen extends ConsumerWidget {
  const OnboardingCompleteScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - (AppSpacing.xl * 2),
                ),
                child: IntrinsicHeight(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(),
                      // Success Icon
                      Icon(
                        Icons.check_circle,
                        size: 90,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      // Title
                      Text(
                        'You\'re All Set!',
                        style: theme.textTheme.headlineLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      // Message
                      Text(
                        'Your personalized skincare journey starts now. We\'ve tailored DermaCare to your unique needs.',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const Spacer(),
                      const SizedBox(height: AppSpacing.xl),
                      // Button
                      PrimaryButton(
                        label: 'Start Your Journey',
                        onPressed: () async {
                          await ref
                              .read(onboardingProvider.notifier)
                              .completeOnboarding();
                          if (context.mounted) {
                            context.go('/home');
                          }
                        },
                        isFullWidth: true,
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
