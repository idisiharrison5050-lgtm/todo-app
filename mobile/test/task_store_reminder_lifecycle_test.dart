import 'package:flutter_test/flutter_test.dart';

import 'package:todo_mobile/features/reminders/application/reminder_scheduler.dart';
import 'package:todo_mobile/features/tasks/application/task_store.dart';
import 'package:todo_mobile/features/tasks/data/task_repository_memory.dart';
import 'package:todo_mobile/features/tasks/domain/task.dart';

class RecordingReminderScheduler implements ReminderScheduler {
  final List<String> scheduled = <String>[];
  final List<String> cancelled = <String>[];

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> schedule(Task task) async => scheduled.add(task.id);

  @override
  Future<void> snooze(Task task, int minutes) async {}

  @override
  Future<void> cancel(String taskId) async => cancelled.add(taskId);

  @override
  Future<void> cancelAll() async {}
}

void main() {
  test('completing a recurring task advances it and replaces its reminder', () async {
    final repository = MemoryTaskRepository();
    final reminders = RecordingReminderScheduler();
    final store = TaskStore(
      repository: repository,
      reminderScheduler: reminders,
    );

    final due = DateTime.now().add(const Duration(hours: 2));
    await store.addTask(
      title: 'Daily reminder',
      dueAt: due,
      repeat: TaskRepeat.daily,
      reminderType: TaskReminderType.once,
    );

    final id = store.tasks.single.id;
    final originalDue = store.tasks.single.dueAt!;
    expect(reminders.scheduled.where((value) => value == id), hasLength(1));

    await store.toggleCompleted(id);

    final updated = store.tasks.single;
    expect(updated.isCompleted, isFalse);
    expect(updated.dueAt, DateTime(originalDue.year, originalDue.month, originalDue.day + 1, originalDue.hour, originalDue.minute));
    expect(reminders.cancelled, contains(id));
    expect(reminders.scheduled.where((value) => value == id), hasLength(2));
    store.dispose();
  });

  test('reopening a completed one-time task restores its reminder', () async {
    final repository = MemoryTaskRepository();
    final reminders = RecordingReminderScheduler();
    final store = TaskStore(
      repository: repository,
      reminderScheduler: reminders,
    );

    await store.addTask(
      title: 'One-time reminder',
      dueAt: DateTime.now().add(const Duration(hours: 2)),
      reminderType: TaskReminderType.once,
    );
    final id = store.tasks.single.id;

    await store.toggleCompleted(id);
    expect(store.tasks.single.isCompleted, isTrue);
    expect(reminders.cancelled, contains(id));

    final scheduledBeforeReopen = reminders.scheduled.where((value) => value == id).length;
    await store.toggleCompleted(id);

    expect(store.tasks.single.isCompleted, isFalse);
    expect(reminders.scheduled.where((value) => value == id), hasLength(scheduledBeforeReopen + 1));
    store.dispose();
  });

  test('loading an overdue recurring task keeps its next reminder after catch-up', () async {
    final repository = MemoryTaskRepository();
    final reminders = RecordingReminderScheduler();
    final overdue = Task(
      id: 'overdue-recurring-reminder',
      title: 'Missed daily reminder',
      dueAt: DateTime.now().subtract(const Duration(days: 3)),
      repeat: TaskRepeat.daily,
      reminderType: TaskReminderType.once,
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
    );
    await repository.saveTask(overdue);

    final store = TaskStore(
      repository: repository,
      reminderScheduler: reminders,
    );
    await store.load();
    await store.toggleCompleted(overdue.id);

    final updated = store.tasks.single;
    expect(updated.isCompleted, isFalse);
    expect(updated.dueAt!.isAfter(DateTime.now()), isTrue);
    expect(updated.history.last.action, 'Completed occurrence');
    expect(reminders.scheduled, contains(overdue.id));
    expect(reminders.cancelled, contains(overdue.id));
    store.dispose();
  });
}
