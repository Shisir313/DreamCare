/// DermaCare Spacing Constants
/// Based on 8dp grid system
class AppSpacing {
  AppSpacing._();
  
  /// Extra small spacing: 4dp
  static const double xs = 4.0;
  
  /// Small spacing: 8dp
  static const double sm = 8.0;
  
  /// Medium spacing: 16dp (default)
  static const double md = 16.0;
  
  /// Large spacing: 24dp
  static const double lg = 24.0;
  
  /// Extra large spacing: 32dp
  static const double xl = 32.0;
  
  /// Extra extra large spacing: 48dp
  static const double xxl = 48.0;
  
  /// Extra extra extra large spacing: 64dp
  static const double xxxl = 64.0;
}

/// DermaCare Border Radius Constants
class AppRadius {
  AppRadius._();
  
  /// Small radius: 8dp (chips, small buttons)
  static const double small = 8.0;
  
  /// Medium radius: 12dp (cards, inputs, default)
  static const double medium = 12.0;
  
  /// Large radius: 16dp (modals, sheets)
  static const double large = 16.0;
  
  /// Full/circular radius: 9999dp (avatars, FAB)
  static const double full = 9999.0;
}

/// DermaCare Elevation Constants
class AppElevation {
  AppElevation._();
  
  /// Elevation 0: Flush with background
  static const double level0 = 0.0;
  
  /// Elevation 1: Cards at rest (1dp)
  static const double level1 = 1.0;
  
  /// Elevation 2: Cards on hover/press (3dp)
  static const double level2 = 3.0;
  
  /// Elevation 3: FAB, modals, dialogs (6dp)
  static const double level3 = 6.0;
  
  /// Elevation 4: Navigation drawer, bottom sheet (8dp)
  static const double level4 = 8.0;
  
  /// Elevation 5: Modal bottom sheet at max height (12dp)
  static const double level5 = 12.0;
}

/// Minimum touch target size (accessibility requirement)
const double kMinTouchTargetSize = 48.0;

/// Standard icon sizes
class IconSizes {
  IconSizes._();
  
  /// Small icon: 20dp (trailing icons in fields)
  static const double small = 20.0;
  
  /// Standard icon: 24dp (default)
  static const double standard = 24.0;
  
  /// Large icon: 32dp (empty states, large actions)
  static const double large = 32.0;
  
  /// Extra large icon: 64dp (splash, onboarding)
  static const double xlarge = 64.0;
}

/// Avatar sizes
class AvatarSizes {
  AvatarSizes._();
  
  /// Small avatar: 24dp
  static const double small = 24.0;
  
  /// Standard avatar: 40dp (default, list items)
  static const double standard = 40.0;
  
  /// Large avatar: 80dp (profile screens)
  static const double large = 80.0;
  
  /// Extra large avatar: 120dp (profile photo upload)
  static const double xlarge = 120.0;
}
