import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Animated button with scale and haptic feedback
class AnimatedButton extends StatefulWidget {
  const AnimatedButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation = 2,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    this.borderRadius = 12,
    this.enableHaptic = true,
    this.scaleDown = 0.95,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double elevation;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final bool enableHaptic;
  final double scaleDown;

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scaleDown,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed != null) {
      _controller.forward();
      if (widget.enableHaptic) {
        HapticFeedback.lightImpact();
      }
    }
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDisabled = widget.onPressed == null;

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.onPressed,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: widget.padding,
          decoration: BoxDecoration(
            color: isDisabled
                ? theme.colorScheme.surfaceContainerHighest
                : (widget.backgroundColor ?? theme.colorScheme.primary),
            borderRadius: BorderRadius.circular(widget.borderRadius),
            boxShadow: isDisabled
                ? null
                : [
                    BoxShadow(
                      color: (widget.backgroundColor ??
                              theme.colorScheme.primary)
                          .withValues(alpha: 0.3),
                      blurRadius: widget.elevation * 4,
                      offset: Offset(0, widget.elevation),
                    ),
                  ],
          ),
          child: DefaultTextStyle(
            style: theme.textTheme.labelLarge!.copyWith(
              color: isDisabled
                  ? theme.colorScheme.onSurfaceVariant
                  : (widget.foregroundColor ?? theme.colorScheme.onPrimary),
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// Animated outlined button variant
class AnimatedOutlinedButton extends StatefulWidget {
  const AnimatedOutlinedButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.borderColor,
    this.foregroundColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    this.borderRadius = 12,
    this.borderWidth = 2,
    this.enableHaptic = true,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final Color? borderColor;
  final Color? foregroundColor;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final double borderWidth;
  final bool enableHaptic;

  @override
  State<AnimatedOutlinedButton> createState() =>
      _AnimatedOutlinedButtonState();
}

class _AnimatedOutlinedButtonState extends State<AnimatedOutlinedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed != null) {
      _controller.forward();
      if (widget.enableHaptic) {
        HapticFeedback.lightImpact();
      }
    }
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDisabled = widget.onPressed == null;

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.onPressed,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: widget.padding,
          decoration: BoxDecoration(
            border: Border.all(
              color: isDisabled
                  ? theme.colorScheme.outline.withValues(alpha: 0.5)
                  : (widget.borderColor ?? theme.colorScheme.primary),
              width: widget.borderWidth,
            ),
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
          child: DefaultTextStyle(
            style: theme.textTheme.labelLarge!.copyWith(
              color: isDisabled
                  ? theme.colorScheme.onSurfaceVariant
                  : (widget.foregroundColor ?? theme.colorScheme.primary),
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// Animated icon button
class AnimatedIconButton extends StatefulWidget {
  const AnimatedIconButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.size = 48,
    this.iconSize = 24,
    this.backgroundColor,
    this.iconColor,
    this.enableHaptic = true,
  });

  final VoidCallback? onPressed;
  final IconData icon;
  final double size;
  final double iconSize;
  final Color? backgroundColor;
  final Color? iconColor;
  final bool enableHaptic;

  @override
  State<AnimatedIconButton> createState() => _AnimatedIconButtonState();
}

class _AnimatedIconButtonState extends State<AnimatedIconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _rotationAnimation = Tween<double>(begin: 0.0, end: 0.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed != null) {
      _controller.forward();
      if (widget.enableHaptic) {
        HapticFeedback.mediumImpact();
      }
    }
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDisabled = widget.onPressed == null;

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.onPressed,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: RotationTransition(
          turns: _rotationAnimation,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: isDisabled
                  ? theme.colorScheme.surfaceContainerHighest
                  : (widget.backgroundColor ??
                      theme.colorScheme.primaryContainer),
              shape: BoxShape.circle,
              boxShadow: isDisabled
                  ? null
                  : [
                      BoxShadow(
                        color: (widget.backgroundColor ??
                                theme.colorScheme.primary)
                            .withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Icon(
              widget.icon,
              size: widget.iconSize,
              color: isDisabled
                  ? theme.colorScheme.onSurfaceVariant
                  : (widget.iconColor ?? theme.colorScheme.primary),
            ),
          ),
        ),
      ),
    );
  }
}
