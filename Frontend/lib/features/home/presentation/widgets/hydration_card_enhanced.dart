import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../providers/water_tracking_provider.dart';
import 'animated_water_glass.dart';

class HydrationCardEnhanced extends ConsumerWidget {
  const HydrationCardEnhanced({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final waterTrackingAsync = ref.watch(waterTrackingProvider);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: waterTrackingAsync.when(
          data: (tracking) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '💧 Daily Hydration',
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  if (tracking.goalReached)
                    Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            '🎉 Goal Reached!',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                        .animate()
                        .scale(duration: 600.ms, curve: Curves.elasticOut)
                        .shimmer(delay: 600.ms, duration: 1000.ms),
                ],
              ),
              const SizedBox(height: 24),

              Center(
                child: AnimatedWaterGlass(
                  current: tracking.glassesCompleted,
                  total: tracking.dailyGoal,
                  onTap: () {
                    ref.read(waterTrackingProvider.notifier).addGlass();
                  },
                ),
              ),

              const SizedBox(height: 24),

              // Quick stats
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatItem(
                    icon: Icons.water_drop,
                    label: 'Completed',
                    value: '${tracking.glassesCompleted}',
                  ),
                  _StatItem(
                    icon: Icons.flag,
                    label: 'Goal',
                    value: '${tracking.dailyGoal}',
                  ),
                  _StatItem(
                    icon: Icons.trending_up,
                    label: 'Progress',
                    value: '${tracking.percentComplete}%',
                  ),
                ],
              ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),

              const SizedBox(height: 16),

              // Action buttons
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  // Remove glass button (undo)
                  if (tracking.glassesCompleted > 0)
                    TextButton.icon(
                      onPressed: () {
                        ref.read(waterTrackingProvider.notifier).removeGlass();
                      },
                      icon: const Icon(Icons.undo, size: 18),
                      label: const Text('Undo'),
                    ),

                  // Enable/disable reminders
                  TextButton.icon(
                    onPressed: () async {
                      final notifier = ref.read(waterTrackingProvider.notifier);
                      if (notifier.remindersEnabled) {
                        await notifier.disableReminders();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Reminders disabled')),
                          );
                        }
                      } else {
                        await notifier.enableReminders();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Reminders enabled! You\'ll get notifications every 2 hours',
                              ),
                            ),
                          );
                        }
                      }
                    },
                    icon: Icon(
                      ref.watch(waterTrackingProvider.notifier).remindersEnabled
                          ? Icons.notifications_active
                          : Icons.notifications_off,
                      size: 18,
                    ),
                    label: Text(
                      ref.watch(waterTrackingProvider.notifier).remindersEnabled
                          ? 'Reminders On'
                          : 'Enable Reminders',
                    ),
                  ),
                ],
              ),
            ],
          ),
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Error loading water tracking: $error'),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: Colors.grey),
        ),
      ],
    );
  }
}
