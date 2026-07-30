import 'package:flutter_test/flutter_test.dart';
import 'package:homework_app/models/homework.dart';
import 'package:homework_app/utils/homework_grouping.dart';

void main() {
  test('groups date boundaries without dropping tasks', () {
    final now = DateTime(2026, 7, 30, 10);
    final todayEnd = DateTime(2026, 7, 31);
    final tomorrowEnd = DateTime(2026, 8, 1);
    final weekEnd = DateTime(2026, 8, 6);
    final tasks = [
      _task('now', now),
      _task('today-end', todayEnd),
      _task('tomorrow-end', tomorrowEnd),
      _task('week-end', weekEnd),
    ];

    final grouped = groupHomeworkByDate(tasks, referenceTime: now);

    expect(grouped['today']!.single.title, 'now');
    expect(grouped['tomorrow']!.single.title, 'today-end');
    expect(grouped['week']!.single.title, 'tomorrow-end');
    expect(grouped['upcoming']!.single.title, 'week-end');
    expect(grouped.values.expand((group) => group), hasLength(tasks.length));
  });
}

Homework _task(String title, DateTime dueDate) =>
    Homework(id: title, title: title, subject: 'Test', dueDate: dueDate);
