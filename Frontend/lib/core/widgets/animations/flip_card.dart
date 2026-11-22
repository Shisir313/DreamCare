import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Animated flip card widget
class FlipCard extends StatefulWidget {
  final Widget front;
  final Widget back;
  final Duration duration;
  final bool flipOnTap;
  final bool isFlipped;
  final VoidCallback? onFlip;

  const FlipCard({
    super.key,
    required this.front,
    required this.back,
    this.duration = const Duration(milliseconds: 600),
    this.flipOnTap = true,
    this.isFlipped = false,
    this.onFlip,
  });

  @override
  State<FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<FlipCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isFlipped = false;

  @override
  void initState() {
    super.initState();
    _isFlipped = widget.isFlipped;
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (_isFlipped) {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _flip() {
    if (_isFlipped) {
      _controller.reverse();
    } else {
      _controller.forward();
    }
    setState(() => _isFlipped = !_isFlipped);
    widget.onFlip?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.flipOnTap ? _flip : null,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final angle = _animation.value * math.pi;
          final transform = Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(angle);

          return Transform(
            transform: transform,
            alignment: Alignment.center,
            child: angle >= math.pi / 2
                ? Transform(
                    transform: Matrix4.identity()..rotateY(math.pi),
                    alignment: Alignment.center,
                    child: widget.back,
                  )
                : widget.front,
          );
        },
      ),
    );
  }
}

/// 3D flip card with perspective
class Card3D extends StatefulWidget {
  final Widget child;
  final bool enableTilt;
  final double maxTilt;

  const Card3D({
    super.key,
    required this.child,
    this.enableTilt = true,
    this.maxTilt = 0.05,
  });

  @override
  State<Card3D> createState() => _Card3DState();
}

class _Card3DState extends State<Card3D> {
  double _rotateX = 0.0;
  double _rotateY = 0.0;

  void _updateRotation(PointerEvent event, Size size) {
    if (!widget.enableTilt) return;

    final dx = (event.localPosition.dx - size.width / 2) / size.width;
    final dy = (event.localPosition.dy - size.height / 2) / size.height;

    setState(() {
      _rotateY = dx * widget.maxTilt;
      _rotateX = -dy * widget.maxTilt;
    });
  }

  void _resetRotation() {
    setState(() {
      _rotateX = 0.0;
      _rotateY = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (event) => _updateRotation(event, context.size!),
      onExit: (_) => _resetRotation(),
      child: Listener(
        onPointerMove: (event) => _updateRotation(event, context.size!),
        onPointerUp: (_) => _resetRotation(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateX(_rotateX)
            ..rotateY(_rotateY),
          child: widget.child,
        ),
      ),
    );
  }
}

/// Expandable card with flip animation
class ExpandableFlipCard extends StatefulWidget {
  final Widget front;
  final Widget expandedContent;
  final bool isExpanded;
  final VoidCallback? onExpand;

  const ExpandableFlipCard({
    super.key,
    required this.front,
    required this.expandedContent,
    this.isExpanded = false,
    this.onExpand,
  });

  @override
  State<ExpandableFlipCard> createState() => _ExpandableFlipCardState();
}

class _ExpandableFlipCardState extends State<ExpandableFlipCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.isExpanded;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    if (_isExpanded) {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    if (_isExpanded) {
      _controller.reverse();
    } else {
      _controller.forward();
    }
    setState(() => _isExpanded = !_isExpanded);
    widget.onExpand?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggle,
      child: AnimatedBuilder(
        animation: _expandAnimation,
        builder: (context, child) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              widget.front,
              SizeTransition(
                sizeFactor: _expandAnimation,
                child: widget.expandedContent,
              ),
            ],
          );
        },
      ),
    );
  }
}
