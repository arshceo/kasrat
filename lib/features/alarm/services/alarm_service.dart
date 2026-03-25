import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';

/// Service to handle background alarms and notifications
class AlarmService {
  static final FlutterLocalNotificationsPlugin notificationsPlugin = FlutterLocalNotificationsPlugin();
  
  static Future<void> initialize() async {
    // Initialize Alarm Manager
    await AndroidAlarmManager.initialize();

    // Initialize Local Notifications
    const initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
    
    await notificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // We handle navigation in main.dart on app launch to ensure router is ready
      },
    );

    // Create Notification Channel for Alarms
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'ustad_alarm_channel', 
      'Ustad Protocol Alarms',
      description: 'Used for waking you up. Non-negotiable.',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  static Future<void> scheduleAlarm(DateTime time) async {
    await AndroidAlarmManager.oneShotAt(
      time,
      0, // alarm ID
      _alarmCallback,
      exact: true,
      wakeup: true,
      rescheduleOnReboot: true,
    );
  }

  static Future<void> cancelAlarm() async {
    await AndroidAlarmManager.cancel(0);
    await notificationsPlugin.cancel(id: 0);
  }

  @pragma('vm:entry-point')
  static Future<void> _alarmCallback() async {
    // Runs in isolate. Fire notification with fullScreenIntent.
    final FlutterLocalNotificationsPlugin plugin = FlutterLocalNotificationsPlugin();
    
    const androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'ustad_alarm_channel',
      'Ustad Protocol Alarms',
      channelDescription: 'Used for waking you up. Non-negotiable.',
      importance: Importance.max,
      priority: Priority.max,
      fullScreenIntent: true,
      ongoing: true,
      autoCancel: false,
      enableVibration: true,
      visibility: NotificationVisibility.public,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction('WAKE_UP', 'COMMENCE DRILL', showsUserInterface: true),
      ]
    );

    const platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
    
    await plugin.show(
      id: 0,
      title: 'USTAD PROTOCOL INITIATED',
      body: 'WAKE UP! GET TO THE CONSOLE!',
      notificationDetails: platformChannelSpecifics,
      payload: 'alarm_fired',
    );
  }
}
