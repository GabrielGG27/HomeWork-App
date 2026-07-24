import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:homework_app/models/homework.dart';

class AnalyticsService {
  AnalyticsService._();

  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  static Future<void> logTaskCreated(Homework homework) async {
    try {
      await _analytics.logEvent(
        name: 'crear_tarea',
        parameters: {
          'has_due_date': homework.hasDueDate ? 1 : 0,
          'notification_enabled': homework.enableNotification ? 1 : 0,
          'is_important': homework.isImportant ? 1 : 0,
          'attachment_count': homework.attachments.length,
        },
      );
    } catch (error) {
      debugPrint('[Analytics] Could not log crear_tarea: $error');
    }
  }
}
