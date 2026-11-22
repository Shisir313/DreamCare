import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../../../../core/widgets/onboarding/onboarding_step_indicator.dart';
import '../../domain/models/hydration_profile.dart';
import '../providers/onboarding_provider.dart';

/// Onboarding screen 3: Hydration Goals
class HydrationScreen extends ConsumerStatefulWidget {
  const HydrationScreen({super.key});

  @override
  ConsumerState<HydrationScreen> createState() => _HydrationScreenState();
}

class _HydrationScreenState extends ConsumerState<HydrationScreen> {
  int _dailyGoal = 8; // Default 8 glasses
  bool _enableReminders = true;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 9, minute: 0);

  void _continue() {
    final hydrationProfile = HydrationProfile(
      weightKg: 60.0, // Default weight, user can change in profile later
      dailyGoalML: _dailyGoal * 250, // Convert glasses to ML
    );

    ref
        .read(onboardingProvider.notifier)
        .updateHydrationProfile(hydrationProfile);
    context.push('/onboarding/medical-history');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Hydration Goals')),
      body: Column(
        children: [
          // Progress indicator
          const Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: OnboardingStepIndicator(currentStep: 3, totalSteps: 6),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Icon(Icons.water_drop, size: 80, color: colorScheme.primary),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Stay Hydrated for Healthy Skin',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Proper hydration is essential for maintaining healthy, glowing skin',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  // Daily Goal
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Daily Water Goal',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: _dailyGoal > 4
                                    ? () => setState(() => _dailyGoal--)
                                    : null,
                                iconSize: 36,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: AppSpacing.lg),
                              Column(
                                children: [
                                  Text(
                                    '$_dailyGoal',
                                    style: theme.textTheme.displayLarge
                                        ?.copyWith(
                                          color: colorScheme.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  Text(
                                    'glasses per day',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  Text(
                                    '(${(_dailyGoal * 0.25).toStringAsFixed(1)} L)',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: AppSpacing.lg),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                onPressed: _dailyGoal < 16
                                    ? () => setState(() => _dailyGoal++)
                                    : null,
                                iconSize: 36,
                                color: colorScheme.primary,
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Slider(
                            value: _dailyGoal.toDouble(),
                            min: 4,
                            max: 16,
                            divisions: 12,
                            onChanged: (value) {
                              setState(() => _dailyGoal = value.round());
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Reminders
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Enable Reminders',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Switch(
                                value: _enableReminders,
                                onChanged: (value) {
                                  setState(() => _enableReminders = value);
                                },
                              ),
                            ],
                          ),
                          if (_enableReminders) ...[
                            const SizedBox(height: AppSpacing.md),
                            const Divider(),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'First Reminder Time',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            OutlinedButton.icon(
                              icon: const Icon(Icons.access_time),
                              label: Text(
                                _reminderTime.format(context),
                                style: theme.textTheme.titleMedium,
                              ),
                              onPressed: () async {
                                final time = await showTimePicker(
                                  context: context,
                                  initialTime: _reminderTime,
                                );
                                if (time != null) {
                                  setState(() => _reminderTime = time);
                                }
                              },
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'We\'ll remind you every 2 hours during the day',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Info box
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
                          Icons.lightbulb_outline,
                          size: 20,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            'Tip: Drinking 8 glasses (2L) of water daily helps maintain skin elasticity and flush out toxins',
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
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
                onPressed: _continue,
                isFullWidth: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
