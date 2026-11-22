import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';

/// Primary action button - uses theme's ElevatedButton style
/// Following Material 3 design with DermaCare branding
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool isLoading;
  final bool isFullWidth;

  @override
  Widget build(BuildContext context) {
    Widget button = icon != null
        ? ElevatedButton.icon(
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
        : ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            child: isLoading
                ? const SizedBox(
                    width: IconSizes.small,
                    height: IconSizes.small,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(label),
          );

    if (isFullWidth) {
      button = SizedBox(width: double.infinity, child: button);
    }

    return button;
  }
}
