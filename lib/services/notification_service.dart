import 'dart:async';
import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';
import 'package:homework_app/services/analytics_service.dart';
import 'package:homework_app/services/homework_service.dart';
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
  static Future<void> _operationQueue = Future<void>.value();
  static bool _didInitialReconciliation = false;

  static Future<void> _enqueue(Future<void> Function() operation) {
    final queuedOperation = _operationQueue.then((_) => operation());
    _operationQueue = queuedOperation.catchError((Object error) {
      debugPrint('Notification operation failed: $error');
    });
    return queuedOperation;
  }

  static int _legacyNotificationId(String homeworkId) =>
      homeworkId.hashCode & 0x7FFFFFFF;

  static int _notificationId(String homeworkId, int reminderIndex) {
    final base = homeworkId.hashCode & 0x3FFFFFFF;
    return ((base << 1) | reminderIndex) & 0x7FFFFFFF;
  }

  static bool reminderTimesAreInFuture({
    required DateTime dueDate,
    required Iterable<int> offsets,
    DateTime? now,
  }) {
    final reference = now ?? DateTime.now();
    return offsets.every(
      (minutes) =>
          dueDate.subtract(Duration(minutes: minutes)).isAfter(reference),
    );
  }

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

  static Future<void> scheduleNotification(Homework homework) =>
      _enqueue(() => _scheduleNotification(homework));

  static Future<void> _scheduleNotification(Homework homework) async {
    // Clear the previous version's single ID and both current reminder slots.
    // This prevents orphan notifications after editing an offset or disabling a
    // reminder.
    await _cancelNotification(homework.id);

    if (!homework.hasDueDate ||
        homework.isCompleted ||
        homework.isDeleted ||
        !homework.enableNotification) {
      return;
    }

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

    Future<void> schedule({
      required int notificationId,
      required DateTime scheduledDate,
      required AndroidScheduleMode scheduleMode,
    }) => flutterLocalNotificationsPlugin.zonedSchedule(
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

    final now = DateTime.now();
    for (final reminder in homework.notificationOffsets.indexed) {
      final reminderIndex = reminder.$1;
      final scheduledDate = homework.dueDate.subtract(
        Duration(minutes: reminder.$2),
      );
      if (!scheduledDate.isAfter(now)) continue;

      final notificationId = _notificationId(homework.id, reminderIndex);
      try {
        await schedule(
          notificationId: notificationId,
          scheduledDate: scheduledDate,
          scheduleMode: scheduleMode,
        );
        debugPrint(
          'Notification scheduled for: $scheduledDate '
          '(Due: ${homework.dueDate})',
        );
      } on PlatformException catch (error) {
        if (scheduleMode == AndroidScheduleMode.exactAllowWhileIdle) {
          try {
            await schedule(
              notificationId: notificationId,
              scheduledDate: scheduledDate,
              scheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            );
            debugPrint(
              'Exact alarm was unavailable; notification scheduled inexactly.',
            );
            continue;
          } catch (fallbackError) {
            debugPrint(
              'Error scheduling fallback notification: $fallbackError',
            );
            continue;
          }
        }
        debugPrint('Error scheduling notification: $error');
      } catch (error) {
        debugPrint('Error scheduling notification: $error');
      }
    }
  }

  static Future<void> schedulePendingNotifications(
    List<Homework> allTasks, {
    bool oncePerProcess = false,
  }) => _reconcileNotifications(
    () => Future<List<Homework>>.value(allTasks),
    oncePerProcess: oncePerProcess,
  );

  static Future<void> reconcileStoredNotifications({
    bool oncePerProcess = false,
  }) => _reconcileNotifications(
    HomeworkService.loadHomework,
    oncePerProcess: oncePerProcess,
  );

  static Future<void> _reconcileNotifications(
    Future<List<Homework>> Function() loadTasks, {
    required bool oncePerProcess,
  }) {
    if (oncePerProcess && _didInitialReconciliation) {
      return Future<void>.value();
    }
    if (oncePerProcess) _didInitialReconciliation = true;

    final reconciliation = _enqueue(() async {
      // Read storage inside the queue so a cancellation or edit that was
      // already queued cannot be followed by an older in-memory snapshot.
      final allTasks = await loadTasks();
      // Reconcile every stored task. _scheduleNotification first removes all
      // legacy/current IDs, and only recreates reminders for eligible tasks.
      // This also cleans up alarms left behind by completed or deleted tasks.
      for (final task in allTasks) {
        await _scheduleNotification(task);
      }
    });
    if (!oncePerProcess) return reconciliation;
    return reconciliation.catchError((Object error, StackTrace stackTrace) {
      _didInitialReconciliation = false;
      Error.throwWithStackTrace(error, stackTrace);
    });
  }

  static Future<void> cancelNotification(String homeworkId) =>
      _enqueue(() => _cancelNotification(homeworkId));

  static Future<void> _cancelNotification(String homeworkId) async {
    final notificationIds = <int>{
      _legacyNotificationId(homeworkId),
      _notificationId(homeworkId, 0),
      _notificationId(homeworkId, 1),
    };
    for (final notificationId in notificationIds) {
      await flutterLocalNotificationsPlugin.cancel(notificationId);
    }
  }
}
