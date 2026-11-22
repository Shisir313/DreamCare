/// App-wide constants for DermaCare
library;

/// Application information
class AppInfo {
  AppInfo._();

  static const String appName = 'DermaCare';
  static const String tagline = 'Your skincare companion';
  static const String version = '1.0.0';
  static const String buildNumber = '1';
}

/// Regional settings for Nepal
class RegionalSettings {
  RegionalSettings._();

  static const String countryCode = 'NP';
  static const String currencyCode = 'NPR';
  static const String currencySymbol = 'Rs';
  static const String timezone = 'Asia/Kathmandu'; // UTC+5:45
  static const String timezoneAbbr = 'NPT';
  static const String locale = 'en_NP';
}

/// Currency conversion constants
class CurrencyConstants {
  CurrencyConstants._();

  /// 1 NPR = 100 paisa
  static const int paisaPerRupee = 100;

  /// Convert rupees to paisa (storage format)
  static int rupeesToPaisa(double rupees) {
    return (rupees * paisaPerRupee).round();
  }

  /// Convert paisa to rupees (display format)
  static double paisaToRupees(int paisa) {
    return paisa / paisaPerRupee;
  }

  /// Format paisa as NPR string
  static String formatPaisa(int paisa) {
    final rupees = paisaToRupees(paisa);
    return '${RegionalSettings.currencySymbol} ${rupees.toStringAsFixed(2)}';
  }
}

/// Membership tier pricing and features
class MembershipConstants {
  MembershipConstants._();

  // Prices in paisa
  static const int basicPriceMonthly = 39900; // Rs 399
  static const int premiumPriceMonthly = 49900; // Rs 499
  static const int payPerConsultation = 20000; // Rs 200

  // Term duration
  static const int termWeeks = 4;
  static const int termDays = 28;

  // Feature limits
  static const int basicConsultationsPerTerm = 1;
  static const int premiumConsultationsPerTerm = 2;

  // AI Analysis limits (daily)
  static const int basicAiAnalysisPerDay = 1;
  static const int premiumAiAnalysisPerDay = 3;
}

/// Payment gateway identifiers
class PaymentGateways {
  PaymentGateways._();

  static const String esewa = 'esewa';
  static const String khalti = 'khalti';
  static const String connectIps = 'connectips';

  static const List<String> all = [esewa, khalti, connectIps];
}

/// API and network configuration
class ApiConstants {
  ApiConstants._();

  // Base URL - will be configured per environment
  static const String baseUrl = 'https://api.dermacare.app/v1';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  // Retry configuration
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
}

/// Storage keys for secure and local storage
class StorageKeys {
  StorageKeys._();

  // Secure storage (flutter_secure_storage)
  static const String accessToken = 'access_token';
  static const String refreshToken = 'refresh_token';
  static const String userId = 'user_id';

  // Local storage (shared_preferences)
  static const String isDarkMode = 'is_dark_mode';
  static const String isOnboardingComplete = 'is_onboarding_complete';
  static const String lastSyncTimestamp = 'last_sync_timestamp';
  static const String reminderSettings = 'reminder_settings';
  static const String privacyConsentGiven = 'privacy_consent_given';
  static const String privacyConsentTimestamp = 'privacy_consent_timestamp';
}

/// Notification channel configuration
class NotificationChannels {
  NotificationChannels._();

  // Channel IDs
  static const String hydrationReminders = 'hydration_reminders';
  static const String routineReminders = 'routine_reminders';
  static const String appointmentReminders = 'appointment_reminders';
  static const String generalNotifications = 'general_notifications';

  // Channel names (user-visible)
  static const String hydrationName = 'Hydration Reminders';
  static const String routineName = 'Routine Reminders';
  static const String appointmentName = 'Appointment Reminders';
  static const String generalName = 'General Notifications';
}

/// Validation rules
class ValidationRules {
  ValidationRules._();

  // Phone number (Nepal format)
  static const String phonePattern = r'^(98|97)\d{8}$'; // 10 digits starting with 98 or 97

  // Password
  static const int passwordMinLength = 8;
  static const int passwordMaxLength = 128;

  // Name
  static const int nameMinLength = 2;
  static const int nameMaxLength = 100;

