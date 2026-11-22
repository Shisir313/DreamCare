import 'package:flutter/material.dart';

/// DermaCare Design Tokens
/// Raw color definitions for Light and Dark themes.
/// Single source of truth for all brand colors.
abstract class AppColors {
  // ==========================================
  // LIGHT TOKENS
  // ==========================================
  static const Color lightBackground = Color(0xFFFBF7EE);
  static const Color lightSurface = Color(0xFFFFFDF8);
  static const Color lightSurfaceVariant = Color(0xFFF3EDDF);

  static const Color lightPrimary = Color(0xFF0E3A2F);
  static const Color lightOnPrimary = Color(0xFFFBF7EE);
  static const Color lightPrimaryContainer = Color(0xFFD7EBE2);
  static const Color lightOnPrimaryContainer = Color(0xFF0B2F27);

  static const Color lightSecondary = Color(0xFF1E5E4C);
  static const Color lightOnSecondary = Color(0xFFFBF7EE);

  static const Color lightOutline = Color(0xFFD9CFB8);
  static const Color lightOutlineVariant = Color(0xFFEAE2D0);

  static const Color lightTextPrimary = Color(0xFF12261F);
  static const Color lightTextSecondary = Color(0xFF4B5E56);

  static const Color lightGold = Color(0xFFE3B872); // decorative only
  static const Color lightGoldText = Color(0xFF8A6420); // for small gold text (5.00:1)

  static const Color lightError = Color(0xFFA8322D);
  static const Color lightErrorContainer = Color(0xFFF9DEDC);
  static const Color lightOnErrorContainer = Color(0xFF410E0B);
  static const Color lightSuccess = Color(0xFF2E7D5B);
  static const Color lightWarning = Color(0xFFB7791F);
  static const Color lightWarningText = Color(0xFF99600F); // WCAG AA text (4.87:1)

  // ==========================================
  // DARK TOKENS
  // ==========================================
  static const Color darkBackground = Color(0xFF0A1A15);
  static const Color darkSurface = Color(0xFF10231D);
  static const Color darkSurfaceHigh = Color(0xFF173028);

  static const Color darkPrimary = Color(0xFF6FC2A5);
  static const Color darkOnPrimary = Color(0xFF06241B);
  static const Color darkPrimaryContainer = Color(0xFF1E5E4C);
  static const Color darkOnPrimaryContainer = Color(0xFFD7EBE2);

  static const Color darkSecondary = Color(0xFF8FD3BA);
  static const Color darkOnSecondary = Color(0xFF06241B);

  static const Color darkOutline = Color(0xFF2C4A40);
  static const Color darkOutlineVariant = Color(0xFF1D352D);

  static const Color darkTextPrimary = Color(0xFFF3EEE2);
  static const Color darkTextSecondary = Color(0xFFB7C4BC);

  static const Color darkGold = Color(0xFFE8C27E);
  static const Color darkGoldText = Color(0xFFE8C27E);

  static const Color darkError = Color(0xFFF2B8B5);
  static const Color darkErrorContainer = Color(0xFF601410);
  static const Color darkSuccess = Color(0xFF7FD1A5);
  static const Color darkWarning = Color(0xFFE8B866);
  static const Color darkWarningText = Color(0xFFE8B866);

  // ==========================================
  // GRADIENTS (Consistent across both modes)
  // ==========================================
  /// Brand Gradient: 135-degree luxury deep-emerald sweep
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF3E8F78),
      Color(0xFF1E5E4C),
      Color(0xFF0B3128),
    ],
    stops: [0.0, 0.5, 1.0],
  );

  /// Gold Gradient: Warm metallic sheen for badges, hairlines & Premium cards
  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFBEBC8),
      Color(0xFFE3B872),
      Color(0xFFF6DDA6),
      Color(0xFFC99A55),
    ],
    stops: [0.0, 0.35, 0.7, 1.0],
  );

  /// Subtle ivory text color for text appearing over the brand gradient
  static const Color onGradientText = Color(0xFFFBF7EE);
}
