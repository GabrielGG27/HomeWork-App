import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:homework_app/models/homework.dart';
import 'package:homework_app/utils/task_inventory.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AnalyticsService {
  AnalyticsService._();

  static const String _firstTaskCreatedKey = 'analytics_first_task_created';
  static const String _firstTaskCompletedKey = 'analytics_first_task_completed';
  static bool _didLogSessionInventorySnapshot = false;

  static Map<String, Object> _taskParameters(Homework homework) => {
    'has_due_date': homework.hasDueDate ? 1 : 0,
    'notification_enabled': homework.enableNotification ? 1 : 0,
    'notification_count': homework.notificationOffsets.length,
    'is_important': homework.isImportant ? 1 : 0,
    'attachment_count': homework.attachments.length,
  };

  static Future<void> _logEvent(
    String name, {
    Map<String, Object>? parameters,
  }) async {
    try {
      await FirebaseAnalytics.instance.logEvent(
        name: name,
        parameters: parameters,
      );
    } catch (error) {
      debugPrint('[Analytics] Could not log $name: $error');
    }
  }

  static Future<void> logTaskCreated(
    Homework homework, {
    required bool isFirstTask,
  }) async {
    final parameters = _taskParameters(homework);
    await _logEvent('crear_tarea', parameters: parameters);

    final prefs = await SharedPreferences.getInstance();
    final alreadyLogged = prefs.getBool(_firstTaskCreatedKey) ?? false;
    if (!alreadyLogged && isFirstTask) {
      await prefs.setBool(_firstTaskCreatedKey, true);
      await _logEvent('first_task_created', parameters: parameters);
    }
  }

  static Future<void> logTaskCompleted(
    Homework homework, {
    required bool hasPreviousCompletedTasks,
  }) async {
    final parameters = _taskParameters(homework);
    await _logEvent('task_completed', parameters: parameters);

    final prefs = await SharedPreferences.getInstance();
    final alreadyLogged = prefs.getBool(_firstTaskCompletedKey) ?? false;
    if (!alreadyLogged && !hasPreviousCompletedTasks) {
      await prefs.setBool(_firstTaskCompletedKey, true);
      await _logEvent('first_task_completed', parameters: parameters);
    }
  }

  static Future<void> logTaskInventorySnapshot(
    Iterable<Homework> tasks, {
    required String reason,
    bool oncePerSession = false,
  }) async {
    if (oncePerSession && _didLogSessionInventorySnapshot) return;
    if (oncePerSession) _didLogSessionInventorySnapshot = true;

    final inventory = TaskInventory.fromTasks(tasks);
    await _logEvent(
      'task_list_snapshot',
      parameters: {
        'pending_task_count': inventory.pending,
        'completed_task_count': inventory.completed,
        'snapshot_reason': reason,
      },
    );

    try {
      await Future.wait([
        FirebaseAnalytics.instance.setUserProperty(
          name: 'pending_task_bucket',
          value: TaskInventory.bucketFor(inventory.pending),
        ),
        FirebaseAnalytics.instance.setUserProperty(
          name: 'completed_task_bucket',
          value: TaskInventory.bucketFor(inventory.completed),
        ),
      ]);
    } catch (error) {
      debugPrint('[Analytics] Could not update task count buckets: $error');
    }
  }

  static Future<void> logNotificationOpened() =>
      _logEvent('notification_opened');

  static Future<void> logOnboardingStarted({required bool isReplay}) async {
    final parameters = {'is_replay': isReplay ? 1 : 0};
    await _logEvent('onboarding_started', parameters: parameters);
  }

  static Future<void> logOnboardingCompleted({required bool isReplay}) =>
      _logEvent(
        'onboarding_completed',
        parameters: {'is_replay': isReplay ? 1 : 0},
      );

  static Future<void> logOnboardingSkipped({required bool isReplay}) =>
      _logEvent(
        'onboarding_skipped',
        parameters: {'is_replay': isReplay ? 1 : 0},
      );

  static Future<void> logFirstTaskSetupStarted() =>
      _logEvent('first_task_setup_started');

  static Future<void> logFirstTaskSetupAbandoned() =>
      _logEvent('first_task_setup_abandoned');
}
