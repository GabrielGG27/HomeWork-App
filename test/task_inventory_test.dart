import 'package:flutter_test/flutter_test.dart';
import 'package:homework_app/models/homework.dart';
import 'package:homework_app/utils/task_inventory.dart';

Homework task({bool completed = false, bool deleted = false}) => Homework(
  title: 'Task',
  subject: 'Math',
  dueDate: DateTime(2026, 8, 21),
  isCompleted: completed,
  isDeleted: deleted,
);

void main() {
  test('counts active pending and completed tasks separately', () {
    final inventory = TaskInventory.fromTasks([
      task(),
      task(),
      task(completed: true),
      task(deleted: true),
      task(completed: true, deleted: true),
    ]);

    expect(inventory.pending, 2);
    expect(inventory.completed, 1);
  });

  test('maps task counts to stable analytics buckets', () {
    expect(TaskInventory.bucketFor(0), '0');
    expect(TaskInventory.bucketFor(1), '1');
    expect(TaskInventory.bucketFor(2), '2_3');
    expect(TaskInventory.bucketFor(3), '2_3');
    expect(TaskInventory.bucketFor(4), '4_7');
    expect(TaskInventory.bucketFor(7), '4_7');
    expect(TaskInventory.bucketFor(8), '8_plus');
  });
}
