import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:homework_app/models/homework.dart';

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
        loaded.add(Homework.fromJson(json));
      } catch (e) {
        print('Error loading homework item: $e');
      }
    }

    if (needsSave) {
      final fixedData = loaded.map((h) => jsonEncode(h.toJson())).toList();
      await prefs.setStringList('homework', fixedData);
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
      return Map<String, int>.from(jsonDecode(iconsJson));
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
      final icons = Map<String, dynamic>.from(jsonDecode(iconsJson));
      icons.remove(subject);
      await prefs.setString('subject_icons', jsonEncode(icons));
    }
  }
}
