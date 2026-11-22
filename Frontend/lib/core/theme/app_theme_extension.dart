import 'package:flutter/material.dart';
import 'app_colors.dart';

/// DermaCare Custom Theme Extension
/// Holds brand-specific tokens that Material 3 ColorScheme does not natively represent:
/// gold accents, goldText, success, warning, warningText, luxury gradients, and hairlines.
@immutable
class DermaCareThemeExtension extends ThemeExtension<DermaCareThemeExtension> {
  const DermaCareThemeExtension({
    required this.gold,
    required this.goldText,
    required this.success,
    required this.warning,
    required this.warningText,
    required this.surfaceHigh,
    required this.brandGradient,
    required this.goldGradient,
    required this.cardBorder,
    required this.goldHairline,
  });

  final Color gold;
  final Color goldText;
  final Color success;
  final Color warning;
  final Color warningText;
  final Color surfaceHigh;
  final LinearGradient brandGradient;
  final LinearGradient goldGradient;
  final BorderSide cardBorder;
  final BorderSide goldHairline;

  /// Light theme preset
  static const DermaCareThemeExtension light = DermaCareThemeExtension(
    gold: AppColors.lightGold,
    goldText: AppColors.lightGoldText,
    success: AppColors.lightSuccess,
    warning: AppColors.lightWarning,
    warningText: AppColors.lightWarningText,
    surfaceHigh: AppColors.lightSurface,
    brandGradient: AppColors.brandGradient,
    goldGradient: AppColors.goldGradient,
    cardBorder: BorderSide(color: AppColors.lightOutline, width: 1.0),
    goldHairline: BorderSide(color: AppColors.lightGold, width: 1.0),
  );

  /// Dark theme preset
  static const DermaCareThemeExtension dark = DermaCareThemeExtension(
    gold: AppColors.darkGold,
    goldText: AppColors.darkGoldText,
    success: AppColors.darkSuccess,
    warning: AppColors.darkWarning,
    warningText: AppColors.darkWarningText,
    surfaceHigh: AppColors.darkSurfaceHigh,
    brandGradient: AppColors.brandGradient,
    goldGradient: AppColors.goldGradient,
    cardBorder: BorderSide(color: AppColors.darkOutline, width: 1.0),
    goldHairline: BorderSide(color: AppColors.darkGold, width: 1.0),
  );

  @override
  DermaCareThemeExtension copyWith({
    Color? gold,
    Color? goldText,
    Color? success,
    Color? warning,
    Color? warningText,
    Color? surfaceHigh,
    LinearGradient? brandGradient,
    LinearGradient? goldGradient,
    BorderSide? cardBorder,
    BorderSide? goldHairline,
  }) {
    return DermaCareThemeExtension(
      gold: gold ?? this.gold,
      goldText: goldText ?? this.goldText,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      warningText: warningText ?? this.warningText,
      surfaceHigh: surfaceHigh ?? this.surfaceHigh,
      brandGradient: brandGradient ?? this.brandGradient,
      goldGradient: goldGradient ?? this.goldGradient,
      cardBorder: cardBorder ?? this.cardBorder,
      goldHairline: goldHairline ?? this.goldHairline,
    );
  }

  @override
  DermaCareThemeExtension lerp(
    ThemeExtension<DermaCareThemeExtension>? other,
    double t,
  ) {
    if (other is! DermaCareThemeExtension) {
      return this;
    }

    return DermaCareThemeExtension(
      gold: Color.lerp(gold, other.gold, t) ?? gold,
      goldText: Color.lerp(goldText, other.goldText, t) ?? goldText,
      success: Color.lerp(success, other.success, t) ?? success,
      warning: Color.lerp(warning, other.warning, t) ?? warning,
      warningText: Color.lerp(warningText, other.warningText, t) ?? warningText,
      surfaceHigh: Color.lerp(surfaceHigh, other.surfaceHigh, t) ?? surfaceHigh,
      brandGradient: LinearGradient.lerp(brandGradient, other.brandGradient, t) ?? brandGradient,
      goldGradient: LinearGradient.lerp(goldGradient, other.goldGradient, t) ?? goldGradient,
      cardBorder: BorderSide.lerp(cardBorder, other.cardBorder, t),
      goldHairline: BorderSide.lerp(goldHairline, other.goldHairline, t),
    );
  }
}

/// Convenience extension on [BuildContext] to access DermaCare theme tokens
extension DermaCareThemeContext on BuildContext {
  DermaCareThemeExtension get dermaTheme =>
      Theme.of(this).extension<DermaCareThemeExtension>() ??
      (Theme.of(this).brightness == Brightness.dark
          ? DermaCareThemeExtension.dark
          : DermaCareThemeExtension.light);
}
