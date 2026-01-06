import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String dailyReminderChannelId = 'daily_reminder_channel';
  static const String dailyReminderChannelName = 'Daily Reminders';
  static const String dailyReminderChannelDescription = 'Daily finance reminder notifications';
  static const int dailyReminderId = 1;

  Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('app_icon');

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
    );

    // Create the notification channel for Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      dailyReminderChannelId,
      dailyReminderChannelName,
      description: dailyReminderChannelDescription,
      importance: Importance.high,
      playSound: true,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> showNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'your channel id',
      'your channel name',
      channelDescription: 'your channel description',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
      payload: 'item x',
    );
  }

  Future<void> scheduleDailyReminder(int hour, int minute) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // If the time has already passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      dailyReminderChannelId,
      dailyReminderChannelName,
      channelDescription: dailyReminderChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      dailyReminderId,
      'Daily Finance Reminder',
      'Don\'t forget to check your finances today!',
      scheduledDate,
      platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time, // Repeat daily at the same time
    );
  }

  Future<void> cancelDailyReminder() async {
    await flutterLocalNotificationsPlugin.cancel(dailyReminderId);
  }
}
