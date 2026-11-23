import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';

class RoutineScreen extends StatefulWidget {
  const RoutineScreen({super.key});

  @override
  State<RoutineScreen> createState() => _RoutineScreenState();
}

class _RoutineScreenState extends State<RoutineScreen> {
  final List<_RoutineItem> _morning = [
    const _RoutineItem('Cleanser', 'Cleanse face gently', true),
    const _RoutineItem('Toner', 'Apply a hydrating toner', true),
    const _RoutineItem('Moisturizer', 'Apply even moisturizer', false),
    const _RoutineItem('Sunscreen', 'SPF 50, broad spectrum', false),
  ];
  final List<_RoutineItem> _evening = [
    const _RoutineItem('Cleanser', 'Remove sunscreen and makeup', false),
    const _RoutineItem('Treatment', 'Apply prescribed serum', false),
    const _RoutineItem('Night Cream', 'Seal in hydration', false),
  ];

  void _toggle(List<_RoutineItem> items, int index) {
    setState(() {
      final item = items[index];
      items[index] = _RoutineItem(
        item.title,
        item.description,
        !item.completed,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final completed = [
      ..._morning,
      ..._evening,
    ].where((item) => item.completed).length;
    final total = _morning.length + _evening.length;

    return Scaffold(
      appBar: AppBar(title: const Text('My Skincare Routine')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Today\'s Progress', style: theme.textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.sm),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.medium),
                    child: LinearProgressIndicator(
                      value: completed / total,
                      minHeight: 10,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text('$completed of $total steps completed'),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _RoutineSection(
            title: 'Morning',
            icon: Icons.wb_sunny_outlined,
            items: _morning,
            onToggle: (index) => _toggle(_morning, index),
          ),
          const SizedBox(height: AppSpacing.md),
          _RoutineSection(
            title: 'Evening',
            icon: Icons.nightlight_outlined,
            items: _evening,
            onToggle: (index) => _toggle(_evening, index),
          ),
        ],
      ),
    );
  }
}

class _RoutineSection extends StatelessWidget {
  const _RoutineSection({
    required this.title,
    required this.icon,
    required this.items,
    required this.onToggle,
  });

  final String title;
  final IconData icon;
  final List<_RoutineItem> items;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(title, style: theme.textTheme.titleMedium),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          for (var index = 0; index < items.length; index++)
            CheckboxListTile(
              value: items[index].completed,
              onChanged: (_) => onToggle(index),
              title: Text(items[index].title),
              subtitle: Text(items[index].description),
              secondary: const Icon(Icons.shopping_bag_outlined),
            ),
        ],
      ),
    );
  }
}

class _RoutineItem {
  const _RoutineItem(this.title, this.description, this.completed);

  final String title;
  final String description;
  final bool completed;
}
