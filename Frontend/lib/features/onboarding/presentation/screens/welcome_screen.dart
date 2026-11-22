import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/buttons/primary_button.dart';

/// Welcome screen - first step of onboarding
class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            children: [
              const Spacer(),
              // Official Logo
              Image.asset(
                'assets/images/logo/logo.png',
                height: 140,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: AppSpacing.xxl),
              // Title
              Text('Welcome to DermaCare',
                  style: theme.textTheme.headlineLarge,
                  textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.md),
              // Subtitle
              Text(
                'Your personalized skincare companion. Let\'s learn about your skin to create a routine that works for you.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              // Button
              PrimaryButton(
                label: 'Get Started',
                onPressed: () => context.push('/onboarding/skin-profile'),
                isFullWidth: true,
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}
