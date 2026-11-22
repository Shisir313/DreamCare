import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Custom page transitions for the app
class AppPageTransitions {
  /// Fade transition - smooth opacity change
  static CustomTransitionPage<T> fade<T>({
    required Widget child,
    required LocalKey key,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    return CustomTransitionPage<T>(
      key: key,
      child: child,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          ),
          child: child,
        );
      },
    );
  }

  /// Slide from right - for forward navigation
  static CustomTransitionPage<T> slideRight<T>({
    required Widget child,
    required LocalKey key,
    Duration duration = const Duration(milliseconds: 350),
  }) {
    return CustomTransitionPage<T>(
      key: key,
      child: child,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;

        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        return SlideTransition(
          position: animation.drive(tween),
          child: FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: const Interval(0.0, 0.7, curve: Curves.easeIn),
            ),
            child: child,
          ),
        );
      },
    );
  }

  /// Slide from bottom - for modal-like screens
  static CustomTransitionPage<T> slideUp<T>({
    required Widget child,
    required LocalKey key,
    Duration duration = const Duration(milliseconds: 400),
  }) {
    return CustomTransitionPage<T>(
      key: key,
      child: child,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        const curve = Curves.easeOutCubic;

        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }

  /// Scale with fade - for pop-up style screens
  static CustomTransitionPage<T> scale<T>({
    required Widget child,
    required LocalKey key,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    return CustomTransitionPage<T>(
      key: key,
      child: child,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: Tween<double>(begin: 0.92, end: 1.0).animate(
            CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
          ),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
    );
  }

  /// Shared axis - Material Design style
  static CustomTransitionPage<T> sharedAxis<T>({
    required Widget child,
    required LocalKey key,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    return CustomTransitionPage<T>(
      key: key,
      child: child,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
          ),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 0.03),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              ),
            ),
            child: child,
          ),
        );
      },
    );
  }

  /// Rotation with fade - for special screens
  static CustomTransitionPage<T> rotation<T>({
    required Widget child,
    required LocalKey key,
    Duration duration = const Duration(milliseconds: 500),
  }) {
    return CustomTransitionPage<T>(
      key: key,
      child: child,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return RotationTransition(
          turns: Tween<double>(begin: 0.95, end: 1.0).animate(
            CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutBack,
            ),
          ),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.9, end: 1.0).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              ),
            ),
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          ),
        );
      },
    );
  }

  /// No transition - instant
  static CustomTransitionPage<T> none<T>({
    required Widget child,
    required LocalKey key,
  }) {
    return CustomTransitionPage<T>(
      key: key,
      child: child,
      transitionDuration: Duration.zero,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return child;
      },
    );
  }

  /// Get appropriate transition based on route type
  static CustomTransitionPage<T> auto<T>({
    required Widget child,
    required LocalKey key,
    required String path,
  }) {
    // Modal-style routes (payment, booking)
    if (path.contains('/payment') || path.contains('/book')) {
      return slideUp(child: child, key: key);
    }

    // Detail screens (doctor profile, prescription details)
    if (path.contains('/doctor/') || path.contains('/prescription/')) {
      return slideRight(child: child, key: key);
    }

    // Main navigation (bottom nav screens)
    if (path == '/home' ||
        path == '/doctors' ||
        path == '/care' ||
        path == '/profile') {
      return sharedAxis(child: child, key: key);
    }

    // Auth screens
    if (path.contains('/login') || path.contains('/register')) {
      return fade(child: child, key: key);
    }

    // Success screens
    if (path.contains('/success') || path.contains('/confirmed')) {
      return scale(child: child, key: key);
    }

    // Default
    return fade(child: child, key: key);
  }
}
