import 'package:flutter/material.dart';
import 'app_colors.dart';

/// DermaCare Explicit Material 3 Color Schemes
/// Built directly from brand design tokens (no ColorScheme.fromSeed).

const ColorScheme lightColorScheme = ColorScheme(
  brightness: Brightness.light,

  // Primary: Deep Emerald
  primary: AppColors.lightPrimary,
  onPrimary: AppColors.lightOnPrimary,
  primaryContainer: AppColors.lightPrimaryContainer,
  onPrimaryContainer: AppColors.lightOnPrimaryContainer,

  // Secondary: Subtle Emerald Accent
  secondary: AppColors.lightSecondary,
  onSecondary: AppColors.lightOnSecondary,
  secondaryContainer: Color(0xFFE4F2EB),
  onSecondaryContainer: Color(0xFF0F362C),

  // Tertiary: Warm Gold Accent
  tertiary: AppColors.lightGoldText,
  onTertiary: AppColors.lightOnPrimary,
  tertiaryContainer: Color(0xFFFBF1DD),
  onTertiaryContainer: Color(0xFF4A3409),

  // Error & Status
  error: AppColors.lightError,
  onError: AppColors.lightOnPrimary,
  errorContainer: AppColors.lightErrorContainer,
  onErrorContainer: AppColors.lightOnErrorContainer,

  // Surfaces & Backgrounds (Ivory / Warm Tint)
  surface: AppColors.lightSurface,
  onSurface: AppColors.lightTextPrimary,
  surfaceContainerHighest: AppColors.lightSurfaceVariant,
  onSurfaceVariant: AppColors.lightTextSecondary,

  // Outlines & Hairlines
  outline: AppColors.lightOutline,
  outlineVariant: AppColors.lightOutlineVariant,

  // Shadows
  shadow: Color(0x140E3A2F),
  scrim: Color(0x66000000),
  inverseSurface: Color(0xFF1B2C25),
  onInverseSurface: Color(0xFFF3EEE2),
  inversePrimary: AppColors.darkPrimary,
  surfaceTint: Colors.transparent,
);

const ColorScheme darkColorScheme = ColorScheme(
  brightness: Brightness.dark,

  // Primary: Soft Luminous Emerald
  primary: AppColors.darkPrimary,
  onPrimary: AppColors.darkOnPrimary,
  primaryContainer: AppColors.darkPrimaryContainer,
  onPrimaryContainer: AppColors.darkOnPrimaryContainer,

  // Secondary: Soft Mint Accent
  secondary: AppColors.darkSecondary,
  onSecondary: AppColors.darkOnSecondary,
  secondaryContainer: Color(0xFF17382F),
  onSecondaryContainer: Color(0xFFBCE7D6),

  // Tertiary: Champagne Gold Accent
  tertiary: AppColors.darkGold,
  onTertiary: AppColors.darkOnPrimary,
  tertiaryContainer: Color(0xFF3F3218),
  onTertiaryContainer: Color(0xFFF6DDA6),

  // Error
  error: AppColors.darkError,
  onError: Color(0xFF601410),
  errorContainer: AppColors.darkErrorContainer,
  onErrorContainer: AppColors.darkError,

  // Surfaces & Backgrounds (Layered Deep Obsidian-Emerald)
  surface: AppColors.darkSurface,
  onSurface: AppColors.darkTextPrimary,
  surfaceContainerHighest: AppColors.darkSurfaceHigh,
  onSurfaceVariant: AppColors.darkTextSecondary,

  // Outlines
  outline: AppColors.darkOutline,
  outlineVariant: AppColors.darkOutlineVariant,

  // Shadows
  shadow: Color(0xFF000000),
  scrim: Color(0x99000000),
  inverseSurface: Color(0xFFF3EEE2),
  onInverseSurface: Color(0xFF10231D),
  inversePrimary: AppColors.lightPrimary,
  surfaceTint: Colors.transparent,
);
