import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:homework_app/models/homework.dart';
import 'package:homework_app/services/attachment_storage_service.dart';

class HomeworkService {
  static Future<List<Homework>> loadHomework() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList('homework') ?? [];

    List<Homework> loaded = [];
    bool needsSave = false;
    int baseId = DateTime.now().millisecondsSinceEpoch;

    for (int i = 0; i < data.length; i++) {
      try {
        Map<String, dynamic> json = jsonDecode(data[i]);
        if (json['id'] == null) {
          json['id'] = '${baseId + i}';
          needsSave = true;
        }
        final homework = Homework.fromJson(json);
        if (homework.isDeleted && homework.deletedAt == null) {
          // Old versions stored the deleted flag without a timestamp. Start
          // their 30-day retention period at migration instead of retaining
          // them forever or deleting them immediately.
          homework.deletedAt = DateTime.now();
          needsSave = true;
        }
        loaded.add(homework);
      } catch (e) {
        debugPrint('Error loading homework item: $e');
      }
    }

    if (needsSave) {
      final fixedData = loaded.map((h) => jsonEncode(h.toJson())).toList();
      await prefs.setStringList('homework', fixedData);
    }

    // Auto-delete expired deleted tasks (older than 30 days)
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    final expiredTasks = loaded
        .where(
          (h) =>
              h.isDeleted &&
              h.deletedAt != null &&
              h.deletedAt!.isBefore(thirtyDaysAgo),
        )
        .toList();
    if (expiredTasks.isNotEmpty) {
      loaded.removeWhere((h) => expiredTasks.contains(h));
      final updatedData = loaded.map((h) => jsonEncode(h.toJson())).toList();
      await prefs.setStringList('homework', updatedData);
      await AttachmentStorageService.deleteManagedFiles(
        expiredTasks.expand((task) => task.attachments),
      );
    }

    return loaded;
  }

  static Future<void> saveHomework(List<Homework> homeworkList) async {
    final prefs = await SharedPreferences.getInstance();
    final data = homeworkList.map((h) => jsonEncode(h.toJson())).toList();
    await prefs.setStringList('homework', data);
  }

  static Future<List<String>> loadSubjects() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('subjects') ?? [];
  }

  static Future<Map<String, int>> loadSubjectIcons() async {
    final prefs = await SharedPreferences.getInstance();
    final iconsJson = prefs.getString('subject_icons');
    if (iconsJson != null) {
      try {
        return Map<String, int>.from(jsonDecode(iconsJson));
      } on FormatException catch (error) {
        debugPrint('Invalid subject icon data: $error');
      } on TypeError catch (error) {
        debugPrint('Invalid subject icon types: $error');
      }
    }
    return {};
  }

  static Future<void> saveSubjects(List<String> subjects) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('subjects', subjects);
  }

  static Future<void> saveSubjectIcons(Map<String, int> icons) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('subject_icons', jsonEncode(icons));
  }

  static Future<void> deleteSubject(String subject) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList('subjects') ?? [];
    current.remove(subject);
    await prefs.setStringList('subjects', current);

    final iconsJson = prefs.getString('subject_icons');
    if (iconsJson != null) {
      try {
        final icons = Map<String, dynamic>.from(jsonDecode(iconsJson));
        icons.remove(subject);
        await prefs.setString('subject_icons', jsonEncode(icons));
      } on FormatException catch (error) {
        debugPrint('Could not update invalid subject icon data: $error');
      } on TypeError catch (error) {
        debugPrint('Could not update invalid subject icon types: $error');
      }
    }
  }
}
