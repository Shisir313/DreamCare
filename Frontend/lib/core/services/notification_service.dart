import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize timezone
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Kathmandu'));

    // Android settings
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    final initialized = await _notifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    if (initialized != true) {
      print('Failed to initialize notifications');
    }

    // Request permissions
    await _requestPermissions();
    _isInitialized = true;
  }

  Future<void> _requestPermissions() async {
    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    await _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  void _onNotificationTap(NotificationResponse response) {
    // Handle notification tap - navigate to water tracking screen
    print('Notification tapped: ${response.payload}');
  }

  // Schedule daily water reminders (every 2 hours from 9 AM to 9 PM)
  Future<void> scheduleWaterReminders() async {
    await _notifications.cancelAll(); // Clear existing

    final reminderTimes = [
      9, // 9 AM
      11, // 11 AM
      13, // 1 PM
      15, // 3 PM
      17, // 5 PM
      19, // 7 PM
      21, // 9 PM
    ];

    for (int i = 0; i < reminderTimes.length; i++) {
      await _scheduleDailyNotification(
        id: i,
        hour: reminderTimes[i],
        minute: 0,
      );
    }
  }

  Future<void> _scheduleDailyNotification({
    required int id,
    required int hour,
    required int minute,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'water_reminder',
      'Water Reminders',
      channelDescription: 'Reminders to drink water throughout the day',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Get motivational messages
    final messages = _getMotivationalMessages();
    final message = messages[id % messages.length];

    await _notifications.zonedSchedule(
      id: id,
      title: '💧 Time to Hydrate!',
      body: message,
      scheduledDate: _nextInstanceOfTime(hour, minute),
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'water_reminder',
    );
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  List<String> _getMotivationalMessages() {
    return [
      'Stay hydrated for glowing skin! 🌟',
      'Your skin needs water. Drink up! 💦',
      'Hydration is the key to healthy skin! ✨',
      'Time for a water break! Keep that skin glowing! 🌊',
      'Don\'t forget to drink water! Your skin will thank you! 💧',
      'Healthy skin starts with hydration! Drink water now! 🥤',
      'Keep your skin fresh! Time to hydrate! 🌿',
    ];
  }

  // Show immediate notification (when glass is completed)
  Future<void> showGlassCompletedNotification(int glassNumber) async {
    const androidDetails = AndroidNotificationDetails(
      'water_achievement',
      'Water Achievements',
      channelDescription: 'Notifications for water drinking milestones',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      id: 1000 + glassNumber,
      title: '🎉 Great Job!',
      body: 'You completed glass $glassNumber of 8! Keep it up!',
      notificationDetails: details,
    );
  }

  Future<void> showGoalReachedNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'water_achievement',
      'Water Achievements',
      channelDescription: 'Notifications for water drinking milestones',
      importance: Importance.max,
      priority: Priority.max,
      enableVibration: true,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      id: 2000,
      title: '🎉🎉 Amazing! Goal Reached! 🎉🎉',
      body: 'You drank all 8 glasses today! Your skin is thanking you! 💧✨',
      notificationDetails: details,
    );
  }

  Future<void> cancelAllReminders() async {
    await _notifications.cancelAll();
  }
}
