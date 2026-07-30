import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homework_app/services/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('dexterous.com/flutter/local_notifications');

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
}
