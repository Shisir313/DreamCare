import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/constants.dart';

/// Provider for local storage service
final localStorageServiceProvider = Provider<LocalStorageService>((ref) {
  return LocalStorageService.inMemory();
});

/// Local storage service for non-sensitive data
/// Uses shared_preferences for persistent storage or in-memory map as fallback
class LocalStorageService {
  LocalStorageService(this._prefs) : _inMemoryMap = null;

  LocalStorageService.inMemory()
      : _prefs = null,
        _inMemoryMap = <String, Object>{};

  final SharedPreferences? _prefs;
  final Map<String, Object>? _inMemoryMap;

  // Theme mode
  Future<bool> setDarkMode(bool isDark) async {
    if (_prefs != null) {
      return await _prefs.setBool(StorageKeys.isDarkMode, isDark);
    }
    _inMemoryMap?[StorageKeys.isDarkMode] = isDark;
    return true;
  }

  bool? getDarkMode() {
    if (_prefs != null) {
      return _prefs.getBool(StorageKeys.isDarkMode);
    }
    return _inMemoryMap?[StorageKeys.isDarkMode] as bool?;
  }

  // Onboarding
  Future<bool> setOnboardingComplete(bool complete) async {
    if (_prefs != null) {
      return await _prefs.setBool(StorageKeys.isOnboardingComplete, complete);
    }
    _inMemoryMap?[StorageKeys.isOnboardingComplete] = complete;
    return true;
  }

  bool isOnboardingComplete() {
    if (_prefs != null) {
      return _prefs.getBool(StorageKeys.isOnboardingComplete) ?? false;
    }
    return (_inMemoryMap?[StorageKeys.isOnboardingComplete] as bool?) ?? false;
  }

  // Privacy consent
  Future<bool> setPrivacyConsent({
    required bool given,
    required DateTime timestamp,
  }) async {
    if (_prefs != null) {
      final success1 =
          await _prefs.setBool(StorageKeys.privacyConsentGiven, given);
      final success2 = await _prefs.setString(
        StorageKeys.privacyConsentTimestamp,
        timestamp.toIso8601String(),
      );
      return success1 && success2;
    }
    _inMemoryMap?[StorageKeys.privacyConsentGiven] = given;
    _inMemoryMap?[StorageKeys.privacyConsentTimestamp] =
        timestamp.toIso8601String();
    return true;
  }

  bool? getPrivacyConsent() {
    if (_prefs != null) {
      return _prefs.getBool(StorageKeys.privacyConsentGiven);
    }
    return _inMemoryMap?[StorageKeys.privacyConsentGiven] as bool?;
  }

  DateTime? getPrivacyConsentTimestamp() {
    final timestamp = _prefs != null
        ? _prefs.getString(StorageKeys.privacyConsentTimestamp)
        : (_inMemoryMap?[StorageKeys.privacyConsentTimestamp] as String?);
    if (timestamp == null) return null;
    return DateTime.tryParse(timestamp);
  }

  // Last sync
  Future<bool> setLastSyncTimestamp(DateTime timestamp) async {
    if (_prefs != null) {
      return await _prefs.setString(
        StorageKeys.lastSyncTimestamp,
        timestamp.toIso8601String(),
      );
    }
    _inMemoryMap?[StorageKeys.lastSyncTimestamp] = timestamp.toIso8601String();
    return true;
  }

  DateTime? getLastSyncTimestamp() {
    final timestamp = _prefs != null
        ? _prefs.getString(StorageKeys.lastSyncTimestamp)
        : (_inMemoryMap?[StorageKeys.lastSyncTimestamp] as String?);
    if (timestamp == null) return null;
    return DateTime.tryParse(timestamp);
  }

  // Clear all local data (logout)
  Future<bool> clearAll() async {
    if (_prefs != null) {
      return await _prefs.clear();
    }
    _inMemoryMap?.clear();
    return true;
  }
}
