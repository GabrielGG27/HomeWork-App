import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:homework_app/services/homework_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('returns no icons when saved JSON is malformed', () async {
    SharedPreferences.setMockInitialValues({'subject_icons': '{not-json'});

    expect(await HomeworkService.loadSubjectIcons(), isEmpty);
  });

  test('returns no icons when saved values have invalid types', () async {
    SharedPreferences.setMockInitialValues({
      'subject_icons': '{"Math":"not-an-icon-code"}',
    });

    expect(await HomeworkService.loadSubjectIcons(), isEmpty);
  });

  test('adds a deletion date to legacy trash items', () async {
    final legacyTask = <String, Object?>{
      'id': 'legacy-deleted',
      'title': 'Old deleted task',
      'subject': 'Math',
      'dueDate': DateTime(2026, 1, 1).millisecondsSinceEpoch,
      'isDeleted': true,
      'isCompleted': false,
      'enableNotification': false,
      'description': '',
      'attachments': <Object?>[],
    };
    SharedPreferences.setMockInitialValues({
      'homework': <String>[jsonEncode(legacyTask)],
    });

    final loaded = await HomeworkService.loadHomework();

    expect(loaded, hasLength(1));
    expect(loaded.single.deletedAt, isNotNull);
    final prefs = await SharedPreferences.getInstance();
    final migrated = jsonDecode(prefs.getStringList('homework')!.single);
    expect(migrated['deletedAt'], isNotNull);
  });
}