  // Bio/Notes
  static const int bioMaxLength = 500;
  static const int notesMaxLength = 1000;

  // Check-in
  static const int checkInMinPhotos = 1;
  static const int checkInMaxPhotos = 3;
}

/// Hydration calculation constants
class HydrationConstants {
  HydrationConstants._();

  // Base water intake in ml per kg of body weight
  static const double baseWaterPerKg = 30.0;

  // Activity level multipliers
  static const double sedentaryMultiplier = 1.0;
  static const double lightMultiplier = 1.1;
  static const double moderateMultiplier = 1.2;
  static const double activeMultiplier = 1.3;

  // Climate adjustments (ml)
  static const int hotClimateBonus = 500;
  static const int humidClimateReduction = 200;

  // Glass size in ml
  static const int standardGlassSizeML = 250;

  // Daily limits
  static const int minDailyGoalML = 1000;
  static const int maxDailyGoalML = 5000;
}

/// Time-related constants
class TimeConstants {
  TimeConstants._();

  // Business hours (Nepal time)
  static const int consultationStartHour = 9; // 9 AM
  static const int consultationEndHour = 18; // 6 PM

  // Appointment durations in minutes
  static const int videoConsultationDuration = 30;
  static const int chatConsultationDuration = 0; // Async, no fixed duration

  // Reminder advance times in minutes
  static const int appointmentReminderAdvance = 60; // 1 hour before
  static const int routineReminderAdvance = 15; // 15 minutes before

  // Debounce durations
  static const Duration searchDebounce = Duration(milliseconds: 500);
  static const Duration autoSaveDebounce = Duration(seconds: 2);
}

/// Asset paths
class AssetPaths {
  AssetPaths._();

  // Images
  static const String logo = 'assets/images/logo.png';
  static const String logoLight = 'assets/images/logo_light.png';
  static const String logoDark = 'assets/images/logo_dark.png';
  static const String splash = 'assets/images/splash.png';
  static const String placeholder = 'assets/images/placeholder.png';

  // Illustrations (for onboarding, empty states)
  static const String onboardingWelcome = 'assets/illustrations/welcome.svg';
  static const String onboardingSkin = 'assets/illustrations/skin.svg';
  static const String onboardingRoutine = 'assets/illustrations/routine.svg';
  static const String emptyAppointments = 'assets/illustrations/empty_appointments.svg';
  static const String emptyRoutine = 'assets/illustrations/empty_routine.svg';
  static const String errorGeneric = 'assets/illustrations/error.svg';

  // Icons (if custom icons needed beyond Material Icons)
  static const String iconWater = 'assets/icons/water.svg';
  static const String iconSun = 'assets/icons/sun.svg';
  static const String iconMoon = 'assets/icons/moon.svg';
}

/// Feature flags for development
class FeatureFlags {
  FeatureFlags._();

  static const bool enableMockData = true; // Toggle fake repositories
  static const bool enableDebugLogging = true;
  static const bool enableAnalytics = false; // Not implemented yet
  static const bool enableCrashReporting = false; // Not implemented yet
  static const bool enableBiometricAuth = false; // Future feature
}

/// Error messages (localized later)
class ErrorMessages {
  ErrorMessages._();

  static const String networkError = 'Unable to connect. Please check your internet connection.';
  static const String serverError = 'Something went wrong on our end. Please try again later.';
  static const String unauthorizedError = 'Your session has expired. Please log in again.';
  static const String notFoundError = 'The requested resource was not found.';
  static const String validationError = 'Please check your input and try again.';
  static const String unknownError = 'An unexpected error occurred. Please try again.';
  static const String timeoutError = 'Request timed out. Please try again.';
  static const String permissionDenied = 'Permission denied. Please grant the required permissions.';
}

/// Success messages
class SuccessMessages {
  SuccessMessages._();

  static const String profileUpdated = 'Profile updated successfully';
  static const String passwordChanged = 'Password changed successfully';
  static const String appointmentBooked = 'Appointment booked successfully';
  static const String checkInSubmitted = 'Check-in submitted successfully';
  static const String reminderSet = 'Reminder set successfully';
  static const String dataDeleted = 'Your data has been deleted';
}
