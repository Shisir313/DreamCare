import 'package:flutter/material.dart';

import '../../services/sound_service.dart';

/// Swipeable card with action callbacks
class SwipeActionCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;
  final Color leftActionColor;
  final Color rightActionColor;
  final IconData leftActionIcon;
  final IconData rightActionIcon;
  final String? leftActionLabel;
  final String? rightActionLabel;
  final double threshold;

  const SwipeActionCard({
    super.key,
    required this.child,
    this.onSwipeLeft,
    this.onSwipeRight,
    this.leftActionColor = Colors.red,
    this.rightActionColor = Colors.green,
    this.leftActionIcon = Icons.delete,
    this.rightActionIcon = Icons.check,
    this.leftActionLabel,
    this.rightActionLabel,
    this.threshold = 0.4,
  });

  @override
  State<SwipeActionCard> createState() => _SwipeActionCardState();
}

class _SwipeActionCardState extends State<SwipeActionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _dragExtent = 0.0;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDragStart(DragStartDetails details) {
    setState(() => _isDragging = true);
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    final delta = details.primaryDelta ?? 0;
    final width = MediaQuery.of(context).size.width;

    setState(() {
      _dragExtent = (_dragExtent + delta).clamp(-width, width);
    });

    // Play swipe sound at threshold
    final progress = (_dragExtent.abs() / width);
    if (progress >= widget.threshold && progress < widget.threshold + 0.05) {
      SoundService().playSwipe();
    }
  }

  void _handleDragEnd(DragEndDetails details) {
    final width = MediaQuery.of(context).size.width;
    final threshold = width * widget.threshold;

    if (_dragExtent.abs() >= threshold) {
      // Trigger action
      if (_dragExtent < 0 && widget.onSwipeLeft != null) {
        _animateOut(left: true).then((_) => widget.onSwipeLeft!());
      } else if (_dragExtent > 0 && widget.onSwipeRight != null) {
        _animateOut(left: false).then((_) => widget.onSwipeRight!());
      } else {
        _animateReset();
      }
    } else {
      _animateReset();
    }

    setState(() => _isDragging = false);
  }

  Future<void> _animateOut({required bool left}) async {
    final width = MediaQuery.of(context).size.width;
    setState(() {
      _dragExtent = left ? -width : width;
    });
    await Future.delayed(const Duration(milliseconds: 200));
  }

  void _animateReset() {
    setState(() => _dragExtent = 0);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final progress = (_dragExtent.abs() / width).clamp(0.0, 1.0);
    final showLeftAction = _dragExtent < 0;
    final showRightAction = _dragExtent > 0;

    return GestureDetector(
      onHorizontalDragStart: _handleDragStart,
      onHorizontalDragUpdate: _handleDragUpdate,
      onHorizontalDragEnd: _handleDragEnd,
      child: Stack(
        children: [
          // Background actions
          Positioned.fill(
            child: Row(
              children: [
                // Right action (shown when swiping right)
                if (showRightAction)
                  Expanded(
                    child: Container(
                      color: widget.rightActionColor.withOpacity(progress),
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.only(left: 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            widget.rightActionIcon,
                            color: Colors.white,
                            size: 24 + (progress * 8),
                          ),
                          if (widget.rightActionLabel != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              widget.rightActionLabel!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                // Left action (shown when swiping left)
                if (showLeftAction)
                  Expanded(
                    child: Container(
                      color: widget.leftActionColor.withOpacity(progress),
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            widget.leftActionIcon,
                            color: Colors.white,
                            size: 24 + (progress * 8),
                          ),
                          if (widget.leftActionLabel != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              widget.leftActionLabel!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Card content
          AnimatedContainer(
            duration: _isDragging
                ? Duration.zero
                : const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            transform: Matrix4.translationValues(_dragExtent, 0, 0),
            child: widget.child,
          ),
        ],
      ),
    );
  }
}

/// Dismissible card with animation
class DismissibleCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onDismissed;
  final String dismissKey;
  final DismissDirection direction;
  final Color backgroundColor;

  const DismissibleCard({
    super.key,
    required this.child,
    required this.dismissKey,
    this.onDismissed,
    this.direction = DismissDirection.horizontal,
    this.backgroundColor = Colors.red,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(dismissKey),
      direction: direction,
      background: Container(
        color: backgroundColor,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      secondaryBackground: Container(
        color: backgroundColor,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        SoundService().playSwipe();
        onDismissed?.call();
      },
      child: child,
    );
  }
}
