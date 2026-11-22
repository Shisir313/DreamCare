/// Form validation utilities for DermaCare app
class Validators {
  Validators._();

  /// Validate Nepal phone number (10 digits starting with 98 or 97)
  static String? phone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }

    // Remove any whitespace or special characters
    final cleaned = value.replaceAll(RegExp(r'[^\d]'), '');

    if (cleaned.length != 10) {
      return 'Phone number must be 10 digits';
    }

    if (!cleaned.startsWith('98') && !cleaned.startsWith('97')) {
      return 'Phone number must start with 98 or 97';
    }

    return null;
  }

  /// Validate password (minimum 8 characters)
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }

    if (value.length > 128) {
      return 'Password must be less than 128 characters';
    }

    return null;
  }

  /// Validate password confirmation matches
  static String? confirmPassword(String? value, String? originalPassword) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }

    if (value != originalPassword) {
      return 'Passwords do not match';
    }

    return null;
  }

  /// Validate name (2-100 characters)
  static String? name(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }

    final trimmed = value.trim();

    if (trimmed.length < 2) {
      return 'Name must be at least 2 characters';
    }

    if (trimmed.length > 100) {
      return 'Name must be less than 100 characters';
    }

    // Check if name contains only letters, spaces, and common punctuation
    if (!RegExp(r"^[a-zA-Z\s\-'.]+$").hasMatch(trimmed)) {
      return 'Name can only contain letters, spaces, hyphens, and apostrophes';
    }

    return null;
  }

  /// Validate email (optional but must be valid format if provided)
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Email is optional in most forms
    }

    final trimmed = value.trim();

    // Basic email regex
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(trimmed)) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  /// Validate required email
  static String? requiredEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }

    return email(value);
  }

  /// Validate required field (generic)
  static String? required(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Validate age (must be 13+ for app usage)
  static String? age(int? value) {
    if (value == null) {
      return 'Age is required';
    }

    if (value < 13) {
      return 'You must be at least 13 years old to use this app';
    }

    if (value > 120) {
      return 'Please enter a valid age';
    }

    return null;
  }

  /// Validate date of birth
  static String? dateOfBirth(DateTime? value) {
    if (value == null) {
      return 'Date of birth is required';
    }

    final now = DateTime.now();
    final age = now.year - value.year;

    if (value.isAfter(now)) {
      return 'Date of birth cannot be in the future';
    }

    if (age < 13) {
      return 'You must be at least 13 years old';
    }

    if (age > 120) {
      return 'Please enter a valid date of birth';
    }

    return null;
  }

  /// Format phone number for display (9801234567 → 980-123-4567)
  static String formatPhoneDisplay(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (cleaned.length == 10) {
      return '${cleaned.substring(0, 3)}-${cleaned.substring(3, 6)}-${cleaned.substring(6)}';
    }
    return phone;
  }

  /// Clean phone number for storage (980-123-4567 → 9801234567)
  static String cleanPhone(String phone) {
    return phone.replaceAll(RegExp(r'[^\d]'), '');
  }
}
