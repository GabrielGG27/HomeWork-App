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
}
