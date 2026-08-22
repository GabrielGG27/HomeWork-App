import 'package:homework_app/models/homework.dart';

class TaskInventory {
  const TaskInventory({required this.pending, required this.completed});

  final int pending;
  final int completed;

  factory TaskInventory.fromTasks(Iterable<Homework> tasks) {
    var pending = 0;
    var completed = 0;

    for (final task in tasks) {
      if (task.isDeleted) continue;
      if (task.isCompleted) {
        completed++;
      } else {
        pending++;
      }
    }

    return TaskInventory(pending: pending, completed: completed);
  }

  static String bucketFor(int count) {
    if (count <= 0) return '0';
    if (count == 1) return '1';
    if (count <= 3) return '2_3';
    if (count <= 7) return '4_7';
    return '8_plus';
  }
}
