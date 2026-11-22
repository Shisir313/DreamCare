import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';

/// Tertiary action button - uses theme's TextButton style
/// For least prominent actions like "Cancel" or "Skip"
class TertiaryButton extends StatelessWidget {
  const TertiaryButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return icon != null
        ? TextButton.icon(
            onPressed: isLoading ? null : onPressed,
            icon: isLoading
                ? const SizedBox(
                    width: IconSizes.small,
                    height: IconSizes.small,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : icon!,
            label: Text(label),
          )
        : TextButton(
            onPressed: isLoading ? null : onPressed,
            child: isLoading
                ? const SizedBox(
                    width: IconSizes.small,
                    height: IconSizes.small,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(label),
          );
  }
}
