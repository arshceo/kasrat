import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';

// ----------------------------------------------------------------------
// THE ISOLATE BRIDGE (Must be top-level, absolutely outside any class)
// ----------------------------------------------------------------------
@pragma('vm:entry-point')
void topLevelAlarmCallback() async {
  // 1. Initialize Flutter for background execution
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialize the service to get notification channels ready
  await AlarmService.initialize();

  // 3. Fire the Full Screen Intent (Wakes the screen)
  await AlarmService.triggerFullScreenIntent();

  // 4. Reschedule for tomorrow
  try {
    await Hive.initFlutter();
    await Hive.openBox('alarm_settings');
    var box = Hive.box('alarm_settings');
    bool isActive = box.get('is_active', defaultValue: false);

    if (isActive) {
      int hour = box.get('hour', defaultValue: 5);
      int minute = box.get('minute', defaultValue: 0);
      DateTime now = DateTime.now();
      DateTime nextTime = DateTime(now.year, now.month, now.day, hour, minute);

      if (nextTime.isBefore(now.add(const Duration(minutes: 1)))) {
        nextTime = nextTime.add(const Duration(days: 1));
      }

      // Reschedule using THIS SAME top-level function
      await AndroidAlarmManager.oneShotAt(
        nextTime,
        0,
        topLevelAlarmCallback,
        exact: true,
        wakeup: true,
        rescheduleOnReboot: true,
      );
    }
  } catch (e) {
    debugPrint("Failed to reschedule tomorrow's alarm: $e");
  }
}
// ----------------------------------------------------------------------

/// Service to handle background alarms and notifications
class AlarmService {
  static final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    await AndroidAlarmManager.initialize();

    const initializationSettingsAndroid = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await notificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handled in main.dart router
      },
    );

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'ustad_alarm_channel_v2',
      'Ustad Protocol Alarms',
      description: 'Used for waking you up. Non-negotiable.',
      importance: Importance.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('alarm'),
      enableVibration: true,
    );

    await notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  static Future<void> rescheduleAlarmFromHive() async {
    var box = Hive.box('alarm_settings');
    bool isActive = box.get('is_active', defaultValue: false);
    if (!isActive) return;

    int hour = box.get('hour', defaultValue: 5);
    int minute = box.get('minute', defaultValue: 0);

    await _scheduleInternal(hour, minute);
  }

  static Future<void> setDailyAlarm(int hour, int minute) async {
    var box = Hive.box('alarm_settings');
    await box.put('is_active', true);
    await box.put('hour', hour);
    await box.put('minute', minute);

    await _scheduleInternal(hour, minute);
  }

  static Future<void> _scheduleInternal(int hour, int minute) async {
    DateTime now = DateTime.now();
    DateTime scheduledTime = DateTime(
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    // THIS IS THE CRITICAL FIX: Passing the top-level callback
    await AndroidAlarmManager.oneShotAt(
      scheduledTime,
      0, // alarm ID
      topLevelAlarmCallback,
      exact: true,
      wakeup: true,
      rescheduleOnReboot: true,
    );
  }

  static Future<void> cancelAlarm() async {
    await AndroidAlarmManager.cancel(0);
    await notificationsPlugin.cancel(id: 0);
    var box = Hive.box('alarm_settings');
    await box.put('is_active', false);
  }

  static Future<void> triggerFullScreenIntent() async {
    const androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'ustad_alarm_channel_v2',
      'Ustad Protocol Alarms',
      channelDescription: 'Used for waking you up. Non-negotiable.',
      importance: Importance.max,
      priority: Priority.max,
      fullScreenIntent: true,
      ongoing: true,
      autoCancel: false,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('alarm'),
      enableVibration: true,
      visibility: NotificationVisibility.public,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          'WAKE_UP',
          'COMMENCE DRILL',
          showsUserInterface: true,
        ),
      ],
    );

    const platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await notificationsPlugin.show(
      id: 0,
      title: 'USTAD PROTOCOL INITIATED',
      body: 'WAKE UP! GET TO THE CONSOLE!',
      notificationDetails: platformChannelSpecifics,
      payload: 'alarm_fired',
    );
  }
}
