import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/water_tracking.dart';
import '../../../../core/services/notification_service.dart';

part 'water_tracking_provider.g.dart';

@Riverpod(keepAlive: true)
class WaterTrackingNotifier extends _$WaterTrackingNotifier {
  static const String _storageKey = 'water_tracking_data';
  late SharedPreferences _prefs;
  late NotificationService _notificationService;

  @override
  Future<WaterTracking> build() async {
    _prefs = await SharedPreferences.getInstance();
    _notificationService = NotificationService();
    await _notificationService.initialize();
    return _loadTodayData();
  }

  WaterTracking _loadTodayData() {
    final today = DateTime.now();
    final todayKey = '${today.year}-${today.month}-${today.day}';
    final json = _prefs.getString('${_storageKey}_$todayKey');

    if (json != null) {
      try {
        return WaterTracking.fromJson(jsonDecode(json));
      } catch (e) {
        print('Error loading water tracking data: $e');
      }
    }

    return WaterTracking(date: today, glassesCompleted: 0, timestamps: []);
  }

  Future<void> addGlass() async {
    final current = await future;

    if (current.glassesCompleted >= current.dailyGoal) {
      return; // Already reached goal
    }

    final updated = current.copyWith(
      glassesCompleted: current.glassesCompleted + 1,
      timestamps: [...current.timestamps, DateTime.now()],
    );

    await _saveData(updated);
    state = AsyncData(updated);

    // Show achievement notification
    await _notificationService.showGlassCompletedNotification(
      updated.glassesCompleted,
    );

    // Special notification when goal reached
    if (updated.goalReached) {
      await _notificationService.showGoalReachedNotification();
    }
  }

  Future<void> removeGlass() async {
    final current = await future;

    if (current.glassesCompleted <= 0) {
      return;
    }

    final updated = current.copyWith(
      glassesCompleted: current.glassesCompleted - 1,
      timestamps: current.timestamps.sublist(0, current.timestamps.length - 1),
    );

    await _saveData(updated);
    state = AsyncData(updated);
  }

  Future<void> _saveData(WaterTracking data) async {
    final todayKey = '${data.date.year}-${data.date.month}-${data.date.day}';
    await _prefs.setString(
      '${_storageKey}_$todayKey',
      jsonEncode(data.toJson()),
    );
  }

  Future<void> enableReminders() async {
    await _notificationService.scheduleWaterReminders();
    await _prefs.setBool('water_reminders_enabled', true);
  }

  Future<void> disableReminders() async {
    await _notificationService.cancelAllReminders();
    await _prefs.setBool('water_reminders_enabled', false);
  }

  bool get remindersEnabled {
    return _prefs.getBool('water_reminders_enabled') ?? false;
  }
}
