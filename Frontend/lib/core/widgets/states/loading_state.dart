import 'package:flutter/material.dart';
import '../../theme/app_spacing.dart';

/// Loading state widget - shows centered circular progress indicator
/// with optional message
class LoadingState extends StatelessWidget {
  const LoadingState({
    this.message,
    super.key,
  });

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              message!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// Loading skeleton for shimmer effect
/// Used to show placeholder while content is loading
class LoadingSkeleton extends StatelessWidget {
  const LoadingSkeleton({
    this.width,
    this.height = 16,
    this.borderRadius,
    super.key,
  });

  final double? width;
  final double height;
  final double? borderRadius;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(
          borderRadius ?? AppRadius.small,
        ),
      ),
    );
  }
}
