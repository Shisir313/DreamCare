import 'package:flutter/material.dart';

import 'color_scheme.dart' as app_colors;
import 'app_spacing.dart';
import 'app_colors.dart';
import 'app_theme_extension.dart';

/// DermaCare App Theme
/// Material 3 design with custom color tokens and spacing
class AppTheme {
  AppTheme._();

  /// Light theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: app_colors.lightColorScheme,

      // Typography
      textTheme: _textTheme,

      // Components
      appBarTheme: _appBarTheme(app_colors.lightColorScheme),
      bottomNavigationBarTheme: _bottomNavTheme(app_colors.lightColorScheme),
      elevatedButtonTheme: _elevatedButtonTheme(app_colors.lightColorScheme),
      outlinedButtonTheme: _outlinedButtonTheme(app_colors.lightColorScheme),
      textButtonTheme: _textButtonTheme(app_colors.lightColorScheme),
      inputDecorationTheme: _inputDecorationTheme(app_colors.lightColorScheme),
      cardTheme: _cardTheme(app_colors.lightColorScheme),
      chipTheme: _chipTheme(app_colors.lightColorScheme),
      dialogTheme: _dialogTheme(app_colors.lightColorScheme),
      snackBarTheme: _snackBarTheme(app_colors.lightColorScheme),

