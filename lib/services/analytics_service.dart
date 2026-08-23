import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:homework_app/models/homework.dart';
import 'package:homework_app/utils/task_inventory.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AnalyticsService {
  AnalyticsService._();

  static const String _firstTaskCreatedKey = 'analytics_first_task_created';
  static const String _firstTaskCompletedKey = 'analytics_first_task_completed';
  static const Duration _analyticsSessionTimeout = Duration(minutes: 30);
  static DateTime? _lastSessionInventorySnapshotAt;

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
    final now = DateTime.now();
    if (oncePerSession &&
        _lastSessionInventorySnapshotAt != null &&
        now.difference(_lastSessionInventorySnapshotAt!) <
            _analyticsSessionTimeout) {
      return;
    }
    if (oncePerSession) _lastSessionInventorySnapshotAt = now;

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

  static Future<void> logBannerConfigurationApplied({
    required bool showBannerAd,
  }) async {
    final variant = showBannerAd ? 'banner_enabled' : 'banner_disabled';
    try {
      await FirebaseAnalytics.instance.setUserProperty(
        name: 'banner_test_group',
        value: variant,
      );
    } catch (error) {
      debugPrint('[Analytics] Could not update banner test group: $error');
    }
    await _logEvent(
      'banner_config_applied',
      parameters: {
        'banner_enabled': showBannerAd ? 1 : 0,
        'banner_variant': variant,
      },
    );
  }

  static Future<void> logOnboardingStarted({required bool isReplay}) async {
    final parameters = {'is_replay': isReplay ? 1 : 0};
    await _logEvent('onboarding_started', parameters: parameters);
  }

  static Future<void> logOnboardingCompleted({required bool isReplay}) =>
      isReplay
      ? _logEvent('onboarding_replay_completed')
      : _logEvent('onboarding_completed');

  static Future<void> logOnboardingSkipped({required bool isReplay}) =>
      _logEvent(
        'onboarding_skipped',
        parameters: {'is_replay': isReplay ? 1 : 0},
      );

  static Future<void> logFirstTaskSetupStarted() =>
      _logEvent('first_task_setup_started');

  static Future<void> logFirstTaskSetupAbandoned() =>
      _logEvent('first_task_setup_abandoned');

  static Future<void> logOnboardingReplayAbandoned() =>
      _logEvent('onboarding_replay_abandoned');
}
