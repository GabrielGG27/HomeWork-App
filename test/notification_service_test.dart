import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homework_app/models/homework.dart';
import 'package:homework_app/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('dexterous.com/flutter/local_notifications');

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    tz_data.initializeTimeZones();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('coalesces concurrent notification permission requests', () async {
    final permissionResult = Completer<bool>();
    var permissionCalls = 0;

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          switch (call.method) {
            case 'initialize':
              return true;
            case 'getNotificationAppLaunchDetails':
              return <String, Object?>{'notificationLaunchedApp': false};
            case 'createNotificationChannel':
              return null;
            case 'requestNotificationsPermission':
              permissionCalls++;
              return permissionResult.future;
          }
          return null;
        });

    await NotificationService.initializeNotifications();

    final first = NotificationService.requestNotificationsPermission();
    final second = NotificationService.requestNotificationsPermission();
    await Future<void>.delayed(Duration.zero);

    expect(permissionCalls, 1);

    permissionResult.complete(true);
    expect(await first, isTrue);
    expect(await second, isTrue);
  });

  test('does not crash when Android rejects a permission request', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          switch (call.method) {
            case 'initialize':
              return true;
            case 'getNotificationAppLaunchDetails':
              return <String, Object?>{'notificationLaunchedApp': false};
            case 'createNotificationChannel':
              return null;
            case 'requestNotificationsPermission':
              throw PlatformException(
                code: 'permissionRequestInProgress',
                message: 'Another permission request is already in progress',
              );
          }
          return null;
        });

    await NotificationService.initializeNotifications();

    expect(await NotificationService.requestNotificationsPermission(), isNull);
  });

  test('requests exact alarm access at most once', () async {
    var exactPermissionCalls = 0;

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          switch (call.method) {
            case 'initialize':
              return true;
            case 'getNotificationAppLaunchDetails':
              return <String, Object?>{'notificationLaunchedApp': false};
            case 'createNotificationChannel':
              return null;
            case 'requestNotificationsPermission':
              return true;
            case 'canScheduleExactNotifications':
              return false;
            case 'requestExactAlarmsPermission':
              exactPermissionCalls++;
              return false;
          }
          return null;
        });

    await NotificationService.initializeNotifications();
    await NotificationService.requestNotificationsPermission();
    await NotificationService.requestNotificationsPermission();

    expect(exactPermissionCalls, 1);
  });

  test('uses an inexact alarm when exact access is unavailable', () async {
    String? scheduleMode;

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          switch (call.method) {
            case 'initialize':
              return true;
            case 'getNotificationAppLaunchDetails':
              return <String, Object?>{'notificationLaunchedApp': false};
            case 'createNotificationChannel':
              return null;
            case 'canScheduleExactNotifications':
              return false;
            case 'zonedSchedule':
              final arguments = Map<String, dynamic>.from(call.arguments);
              final platformSpecifics = Map<String, dynamic>.from(
                arguments['platformSpecifics'],
              );
              scheduleMode = platformSpecifics['scheduleMode'] as String?;
              return null;
          }
          return null;
        });

    await NotificationService.initializeNotifications();
    await NotificationService.scheduleNotification(
      Homework(
        id: 'future-task',
        title: 'Future task',
        subject: 'Math',
        dueDate: DateTime.now().add(const Duration(days: 1)),
      ),
    );

    expect(scheduleMode, 'inexactAllowWhileIdle');
  });
}
