import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/settings_model.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._init();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  NotificationService._init();

  Future<void> init() async {
    if (_initialized) return;

    // 1. Initialize time zones
    tz.initializeTimeZones();
    // In Flutter, we can try to guess the device's timezone
    // The package 'flutter_timezone' is normally used to get native timezone,
    // but since it's not in our dependencies, we can fall back to local timezone database logic
    // or set a default timezone if estimation fails.
    // Timezone local can be set using tz.local = tz.getLocation('GMT'); or similar.
    // By default, timezone library's tz.local is initialized to UTC. Let's see:
    try {
      // In timezone 0.10.x, tz.local is set to UTC by default.
      // We can try to set it or configure it. We will use UTC fallback or local if possible.
      // To be extremely safe, we will grab the device offset or just schedule based on local timezone
      // using DateTime.now().timeZoneName.
      // Let's do a timezone lookup:
      final String timeZoneName = DateTime.now().timeZoneName;
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (_) {
      // Fallback if local location lookup fails (e.g. on web or unsupported timezone name format)
      // Usually on iOS and Android, timezone names like 'America/New_York' work.
      // Let's fall back to UTC or try to find a matching location.
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    // 2. Configure Android & iOS initialization settings
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _initialized = true;
  }

  void _onNotificationTapped(NotificationResponse response) {
    if (kDebugMode) {
      print('Notification tapped: ${response.payload}');
    }
  }

  /// Request permissions dynamically
  Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _localNotifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      final bool? grantedNotification =
          await androidImplementation?.requestNotificationsPermission();
      final bool? grantedExactAlarm =
          await androidImplementation?.requestExactAlarmsPermission();
      return (grantedNotification ?? false) && (grantedExactAlarm ?? false);
    } else if (Platform.isIOS) {
      final bool? granted = await _localNotifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      return granted ?? false;
    }
    return false;
  }

  /// Cancel all scheduled reminders
  Future<void> cancelAllReminders() async {
    await _localNotifications.cancelAll();
  }

  /// Schedule window-aware reminders for the next 3 days
  Future<void> scheduleWindowReminders(HydrioSettings settings) async {
    // Always clear existing reminders first to avoid overlap/duplication
    await cancelAllReminders();

    if (!settings.notificationsOn) {
      return;
    }

    final localLocation = tz.local;
    final now = tz.TZDateTime.now(localLocation);

    // Parse wake and sleep times
    final wakeParts = settings.wakeTime.split(':');
    final sleepParts = settings.sleepTime.split(':');

    if (wakeParts.length != 2 || sleepParts.length != 2) return;

    final wakeHour = int.parse(wakeParts[0]);
    final wakeMin = int.parse(wakeParts[1]);
    final sleepHour = int.parse(sleepParts[0]);
    final sleepMin = int.parse(sleepParts[1]);

    // Create Notification details
    final androidDetails = AndroidNotificationDetails(
      settings.silentReminders
          ? 'hydrio_reminders_silent'
          : 'hydrio_reminders_loud',
      settings.silentReminders
          ? 'Hydrio Silent Reminders'
          : 'Hydrio Reminders',
      channelDescription: settings.silentReminders
          ? 'Silent notification reminders to drink water'
          : 'Loud notification reminders to drink water',
      importance: settings.silentReminders ? Importance.low : Importance.high,
      priority: settings.silentReminders ? Priority.low : Priority.high,
      playSound: !settings.silentReminders,
      enableVibration: !settings.silentReminders,
    );

    final iosDetails = DarwinNotificationDetails(
      presentSound: !settings.silentReminders,
      presentAlert: true,
      presentBadge: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    int notificationId = 1; // Auto-incrementing IDs for unique notifications

    // Encouraging reminder messages (encouraging tone!)
    final reminderMessages = [
      "Time for a quick sip! Keep up the good work. 💧",
      "A fresh glass of water is waiting. You're doing great! 🥤",
      "Stay refreshed, stay energized! Let's take a water break. ✨",
      "Keep that hydration streak going! Your body will thank you. 🌟",
      "Hydration is key! Great progress so far, let's keep it up. 😊",
      "Time to top off! Every sip brings you closer to your goal. 🚀",
    ];

    // Loop through the next 3 days (today, tomorrow, day after)
    for (int dayOffset = 0; dayOffset < 3; dayOffset++) {
      final targetDate = now.add(Duration(days: dayOffset));

      // Construct wake and sleep date times for that specific day
      final wakeDateTime = tz.TZDateTime(
        localLocation,
        targetDate.year,
        targetDate.month,
        targetDate.day,
        wakeHour,
        wakeMin,
      );

      final sleepDateTime = tz.TZDateTime(
        localLocation,
        targetDate.year,
        targetDate.month,
        targetDate.day,
        sleepHour,
        sleepMin,
      );

      // If sleep time is configured before wake time (e.g. overnight shifts)
      // shift sleep time to the next day
      var adjustedSleepDateTime = sleepDateTime;
      if (sleepDateTime.isBefore(wakeDateTime)) {
        adjustedSleepDateTime = sleepDateTime.add(const Duration(days: 1));
      }

      // Schedule logs inside this window
      var scheduledTime = wakeDateTime;

      // Ensure we don't schedule notifications in the past
      if (scheduledTime.isBefore(now)) {
        // Find the first slot after now
        final differenceInMinutes = now.difference(wakeDateTime).inMinutes;
        final elapsedIntervals = (differenceInMinutes / settings.reminderIntervalMin).ceil();
        scheduledTime = wakeDateTime.add(
          Duration(minutes: elapsedIntervals * settings.reminderIntervalMin),
        );
      }

      while (scheduledTime.isBefore(adjustedSleepDateTime) ||
          scheduledTime.isAtSameMomentAs(adjustedSleepDateTime)) {
        // Double check this is still in the future
        if (scheduledTime.isAfter(now)) {
          final message = reminderMessages[notificationId % reminderMessages.length];
          try {
            await _localNotifications.zonedSchedule(
              notificationId,
              'Hydrio Reminder',
              message,
              scheduledTime,
              notificationDetails,
              androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
              uiLocalNotificationDateInterpretation:
                  UILocalNotificationDateInterpretation.absoluteTime,
            );
            notificationId++;
            // Protect against exceeding the 64-notification limit
            if (notificationId >= 60) {
              return;
            }
          } catch (e) {
            if (kDebugMode) {
              print('Failed to schedule notification $notificationId at $scheduledTime: $e');
            }
          }
        }
        scheduledTime = scheduledTime.add(Duration(minutes: settings.reminderIntervalMin));
      }
    }
  }
}
