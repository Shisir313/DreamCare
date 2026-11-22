import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Staggered animation for list items
class StaggeredList extends StatelessWidget {
  const StaggeredList({
    super.key,
    required this.children,
    this.delay = const Duration(milliseconds: 100),
    this.staggerDelay = const Duration(milliseconds: 80),
    this.fadeInDuration = const Duration(milliseconds: 400),
    this.slideDuration = const Duration(milliseconds: 400),
    this.slideOffset = 0.2,
    this.axis = Axis.vertical,
  });

  final List<Widget> children;
  final Duration delay;
  final Duration staggerDelay;
  final Duration fadeInDuration;
  final Duration slideDuration;
  final double slideOffset;
  final Axis axis;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: children.asMap().entries.map((entry) {
        final index = entry.key;
        final child = entry.value;

        return child
            .animate()
            .fadeIn(
              delay: delay + (staggerDelay * index),
              duration: fadeInDuration,
              curve: Curves.easeOut,
            )
            .slideX(
              begin: axis == Axis.horizontal ? -slideOffset : 0,
              end: 0,
              delay: delay + (staggerDelay * index),
              duration: slideDuration,
              curve: Curves.easeOutCubic,
            )
            .slideY(
              begin: axis == Axis.vertical ? slideOffset : 0,
              end: 0,
              delay: delay + (staggerDelay * index),
              duration: slideDuration,
              curve: Curves.easeOutCubic,
            );
      }).toList(),
    );
  }
}

/// Staggered grid animation
class StaggeredGrid extends StatelessWidget {
  const StaggeredGrid({
    super.key,
    required this.children,
    this.crossAxisCount = 2,
    this.crossAxisSpacing = 12,
    this.mainAxisSpacing = 12,
    this.delay = const Duration(milliseconds: 100),
    this.staggerDelay = const Duration(milliseconds: 60),
  });

  final List<Widget> children;
  final int crossAxisCount;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final Duration delay;
  final Duration staggerDelay;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: crossAxisSpacing,
        mainAxisSpacing: mainAxisSpacing,
      ),
      itemCount: children.length,
      itemBuilder: (context, index) {
        return children[index]
            .animate()
            .fadeIn(
              delay: delay + (staggerDelay * index),
              duration: const Duration(milliseconds: 400),
            )
            .scale(
              begin: const Offset(0.8, 0.8),
              end: const Offset(1.0, 1.0),
              delay: delay + (staggerDelay * index),
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutBack,
            );
      },
    );
  }
}

/// Animated list view with stagger
class AnimatedListView extends StatelessWidget {
  const AnimatedListView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.separator,
    this.padding,
    this.physics,
    this.shrinkWrap = false,
    this.delay = const Duration(milliseconds: 50),
    this.staggerDelay = const Duration(milliseconds: 60),
  });

  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final Widget? separator;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;
  final bool shrinkWrap;
  final Duration delay;
  final Duration staggerDelay;

  @override
  Widget build(BuildContext context) {
    if (separator != null) {
      return ListView.separated(
        padding: padding,
        physics: physics,
        shrinkWrap: shrinkWrap,
        itemCount: itemCount,
        separatorBuilder: (context, index) => separator!,
        itemBuilder: (context, index) {
          return itemBuilder(context, index)
              .animate()
              .fadeIn(
                delay: delay + (staggerDelay * index),
                duration: const Duration(milliseconds: 400),
              )
              .slideX(
                begin: -0.1,
                end: 0,
                delay: delay + (staggerDelay * index),
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutCubic,
              );
        },
      );
    }

    return ListView.builder(
      padding: padding,
      physics: physics,
      shrinkWrap: shrinkWrap,
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return itemBuilder(context, index)
            .animate()
            .fadeIn(
              delay: delay + (staggerDelay * index),
              duration: const Duration(milliseconds: 400),
            )
            .slideX(
              begin: -0.1,
              end: 0,
              delay: delay + (staggerDelay * index),
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
            );
      },
    );
  }
}

/// Cascade animation wrapper for individual widgets
class CascadeAnimation extends StatelessWidget {
  const CascadeAnimation({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.animationType = CascadeAnimationType.slideUp,
  });

  final Widget child;
  final Duration delay;
  final CascadeAnimationType animationType;

  @override
  Widget build(BuildContext context) {
    switch (animationType) {
      case CascadeAnimationType.slideUp:
        return child
            .animate()
            .fadeIn(delay: delay, duration: 400.ms)
            .slideY(begin: 0.3, end: 0, delay: delay, duration: 400.ms);

      case CascadeAnimationType.slideLeft:
        return child
            .animate()
            .fadeIn(delay: delay, duration: 400.ms)
            .slideX(begin: -0.2, end: 0, delay: delay, duration: 400.ms);

      case CascadeAnimationType.slideRight:
        return child
            .animate()
            .fadeIn(delay: delay, duration: 400.ms)
            .slideX(begin: 0.2, end: 0, delay: delay, duration: 400.ms);

      case CascadeAnimationType.scale:
        return child
            .animate()
            .fadeIn(delay: delay, duration: 400.ms)
            .scale(
              begin: const Offset(0.8, 0.8),
              end: const Offset(1.0, 1.0),
              delay: delay,
              duration: 400.ms,
              curve: Curves.easeOutBack,
            );

      case CascadeAnimationType.fadeIn:
        return child.animate().fadeIn(delay: delay, duration: 500.ms);
    }
  }
}

enum CascadeAnimationType {
  slideUp,
  slideLeft,
  slideRight,
  scale,
  fadeIn,
}

/// Row with staggered children
class StaggeredRow extends StatelessWidget {
  const StaggeredRow({
    super.key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.delay = const Duration(milliseconds: 100),
    this.staggerDelay = const Duration(milliseconds: 50),
  });

  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final Duration delay;
  final Duration staggerDelay;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      children: children.asMap().entries.map((entry) {
        final index = entry.key;
        final child = entry.value;

        return child
            .animate()
            .fadeIn(
              delay: delay + (staggerDelay * index),
              duration: const Duration(milliseconds: 400),
            )
            .slideX(
              begin: -0.2,
              end: 0,
              delay: delay + (staggerDelay * index),
              duration: const Duration(milliseconds: 400),
            );
      }).toList(),
    );
  }
}

/// Wrap with staggered children
class StaggeredWrap extends StatelessWidget {
  const StaggeredWrap({
    super.key,
    required this.children,
    this.spacing = 8.0,
    this.runSpacing = 8.0,
    this.alignment = WrapAlignment.start,
    this.delay = const Duration(milliseconds: 100),
    this.staggerDelay = const Duration(milliseconds: 40),
  });

  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final WrapAlignment alignment;
  final Duration delay;
  final Duration staggerDelay;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: spacing,
      runSpacing: runSpacing,
      alignment: alignment,
      children: children.asMap().entries.map((entry) {
        final index = entry.key;
        final child = entry.value;

        return child
            .animate()
            .fadeIn(
              delay: delay + (staggerDelay * index),
              duration: const Duration(milliseconds: 300),
            )
            .scale(
              begin: const Offset(0.5, 0.5),
              end: const Offset(1.0, 1.0),
              delay: delay + (staggerDelay * index),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
            );
      }).toList(),
    );
  }
}
