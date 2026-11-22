import 'package:flutter/material.dart';
import '../../theme/app_spacing.dart';

/// Multi-select chip group for onboarding
class SelectionChipGroup<T> extends StatelessWidget {
  const SelectionChipGroup({
    required this.items,
    required this.selectedItems,
    required this.onSelectionChanged,
    required this.labelBuilder,
    this.multiSelect = true,
    super.key,
  });

  final List<T> items;
  final List<T> selectedItems;
  final void Function(List<T>) onSelectionChanged;
  final String Function(T) labelBuilder;
  final bool multiSelect;

  void _onChipTap(T item) {
    final newSelection = List<T>.from(selectedItems);

    if (multiSelect) {
      // Multi-select: toggle selection
      if (newSelection.contains(item)) {
        newSelection.remove(item);
      } else {
        newSelection.add(item);
      }
    } else {
      // Single-select: replace selection
      newSelection.clear();
      newSelection.add(item);
    }

    onSelectionChanged(newSelection);
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: items.map((item) {
        final isSelected = selectedItems.contains(item);

        return FilterChip(
          label: Text(labelBuilder(item)),
          selected: isSelected,
          onSelected: (_) => _onChipTap(item),
          showCheckmark: multiSelect,
        );
      }).toList(),
    );
  }
}
