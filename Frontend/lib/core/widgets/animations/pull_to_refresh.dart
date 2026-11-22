import 'package:flutter/material.dart';

/// Custom pull-to-refresh widget with animations
class AnimatedPullToRefresh extends StatefulWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final Color? indicatorColor;
  final double displacement;

  const AnimatedPullToRefresh({
    super.key,
    required this.child,
    required this.onRefresh,
    this.indicatorColor,
    this.displacement = 40.0,
  });

  @override
  State<AnimatedPullToRefresh> createState() => _AnimatedPullToRefreshState();
}

class _AnimatedPullToRefreshState extends State<AnimatedPullToRefresh>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;

    setState(() => _isRefreshing = true);
    _controller.repeat();

    await widget.onRefresh();

    _controller.stop();
    setState(() => _isRefreshing = false);
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      displacement: widget.displacement,
      color: widget.indicatorColor ?? Theme.of(context).primaryColor,
      child: widget.child,
    );
  }
}

/// Custom refresh indicator with water drop animation
class WaterDropRefreshIndicator extends StatelessWidget {
  final Widget child;
  final Future<void> Function() onRefresh;

  const WaterDropRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      displacement: 60,
      backgroundColor: Colors.white,
      color: const Color(0xFF4A90E2),
      strokeWidth: 3.0,
      child: child,
    );
  }
}

/// Animated refresh indicator builder
class CustomRefreshIndicator extends StatefulWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final Widget Function(BuildContext, double) builder;

  const CustomRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
    required this.builder,
  });

  @override
  State<CustomRefreshIndicator> createState() => _CustomRefreshIndicatorState();
}

class _CustomRefreshIndicatorState extends State<CustomRefreshIndicator> {
  double _dragOffset = 0.0;
  bool _isRefreshing = false;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollUpdateNotification) {
          if (notification.metrics.extentBefore == 0) {
            setState(() {
              _dragOffset = notification.metrics.pixels.abs();
            });
          }
        } else if (notification is ScrollEndNotification) {
          if (_dragOffset > 100 && !_isRefreshing) {
            _handleRefresh();
          }
          setState(() => _dragOffset = 0);
        }
        return false;
      },
      child: Stack(
        children: [
          widget.child,
          if (_dragOffset > 0 || _isRefreshing)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: widget.builder(context, _dragOffset / 100),
            ),
        ],
      ),
    );
  }

  Future<void> _handleRefresh() async {
    setState(() => _isRefreshing = true);
    await widget.onRefresh();
    setState(() => _isRefreshing = false);
  }
}

/// Shimmer refresh indicator
class ShimmerRefreshIndicator extends StatelessWidget {
  final Widget child;
  final Future<void> Function() onRefresh;

  const ShimmerRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator.adaptive(onRefresh: onRefresh, child: child);
  }
}
