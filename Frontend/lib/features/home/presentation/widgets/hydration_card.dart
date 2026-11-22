import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/cards/standard_card.dart';

/// Hydration tracking card
class HydrationCard extends StatefulWidget {
  const HydrationCard({super.key});

  @override
  State<HydrationCard> createState() => _HydrationCardState();
}

class _HydrationCardState extends State<HydrationCard> {
  int _waterGlasses = 0;
  final int _goalGlasses = 8;

  void _addWater() {
    if (_waterGlasses < _goalGlasses) {
      setState(() => _waterGlasses++);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final progress = _waterGlasses / _goalGlasses;

    return StandardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.water_drop, color: colorScheme.primary),
              const SizedBox(width: AppSpacing.sm),
              Text('Daily Hydration', style: theme.textTheme.titleMedium),
              const Spacer(),
              Text(
                '$_waterGlasses/$_goalGlasses glasses',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.full),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(colorScheme.primary),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Water Glasses Visualization
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
              _goalGlasses,
              (index) => Icon(
                index < _waterGlasses
                    ? Icons.water_drop
                    : Icons.water_drop_outlined,
                color: index < _waterGlasses
                    ? colorScheme.primary
                    : colorScheme.outlineVariant,
                size: 20,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Add Water Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _waterGlasses < _goalGlasses ? _addWater : null,
              icon: const Icon(Icons.add),
              label: Text(_waterGlasses < _goalGlasses
                  ? 'Log a Glass (250ml)'
                  : 'Goal Reached! 🎉'),
            ),
          ),
        ],
      ),
    );
  }
}