      // Other
      scaffoldBackgroundColor: AppColors.lightBackground,
      dividerColor: app_colors.lightColorScheme.outlineVariant,
      extensions: const [DermaCareThemeExtension.light],
    );
  }

  /// Dark theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: app_colors.darkColorScheme,

      // Typography
      textTheme: _textTheme,

      // Components
      appBarTheme: _appBarTheme(app_colors.darkColorScheme),
      bottomNavigationBarTheme: _bottomNavTheme(app_colors.darkColorScheme),
      elevatedButtonTheme: _elevatedButtonTheme(app_colors.darkColorScheme),
      outlinedButtonTheme: _outlinedButtonTheme(app_colors.darkColorScheme),
      textButtonTheme: _textButtonTheme(app_colors.darkColorScheme),
      inputDecorationTheme: _inputDecorationTheme(app_colors.darkColorScheme),
      cardTheme: _cardTheme(app_colors.darkColorScheme),
      chipTheme: _chipTheme(app_colors.darkColorScheme),
      dialogTheme: _dialogTheme(app_colors.darkColorScheme),
      snackBarTheme: _snackBarTheme(app_colors.darkColorScheme),

      // Other
      scaffoldBackgroundColor: AppColors.darkBackground,
      dividerColor: app_colors.darkColorScheme.outlineVariant,
      extensions: const [DermaCareThemeExtension.dark],
    );
  }

  /// Material 3 Text Theme
  static const TextTheme _textTheme = TextTheme(
    // Display - Large headings (rare use)
    displayLarge: TextStyle(
      fontSize: 57,
      fontWeight: FontWeight.w400,
      height: 64 / 57,
    ),
    displayMedium: TextStyle(
      fontSize: 45,
      fontWeight: FontWeight.w400,
      height: 52 / 45,
    ),
    displaySmall: TextStyle(
      fontSize: 36,
      fontWeight: FontWeight.w400,
      height: 44 / 36,
    ),

    // Headline - Section headings
    headlineLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w400,
      height: 40 / 32,
    ),
    headlineMedium: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w400,
      height: 36 / 28,
    ),
    headlineSmall: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w400,
      height: 32 / 24,
    ),

    // Title - Card titles, app bar titles
    titleLarge: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w500,
      height: 28 / 22,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 24 / 16,
    ),
    titleSmall: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      height: 20 / 14,
    ),

    // Body - Paragraph text (most common)
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 24 / 16,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 20 / 14,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      height: 16 / 12,
    ),

    // Label - Buttons, chips, small labels
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      height: 20 / 14,
    ),
    labelMedium: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      height: 16 / 12,
    ),
    labelSmall: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      height: 16 / 11,
    ),
  );

  /// App Bar Theme
  static AppBarTheme _appBarTheme(ColorScheme colorScheme) {
    return AppBarTheme(
      elevation: 0,
      centerTitle: false,
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      titleTextStyle: _textTheme.titleLarge?.copyWith(
        color: colorScheme.onSurface,
      ),
    );
  }

  /// Bottom Navigation Bar Theme
  static BottomNavigationBarThemeData _bottomNavTheme(ColorScheme colorScheme) {
    return BottomNavigationBarThemeData(
      elevation: AppElevation.level3,
      backgroundColor: colorScheme.surface,
      selectedItemColor: colorScheme.primary,
      unselectedItemColor: colorScheme.onSurfaceVariant,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: _textTheme.labelMedium,
      unselectedLabelStyle: _textTheme.labelMedium,
    );
  }

  /// Elevated Button Theme (Primary Button)
  static ElevatedButtonThemeData _elevatedButtonTheme(ColorScheme colorScheme) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        disabledBackgroundColor: colorScheme.onSurface.withValues(alpha: 0.12),
        disabledForegroundColor: colorScheme.onSurface.withValues(alpha: 0.38),
        elevation: AppElevation.level1,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        minimumSize: const Size(0, kMinTouchTargetSize),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
        ),
        textStyle: _textTheme.labelLarge,
      ),
    );
  }

  /// Outlined Button Theme (Secondary Button)
  static OutlinedButtonThemeData _outlinedButtonTheme(ColorScheme colorScheme) {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: colorScheme.primary,
        disabledForegroundColor: colorScheme.onSurface.withValues(alpha: 0.38),
        side: BorderSide(color: colorScheme.outline),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        minimumSize: const Size(0, kMinTouchTargetSize),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
        ),
        textStyle: _textTheme.labelLarge,
      ),
    );
  }

  /// Text Button Theme (Tertiary Button)
  static TextButtonThemeData _textButtonTheme(ColorScheme colorScheme) {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: colorScheme.primary,
        disabledForegroundColor: colorScheme.onSurface.withValues(alpha: 0.38),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        minimumSize: const Size(0, kMinTouchTargetSize),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
        ),
        textStyle: _textTheme.labelLarge,
      ),
    );
  }

  /// Input Decoration Theme (Text Fields)
  static InputDecorationTheme _inputDecorationTheme(ColorScheme colorScheme) {
    return InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surfaceContainerHighest,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.medium),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.medium),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.medium),
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.medium),
        borderSide: BorderSide(color: colorScheme.error, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      labelStyle: _textTheme.bodySmall?.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
      hintStyle: _textTheme.bodyMedium?.copyWith(
        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
      ),
      errorStyle: _textTheme.bodySmall?.copyWith(color: colorScheme.error),
    );
  }

  /// Card Theme
  static CardThemeData _cardTheme(ColorScheme colorScheme) {
    return CardThemeData(
      elevation: AppElevation.level1,
      color: colorScheme.surface,
      surfaceTintColor: colorScheme.surfaceTint,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
      margin: const EdgeInsets.all(AppSpacing.sm),
    );
  }

  /// Chip Theme
  static ChipThemeData _chipTheme(ColorScheme colorScheme) {
    return ChipThemeData(
      backgroundColor: colorScheme.surface,
      selectedColor: colorScheme.secondaryContainer,
      disabledColor: colorScheme.onSurface.withValues(alpha: 0.12),
      labelStyle: _textTheme.labelMedium?.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
      secondaryLabelStyle: _textTheme.labelMedium?.copyWith(
        color: colorScheme.onSecondaryContainer,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.small),
        side: BorderSide(color: colorScheme.outline),
      ),
    );
  }

  /// Dialog Theme
  static DialogThemeData _dialogTheme(ColorScheme colorScheme) {
    return DialogThemeData(
      backgroundColor: colorScheme.surface,
      surfaceTintColor: colorScheme.surfaceTint,
      elevation: AppElevation.level3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.large),
      ),
      titleTextStyle: _textTheme.titleLarge?.copyWith(
        color: colorScheme.onSurface,
      ),
      contentTextStyle: _textTheme.bodyMedium?.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }

  /// SnackBar Theme
  static SnackBarThemeData _snackBarTheme(ColorScheme colorScheme) {
    return SnackBarThemeData(
      backgroundColor: colorScheme.inverseSurface,
      contentTextStyle: _textTheme.bodyMedium?.copyWith(
        color: colorScheme.onInverseSurface,
      ),
      actionTextColor: colorScheme.inversePrimary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.small),
      ),
      elevation: AppElevation.level3,
    );
  }
}
