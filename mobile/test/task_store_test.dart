import 'package:flutter_test/flutter_test.dart';

import 'package:todo_mobile/features/reminders/application/reminder_scheduler.dart';
import 'package:todo_mobile/features/tasks/application/task_store.dart';
import 'package:todo_mobile/features/tasks/data/task_repository_memory.dart';
import 'package:todo_mobile/features/tasks/domain/task.dart';

class FakeReminderScheduler implements ReminderScheduler {
  final List<String> scheduled = <String>[];
  final List<String> cancelled = <String>[];
  @override Future<bool> requestPermission() async => true;
  @override Future<void> schedule(Task task) async => scheduled.add(task.id);
  @override Future<void> snooze(Task task, int minutes) async {}
  @override Future<void> cancel(String taskId) async => cancelled.add(taskId);
  @override Future<void> cancelAll() async {}
}

void main() {
  test('creates, updates, completes and deletes a task', () async {
    final repository = MemoryTaskRepository();
    final reminders = FakeReminderScheduler();
    final store = TaskStore(repository: repository, reminderScheduler: reminders);
    await store.addTask(title: 'Test task', notes: 'Notes', dueAt: DateTime.now().add(const Duration(minutes: 5, seconds: 47)), reminderType: TaskReminderType.once, priority: TaskPriority.high);
    expect(store.tasks, hasLength(1));
    final created = store.tasks.single;
    expect(created.title, 'Test task'); expect(created.notes, 'Notes'); expect(created.priority, TaskPriority.high);
    expect(created.dueAt!.second, 0); expect(created.dueAt!.millisecond, 0); expect(created.dueAt!.microsecond, 0); expect(reminders.scheduled, contains(created.id));
    await store.updateTask(created.id, title: 'Updated task', dueAt: DateTime.now().add(const Duration(minutes: 10, seconds: 59)), reminderType: TaskReminderType.once);
    expect(store.tasks.single.title, 'Updated task'); expect(store.tasks.single.dueAt!.second, 0); expect(reminders.cancelled, contains(created.id)); expect(reminders.scheduled.where((id) => id == created.id).length, 2);
    await store.toggleCompleted(created.id); expect(store.tasks.single.isCompleted, isTrue); expect(reminders.cancelled.length, greaterThanOrEqualTo(2));
    await store.toggleCompleted(created.id); expect(store.tasks.single.isCompleted, isFalse); expect(reminders.scheduled.where((id) => id == created.id).length, 3);
    await store.deleteTask(created.id); expect(store.tasks, isEmpty); expect(reminders.cancelled.length, greaterThanOrEqualTo(3));
    store.dispose();
  });

  test('loads persisted tasks from the repository and restores reminders', () async {
    final repository = MemoryTaskRepository(); final reminders = FakeReminderScheduler(); final first = TaskStore(repository: repository, reminderScheduler: reminders);
    await first.addTask(title: 'Persistent task', dueAt: DateTime.now().add(const Duration(hours: 1)), reminderType: TaskReminderType.once);
    final savedId = first.tasks.single.id; first.dispose(); reminders.scheduled.clear();
    final second = TaskStore(repository: repository, reminderScheduler: reminders); await second.load();
    expect(second.tasks, hasLength(1)); expect(second.tasks.single.title, 'Persistent task'); expect(reminders.scheduled, contains(savedId)); second.dispose();
  });

  test('does not restore reminders for completed tasks', () async {
    final repository = MemoryTaskRepository(); final reminders = FakeReminderScheduler(); final first = TaskStore(repository: repository, reminderScheduler: reminders);
    await first.addTask(title: 'Completed task', dueAt: DateTime.now().add(const Duration(hours: 1)), reminderType: TaskReminderType.once);
    await first.toggleCompleted(first.tasks.single.id); first.dispose(); reminders.scheduled.clear();
    final second = TaskStore(repository: repository, reminderScheduler: reminders); await second.load();
    expect(second.tasks.single.isCompleted, isTrue); expect(reminders.scheduled, isEmpty); second.dispose();
  });

  test('switching reminder modes replaces the previous schedule', () async {
    final repository = MemoryTaskRepository(); final reminders = FakeReminderScheduler(); final store = TaskStore(repository: repository, reminderScheduler: reminders); final due = DateTime.now().add(const Duration(hours: 2));
    await store.addTask(title: 'Reminder task', dueAt: due, reminderType: TaskReminderType.once); final id = store.tasks.single.id; final scheduledAfterOnce = reminders.scheduled.length;
    await store.updateTask(id, title: 'Reminder task', dueAt: due, reminderType: TaskReminderType.interval, reminderInterval: const Duration(hours: 2));
    expect(reminders.cancelled, contains(id)); expect(reminders.scheduled.length, scheduledAfterOnce + 1);
    await store.updateTask(id, title: 'Reminder task', dueAt: due, reminderType: TaskReminderType.none);
    expect(reminders.cancelled.length, greaterThanOrEqualTo(2)); expect(reminders.scheduled.length, scheduledAfterOnce + 1); store.dispose();
  });

  test('editing a reminder time cancels the old schedule before scheduling the new one', () async {
    final repository = MemoryTaskRepository(); final reminders = FakeReminderScheduler(); final store = TaskStore(repository: repository, reminderScheduler: reminders);
    final originalDue = DateTime.now().add(const Duration(hours: 1)); final updatedDue = DateTime.now().add(const Duration(hours: 3));
    await store.addTask(title: 'Move reminder', dueAt: originalDue, reminderType: TaskReminderType.once); final id = store.tasks.single.id;
    await store.updateTask(id, title: 'Move reminder', dueAt: updatedDue, reminderType: TaskReminderType.once);
    expect(reminders.cancelled, contains(id)); expect(store.tasks.single.dueAt!.isBefore(updatedDue.add(const Duration(minutes: 1))), isTrue); expect(reminders.scheduled.where((value) => value == id), hasLength(2)); store.dispose();
  });

  test('removing a due date disables and cancels its reminder', () async {
    final repository = MemoryTaskRepository(); final reminders = FakeReminderScheduler(); final store = TaskStore(repository: repository, reminderScheduler: reminders);
    await store.addTask(title: 'Remove schedule', dueAt: DateTime.now().add(const Duration(hours: 1)), reminderType: TaskReminderType.once); final id = store.tasks.single.id;
    await store.updateTask(id, title: 'Remove schedule', dueAt: null, reminderType: TaskReminderType.none);
    expect(store.tasks.single.dueAt, isNull); expect(store.tasks.single.reminderType, TaskReminderType.none); expect(reminders.cancelled, contains(id)); expect(reminders.scheduled.where((value) => value == id), hasLength(1)); store.dispose();
  });

  test('turning a reminder off does not leave a new schedule', () async {
    final repository = MemoryTaskRepository(); final reminders = FakeReminderScheduler(); final store = TaskStore(repository: repository, reminderScheduler: reminders); final due = DateTime.now().add(const Duration(hours: 1));
    await store.addTask(title: 'Disable reminder', dueAt: due, reminderType: TaskReminderType.once); final id = store.tasks.single.id; final scheduledCount = reminders.scheduled.length;
    await store.updateTask(id, title: 'Disable reminder', dueAt: due, reminderType: TaskReminderType.none);
    expect(reminders.cancelled, contains(id)); expect(reminders.scheduled.length, scheduledCount); store.dispose();
  });

  test('rejects a reminder without a due time', () async {
    final store = TaskStore(repository: MemoryTaskRepository(), reminderScheduler: FakeReminderScheduler());
    expect(() => store.addTask(title: 'Reminder', reminderType: TaskReminderType.once), throwsArgumentError); store.dispose();
  });

  test('rejects an invalid repeating reminder interval', () async {
    final store = TaskStore(repository: MemoryTaskRepository(), reminderScheduler: FakeReminderScheduler());
    expect(() => store.addTask(title: 'Repeat', dueAt: DateTime.now().add(const Duration(minutes: 5)), reminderType: TaskReminderType.interval), throwsArgumentError); store.dispose();
  });

  test('rejects a recurring task without a due time', () async {
    final store = TaskStore(repository: MemoryTaskRepository(), reminderScheduler: FakeReminderScheduler());
    expect(() => store.addTask(title: 'Recurring', repeat: TaskRepeat.daily), throwsArgumentError); store.dispose();
  });

  test('rejects a custom recurrence without a positive interval', () async {
    final store = TaskStore(repository: MemoryTaskRepository(), reminderScheduler: FakeReminderScheduler());
    final due = DateTime.now().add(const Duration(hours: 1));
    expect(() => store.addTask(title: 'Custom', dueAt: due, repeat: TaskRepeat.custom), throwsArgumentError);
    expect(() => store.addTask(title: 'Custom', dueAt: due, repeat: TaskRepeat.custom, repeatIntervalDays: 0), throwsArgumentError);
    expect(() => store.addTask(title: 'Custom', dueAt: due, repeat: TaskRepeat.custom, repeatIntervalDays: -1), throwsArgumentError);
    store.dispose();
  });

  test('advances a daily recurring task by one calendar day', () async {
    final repository = MemoryTaskRepository(); final store = TaskStore(repository: repository, reminderScheduler: FakeReminderScheduler());
    final due = DateTime(2026, 9, 10, 9, 15);
    await store.addTask(title: 'Daily', dueAt: due, repeat: TaskRepeat.daily);
    final id = store.tasks.single.id;
    await store.toggleCompleted(id);
    expect(store.tasks.single.isCompleted, isFalse);
    expect(store.tasks.single.dueAt, DateTime(2026, 9, 11, 9, 15));
    store.dispose();
  });

  test('skips the weekend for weekday recurrence', () async {
    final repository = MemoryTaskRepository(); final store = TaskStore(repository: repository, reminderScheduler: FakeReminderScheduler());
    final friday = DateTime(2026, 9, 11, 9, 15);
    await store.addTask(title: 'Weekday', dueAt: friday, repeat: TaskRepeat.weekdays);
    final id = store.tasks.single.id;
    await store.toggleCompleted(id);
    expect(store.tasks.single.dueAt, DateTime(2026, 9, 14, 9, 15));
    store.dispose();
  });

  test('advances weekly recurrence by seven calendar days', () async {
    final repository = MemoryTaskRepository(); final store = TaskStore(repository: repository, reminderScheduler: FakeReminderScheduler());
    final due = DateTime(2026, 9, 10, 9, 15);
    await store.addTask(title: 'Weekly', dueAt: due, repeat: TaskRepeat.weekly);
    final id = store.tasks.single.id;
    await store.toggleCompleted(id);
    expect(store.tasks.single.dueAt, DateTime(2026, 9, 17, 9, 15));
    store.dispose();
  });

  test('clamps monthly recurrence to the last day of the target month', () async {
    final repository = MemoryTaskRepository(); final store = TaskStore(repository: repository, reminderScheduler: FakeReminderScheduler());
    final januaryThirtyFirst = DateTime(2027, 1, 31, 9, 15);
    await store.addTask(title: 'Monthly', dueAt: januaryThirtyFirst, repeat: TaskRepeat.monthly);
    final id = store.tasks.single.id;
    await store.toggleCompleted(id);
    expect(store.tasks.single.dueAt, DateTime(2027, 2, 28, 9, 15));
    store.dispose();
  });

  test('advances custom recurrence by its configured calendar interval', () async {
    final repository = MemoryTaskRepository(); final store = TaskStore(repository: repository, reminderScheduler: FakeReminderScheduler());
    final due = DateTime(2026, 9, 10, 9, 15);
    await store.addTask(title: 'Custom', dueAt: due, repeat: TaskRepeat.custom, repeatIntervalDays: 10);
    final id = store.tasks.single.id;
    await store.toggleCompleted(id);
    expect(store.tasks.single.dueAt, DateTime(2026, 9, 20, 9, 15));
    store.dispose();
  });

  test('manages subtasks and records history', () async {
    final repository = MemoryTaskRepository(); final store = TaskStore(repository: repository, reminderScheduler: FakeReminderScheduler());
    await store.addTask(title: 'Project plan');
    final id = store.tasks.single.id;
    expect(store.tasks.single.history.map((entry) => entry.action), contains('Created'));
    await store.addSubtask(id, 'Write brief'); await store.addSubtask(id, 'Review budget');
    expect(store.tasks.single.subtasks, hasLength(2)); expect(store.tasks.single.history.map((entry) => entry.action), contains('Subtask added'));
    final subtaskId = store.tasks.single.subtasks.first.id;
    await store.updateSubtask(id, subtaskId, isCompleted: true);
    expect(store.tasks.single.subtasks.first.isCompleted, isTrue); expect(store.tasks.single.history.map((entry) => entry.action), contains('Subtask completed'));
    await store.deleteSubtask(id, subtaskId);
    expect(store.tasks.single.subtasks, hasLength(1)); expect(store.tasks.single.history.map((entry) => entry.action), contains('Subtask deleted'));
    await store.toggleCompleted(id); expect(store.tasks.single.history.map((entry) => entry.action), contains('Completed'));
    final reloaded = TaskStore(repository: repository, reminderScheduler: FakeReminderScheduler()); store.dispose(); await reloaded.load();
    expect(reloaded.tasks.single.history.length, greaterThanOrEqualTo(5)); expect(reloaded.tasks.single.subtasks, hasLength(1)); reloaded.dispose();
  });
}
