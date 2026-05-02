import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/material.dart';
import 'package:homework_app/models/homework.dart';

const String notificationChannelId = 'homework_channel_id';
late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

class NotificationService {
  static Future<void> initializeNotifications() async {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('icon_app');

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      notificationChannelId,
      'Homework Notifications',
      description: 'Notifications for upcoming homework assignments',
      importance: Importance.high,
      playSound: true,
    );

    final androidPlatform = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlatform?.createNotificationChannel(channel);
  }

  static void requestNotificationsPermission() {
    flutterLocalNotificationsPlugin
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

    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        notificationId,
        'Upcoming assignment: ${homework.title}',
        'Due ${DateFormat('MMM dd, hh:mm a').format(homework.dueDate)}',
        tz.TZDateTime.from(scheduledDate, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            notificationChannelId,
            'Homework Notifications',
            channelDescription: 'Notifications for upcoming homework tasks',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            color: Colors.blue,
          ),
        ),
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      print(
        "Notification scheduled for: $scheduledDate (Due: ${homework.dueDate})",
      );
    } catch (e) {
      print("Error scheduling notification: $e");
    }
  }

  static Future<void> schedulePendingNotifications(List<Homework> allTasks) async {
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
