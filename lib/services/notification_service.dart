import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:homework_app/utils/date_formatter.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/material.dart';
import 'package:homework_app/models/homework.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

const String notificationChannelId = 'homework_channel_id_max_priority';
late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

class NotificationService {
  static Future<void> initializeNotifications() async {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('icon_app');

    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      notificationChannelId,
      'Homework Notifications',
      description: 'Notifications for upcoming homework assignments',
      importance: Importance.max,
      playSound: true,
    );

    final androidPlatform = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlatform?.createNotificationChannel(channel);
  }

  static Future<void> requestNotificationsPermission() async {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  static Future<void> scheduleNotification(Homework homework) async {
    if (!homework.enableNotification) {
      final notificationId = homework.id.hashCode & 0x7FFFFFFF;
      await flutterLocalNotificationsPlugin.cancel(notificationId);
      return;
    }

    final scheduledDate = homework.dueDate.subtract(
      Duration(minutes: homework.notificationOffset),
    );
    final now = DateTime.now();

    if (scheduledDate.isBefore(now)) return;

    final notificationId = homework.id.hashCode & 0x7FFFFFFF;

    final prefs = await SharedPreferences.getInstance();
    final langCode =
        prefs.getString('languageCode') ?? Platform.localeName.split('_')[0];
    final isEs = langCode == 'es';

    final upcomingStr = isEs
        ? 'Próxima tarea: ${homework.title}'
        : 'Upcoming assignment: ${homework.title}';
    final smartDate = SmartDateFormatter.formatForNotification(
      homework.dueDate,
      isSpanish: isEs,
    );
    final dueStr = isEs ? 'Entrega $smartDate' : 'Due $smartDate';

    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        notificationId,
        upcomingStr,
        dueStr,
        tz.TZDateTime.local(
          scheduledDate.year,
          scheduledDate.month,
          scheduledDate.day,
          scheduledDate.hour,
          scheduledDate.minute,
          scheduledDate.second,
        ),
        NotificationDetails(
          android: AndroidNotificationDetails(
            notificationChannelId,
            'Homework Notifications',
            channelDescription: 'Notifications for upcoming homework tasks',
            importance: Importance.max,
            priority: Priority.max,
            playSound: true,
            color: Colors.blue,
            styleInformation: BigTextStyleInformation(
              homework.description.isNotEmpty ? homework.description : dueStr,
              contentTitle: upcomingStr,
            ),
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      debugPrint(
        "Notification scheduled for: $scheduledDate (Due: ${homework.dueDate})",
      );
    } catch (e) {
      debugPrint("Error scheduling notification: $e");
    }
  }

  static Future<void> schedulePendingNotifications(
    List<Homework> allTasks,
  ) async {
    final pendingTasks = allTasks.where((task) => !task.isCompleted).toList();
    for (final task in pendingTasks) {
      await scheduleNotification(task);
    }
  }

  static Future<void> cancelNotification(String homeworkId) async {
    final notificationId = homeworkId.hashCode & 0x7FFFFFFF;
    await flutterLocalNotificationsPlugin.cancel(notificationId);
  }
}
