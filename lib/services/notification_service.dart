import 'dart:async';
import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';
import 'package:homework_app/services/analytics_service.dart';
import 'package:homework_app/utils/date_formatter.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/material.dart';
import 'package:homework_app/models/homework.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String notificationChannelId = 'homework_channel_id_max_priority';
const String _exactAlarmPermissionRequestedKey =
    'exact_alarm_permission_requested';
late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

class NotificationService {
  static Future<bool?>? _notificationPermissionRequest;

  static Future<void> initializeNotifications() async {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('icon_app');

    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (_) {
        unawaited(AnalyticsService.logNotificationOpened());
      },
    );

    final launchDetails = await flutterLocalNotificationsPlugin
        .getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp ?? false) {
      unawaited(AnalyticsService.logNotificationOpened());
    }

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

  static Future<bool?> requestNotificationsPermission() {
    final pendingRequest = _notificationPermissionRequest;
    if (pendingRequest != null) return pendingRequest;

    final request = _requestNotificationsPermission();
    _notificationPermissionRequest = request;
    request.whenComplete(() {
      if (identical(_notificationPermissionRequest, request)) {
        _notificationPermissionRequest = null;
      }
    });
    return request;
  }

  static Future<bool?> _requestNotificationsPermission() async {
    try {
      final androidPlatform = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final notificationGranted = await androidPlatform
          ?.requestNotificationsPermission();

      if (notificationGranted != false &&
          await androidPlatform?.canScheduleExactNotifications() == false) {
        final prefs = await SharedPreferences.getInstance();
        final alreadyRequested =
            prefs.getBool(_exactAlarmPermissionRequestedKey) ?? false;
        if (!alreadyRequested) {
          await prefs.setBool(_exactAlarmPermissionRequestedKey, true);
          await androidPlatform?.requestExactAlarmsPermission();
        }
      }

      return notificationGranted;
    } on PlatformException catch (error) {
      // Android rejects concurrent runtime permission dialogs. A request can
      // already be active after a rapid double tap or another plugin prompt.
      // The task can still be saved; permission may be requested again later.
      debugPrint('Notification permission request failed: $error');
      return null;
    } catch (error) {
      // A permission prompt must never prevent the task itself from being
      // created. Future attempts can request the permission again.
      debugPrint('Unexpected notification permission error: $error');
      return null;
    }
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

    Future<void> schedule(AndroidScheduleMode scheduleMode) =>
        flutterLocalNotificationsPlugin.zonedSchedule(
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
          payload: homework.id,
          androidScheduleMode: scheduleMode,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );

    var scheduleMode = AndroidScheduleMode.inexactAllowWhileIdle;
    try {
      final canScheduleExact = await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.canScheduleExactNotifications();
      if (canScheduleExact == true) {
        scheduleMode = AndroidScheduleMode.exactAllowWhileIdle;
      }
    } catch (error) {
      debugPrint('Could not check exact alarm permission: $error');
    }

    try {
      await schedule(scheduleMode);
      debugPrint(
        "Notification scheduled for: $scheduledDate (Due: ${homework.dueDate})",
      );
    } on PlatformException catch (error) {
      if (scheduleMode == AndroidScheduleMode.exactAllowWhileIdle) {
        try {
          await schedule(AndroidScheduleMode.inexactAllowWhileIdle);
          debugPrint(
            'Exact alarm was unavailable; notification scheduled inexactly.',
          );
          return;
        } catch (fallbackError) {
          debugPrint('Error scheduling fallback notification: $fallbackError');
          return;
        }
      }
      debugPrint('Error scheduling notification: $error');
    } catch (error) {
      debugPrint('Error scheduling notification: $error');
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
