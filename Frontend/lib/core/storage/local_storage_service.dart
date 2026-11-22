import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/constants.dart';

/// Provider for local storage service
final localStorageServiceProvider = Provider<LocalStorageService>((ref) {
  throw UnimplementedError('LocalStorageService must be overridden');
});

/// Local storage service for non-sensitive data
/// Uses shared_preferences for persistent storage
class LocalStorageService {
  LocalStorageService(this._prefs);

  final SharedPreferences _prefs;

  // Theme mode
  Future<bool> setDarkMode(bool isDark) async {
    return await _prefs.setBool(StorageKeys.isDarkMode, isDark);
  }

  bool? getDarkMode() {
    return _prefs.getBool(StorageKeys.isDarkMode);
  }

  // Onboarding
  Future<bool> setOnboardingComplete(bool complete) async {
    return await _prefs.setBool(StorageKeys.isOnboardingComplete, complete);
  }

  bool isOnboardingComplete() {
    return _prefs.getBool(StorageKeys.isOnboardingComplete) ?? false;
  }

  // Privacy consent
  Future<bool> setPrivacyConsent({
    required bool given,
    required DateTime timestamp,
  }) async {
    final success1 =
        await _prefs.setBool(StorageKeys.privacyConsentGiven, given);
    final success2 = await _prefs.setString(
      StorageKeys.privacyConsentTimestamp,
      timestamp.toIso8601String(),
    );
    return success1 && success2;
  }

  bool? getPrivacyConsent() {
    return _prefs.getBool(StorageKeys.privacyConsentGiven);
  }

  DateTime? getPrivacyConsentTimestamp() {
    final timestamp = _prefs.getString(StorageKeys.privacyConsentTimestamp);
    if (timestamp == null) return null;
    return DateTime.tryParse(timestamp);
  }

  // Last sync
  Future<bool> setLastSyncTimestamp(DateTime timestamp) async {
    return await _prefs.setString(
      StorageKeys.lastSyncTimestamp,
      timestamp.toIso8601String(),
    );
  }

  DateTime? getLastSyncTimestamp() {
    final timestamp = _prefs.getString(StorageKeys.lastSyncTimestamp);
    if (timestamp == null) return null;
    return DateTime.tryParse(timestamp);
  }

  // Clear all local data (logout)
  Future<bool> clearAll() async {
    return await _prefs.clear();
  }
}
