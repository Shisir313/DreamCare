import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/cards/standard_card.dart';

/// Daily routine card
class RoutineCard extends StatelessWidget {
  const RoutineCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return StandardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.wb_sunny_outlined, color: colorScheme.secondary),
              const SizedBox(width: AppSpacing.sm),
              Text('Today\'s Routine', style: theme.textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Morning Routine
          const _RoutineItem(
            time: 'Morning',
            icon: Icons.wb_sunny,
            steps: ['Cleanser', 'Toner', 'Moisturizer', 'Sunscreen'],
            completed: 2,
          ),
          const Divider(height: AppSpacing.lg),
          // Evening Routine
          const _RoutineItem(
            time: 'Evening',
            icon: Icons.nightlight_outlined,
            steps: ['Cleanser', 'Serum', 'Night Cream'],
            completed: 0,
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Full routine page coming soon'),
                  ),
                );
              },
              child: const Text('View Full Routine'),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoutineItem extends StatelessWidget {
  const _RoutineItem({
    required this.time,
    required this.icon,
    required this.steps,
    required this.completed,
  });

  final String time;
  final IconData icon;
  final List<String> steps;
  final int completed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: AppSpacing.xs),
            Text(
              time,
              style: theme.textTheme.titleSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            Text(
              '$completed/${steps.length} done',
              style: theme.textTheme.bodySmall?.copyWith(
                color: completed == steps.length
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: steps.asMap().entries.map((entry) {
            final index = entry.key;
            final step = entry.value;
            final isDone = index < completed;

            return Chip(
              label: Text(step),
              avatar: Icon(
                isDone ? Icons.check_circle : Icons.circle_outlined,
                size: 16,
              ),
              visualDensity: VisualDensity.compact,
              backgroundColor: isDone
                  ? colorScheme.primaryContainer
                  : colorScheme.surfaceContainerHighest,
              labelStyle: theme.textTheme.bodySmall?.copyWith(
                color: isDone
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurfaceVariant,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
