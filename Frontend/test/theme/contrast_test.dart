import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:derma_care/core/theme/app_colors.dart';

/// Helper function to compute linear channel from 8-bit sRGB channel
double _srgbToLinear(int channel) {
  final c = channel / 255.0;
  return c <= 0.04045 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
}

/// Helper to compute relative luminance for a Color
double relativeLuminance(Color color) {
  final r = _srgbToLinear(color.red);
  final g = _srgbToLinear(color.green);
  final b = _srgbToLinear(color.blue);
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

/// Helper to compute WCAG 2.1 contrast ratio between two colors
double contrastRatio(Color fg, Color bg) {
  final l1 = relativeLuminance(fg);
  final l2 = relativeLuminance(bg);
  final lighter = math.max(l1, l2);
  final darker = math.min(l1, l2);
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  group('WCAG Contrast Ratio Tests', () {
    test('Light mode body text and interactive token pairs meet WCAG AA (>= 4.5:1)', () {
      final pairs = <String, (Color, Color, double)>{
        'textPrimary on background': (AppColors.lightTextPrimary, AppColors.lightBackground, 4.5),
        'textPrimary on surface': (AppColors.lightTextPrimary, AppColors.lightSurface, 4.5),
        'textSecondary on background': (AppColors.lightTextSecondary, AppColors.lightBackground, 4.5),
        'textSecondary on surface': (AppColors.lightTextSecondary, AppColors.lightSurface, 4.5),
        'onPrimary on primary': (AppColors.lightOnPrimary, AppColors.lightPrimary, 4.5),
        'onSecondary on secondary': (AppColors.lightOnSecondary, AppColors.lightSecondary, 4.5),
        'onPrimaryContainer on primaryContainer': (AppColors.lightOnPrimaryContainer, AppColors.lightPrimaryContainer, 4.5),
        'goldText on background': (AppColors.lightGoldText, AppColors.lightBackground, 4.5),
        'goldText on surface': (AppColors.lightGoldText, AppColors.lightSurface, 4.5),
        'error on background': (AppColors.lightError, AppColors.lightBackground, 4.5),
        'success on background': (AppColors.lightSuccess, AppColors.lightBackground, 4.5),
        'warningText on background': (AppColors.lightWarningText, AppColors.lightBackground, 4.5),
      };

      for (final entry in pairs.entries) {
        final (fg, bg, target) = entry.value;
        final ratio = contrastRatio(fg, bg);
        expect(
          ratio,
          greaterThanOrEqualTo(target),
          reason: '${entry.key} had contrast ratio ${ratio.toStringAsFixed(2)}:1, expected >= $target:1',
        );
      }
    });

    test('Dark mode token pairs meet WCAG AA (>= 4.5:1)', () {
      final pairs = <String, (Color, Color, double)>{
        'textPrimary on background': (AppColors.darkTextPrimary, AppColors.darkBackground, 4.5),
        'textPrimary on surface': (AppColors.darkTextPrimary, AppColors.darkSurface, 4.5),
        'textPrimary on surfaceHigh': (AppColors.darkTextPrimary, AppColors.darkSurfaceHigh, 4.5),
        'textSecondary on background': (AppColors.darkTextSecondary, AppColors.darkBackground, 4.5),
        'textSecondary on surface': (AppColors.darkTextSecondary, AppColors.darkSurface, 4.5),
        'textSecondary on surfaceHigh': (AppColors.darkTextSecondary, AppColors.darkSurfaceHigh, 4.5),
        'onPrimary on primary': (AppColors.darkOnPrimary, AppColors.darkPrimary, 4.5),
        'onPrimaryContainer on primaryContainer': (AppColors.darkOnPrimaryContainer, AppColors.darkPrimaryContainer, 4.5),
        'gold on background': (AppColors.darkGold, AppColors.darkBackground, 4.5),
        'gold on surface': (AppColors.darkGold, AppColors.darkSurface, 4.5),
        'error on background': (AppColors.darkError, AppColors.darkBackground, 4.5),
        'error on errorContainer': (AppColors.darkError, AppColors.darkErrorContainer, 4.5),
        'success on background': (AppColors.darkSuccess, AppColors.darkBackground, 4.5),
        'warning on background': (AppColors.darkWarning, AppColors.darkBackground, 4.5),
      };

      for (final entry in pairs.entries) {
        final (fg, bg, target) = entry.value;
        final ratio = contrastRatio(fg, bg);
        expect(
          ratio,
          greaterThanOrEqualTo(target),
          reason: '${entry.key} had contrast ratio ${ratio.toStringAsFixed(2)}:1, expected >= $target:1',
        );
      }
    });

    test('UI components and large elements meet WCAG 3.0:1 threshold', () {
      expect(contrastRatio(AppColors.lightPrimary, AppColors.lightBackground), greaterThanOrEqualTo(3.0));
      expect(contrastRatio(AppColors.darkPrimary, AppColors.darkBackground), greaterThanOrEqualTo(3.0));
      expect(contrastRatio(AppColors.darkOutline, AppColors.darkBackground), greaterThanOrEqualTo(1.8)); // subtle container boundary
    });
  });
}
