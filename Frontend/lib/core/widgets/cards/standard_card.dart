import 'package:flutter/material.dart';
import '../../theme/app_spacing.dart';

/// Standard card widget with consistent styling
/// Used throughout the app for content grouping
class StandardCard extends StatelessWidget {
  const StandardCard({
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final card = Card(
      margin: margin,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(AppSpacing.md),
          child: child,
        ),
      ),
    );

    return card;
  }
}
