import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';

/// Quick action buttons on home screen with animations
class QuickActions extends StatelessWidget {
  const QuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final actions = [
      _QuickActionData(
        icon: Icons.medical_services_outlined,
        label: 'Find Doctor',
        color: colorScheme.primary,
        onTap: () => context.push('/doctors'),
      ),
      _QuickActionData(
        icon: Icons.camera_alt_outlined,
        label: 'Scan Product',
        color: colorScheme.secondary,
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product scanner coming soon')),
          );
        },
      ),
      _QuickActionData(
        icon: Icons.favorite_outline,
        label: 'Track Skin',
        color: colorScheme.tertiary,
        onTap: () => context.push('/progress/logs'),
      ),
    ];

    return Row(
      children: actions.asMap().entries.map((entry) {
        final index = entry.key;
        final action = entry.value;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              left: index == 0 ? 0 : AppSpacing.sm / 2,
              right: index == actions.length - 1 ? 0 : AppSpacing.sm / 2,
            ),
            child:
                _QuickActionButton(
                      icon: action.icon,
                      label: action.label,
                      color: action.color,
                      onTap: action.onTap,
                    )
                    .animate()
                    .fadeIn(delay: (200 + (index * 100)).ms, duration: 400.ms)
                    .scale(
                      delay: (200 + (index * 100)).ms,
                      duration: 400.ms,
                      begin: const Offset(0.8, 0.8),
                      end: const Offset(1.0, 1.0),
                      curve: Curves.easeOutBack,
                    ),
          ),
        );
      }).toList(),
    );
  }
}

class _QuickActionData {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  _QuickActionData({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}

class _QuickActionButton extends StatefulWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  State<_QuickActionButton> createState() => _QuickActionButtonState();
}

class _QuickActionButtonState extends State<_QuickActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _controller.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _controller.reverse();
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md,
            horizontal: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: _isPressed
                ? widget.color.withValues(alpha: 0.15)
                : widget.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.medium),
            border: Border.all(
              color: _isPressed
                  ? widget.color.withValues(alpha: 0.5)
                  : widget.color.withValues(alpha: 0.3),
              width: _isPressed ? 2 : 1,
            ),
            boxShadow: _isPressed
                ? [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Icon(widget.icon, color: widget.color, size: 28)
                  .animate(
                    target: _isPressed ? 1 : 0,
                    onPlay: (controller) => controller.forward(),
                  )
                  .rotate(begin: 0, end: 0.05, duration: 150.ms),
              const SizedBox(height: AppSpacing.xs),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  widget.label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: widget.color,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
