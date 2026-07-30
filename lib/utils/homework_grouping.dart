import 'package:homework_app/models/homework.dart';

Map<String, List<Homework>> groupHomeworkByDate(
  List<Homework> homeworkList, {
  DateTime? referenceTime,
}) {
  final now = referenceTime ?? DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);
  final todayEnd = todayStart.add(const Duration(days: 1));
  final tomorrowEnd = todayEnd.add(const Duration(days: 1));
  final endOfWeek = todayStart.add(const Duration(days: 7));

  final groups = <String, List<Homework>>{
    'overdue': [],
    'today': [],
    'tomorrow': [],
    'week': [],
    'upcoming': [],
    'no_date': [],
  };

  for (final homework in homeworkList) {
    if (!homework.hasDueDate) {
      groups['no_date']!.add(homework);
    } else if (homework.dueDate.isBefore(now)) {
      groups['overdue']!.add(homework);
    } else if (homework.dueDate.isBefore(todayEnd)) {
      groups['today']!.add(homework);
    } else if (homework.dueDate.isBefore(tomorrowEnd)) {
      groups['tomorrow']!.add(homework);
    } else if (homework.dueDate.isBefore(endOfWeek)) {
      groups['week']!.add(homework);
    } else {
      groups['upcoming']!.add(homework);
    }
  }

  groups.removeWhere((_, tasks) => tasks.isEmpty);
  return groups;
}
