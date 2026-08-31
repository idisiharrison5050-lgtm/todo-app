import 'package:flutter_test/flutter_test.dart';

import 'package:todo_mobile/features/reminders/application/reminder_scheduler.dart';
import 'package:todo_mobile/features/tasks/application/task_store.dart';
import 'package:todo_mobile/features/tasks/data/task_repository_memory.dart';
import 'package:todo_mobile/features/tasks/domain/task.dart';

class FakeReminderScheduler implements ReminderScheduler {
  final List<String> scheduled = <String>[];
  final List<String> cancelled = <String>[];

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> schedule(Task task) async => scheduled.add(task.id);

  @override
  Future<void> cancel(String taskId) async => cancelled.add(taskId);

  @override
  Future<void> cancelAll() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('creates, updates, completes and deletes a task', () async {
    final repository = MemoryTaskRepository();
    final reminders = FakeReminderScheduler();
    final store = TaskStore(repository: repository, reminderScheduler: reminders);

    await store.addTask(
      title: 'Test task',
      notes: 'Notes',
      dueAt: DateTime.now().add(const Duration(minutes: 5, seconds: 47)),
      reminderType: TaskReminderType.once,
      priority: TaskPriority.high,
    );

    expect(store.tasks, hasLength(1));
    final created = store.tasks.single;
    expect(created.title, 'Test task');
    expect(created.notes, 'Notes');
    expect(created.priority, TaskPriority.high);
    expect(created.dueAt!.second, 0);
    expect(created.dueAt!.millisecond, 0);
    expect(created.dueAt!.microsecond, 0);
    expect(reminders.scheduled, contains(created.id));

    await store.updateTask(
      created.id,
      title: 'Updated task',
      dueAt: DateTime.now().add(const Duration(minutes: 10, seconds: 59)),
      reminderType: TaskReminderType.none,
    );

    expect(store.tasks.single.title, 'Updated task');
    expect(store.tasks.single.dueAt!.second, 0);
    expect(reminders.cancelled, contains(created.id));

    await store.toggleCompleted(created.id);
    expect(store.tasks.single.isCompleted, isTrue);
    expect(reminders.cancelled, contains(created.id));

    await store.toggleCompleted(created.id);
    expect(store.tasks.single.isCompleted, isFalse);

    await store.deleteTask(created.id);
    expect(store.tasks, isEmpty);

    store.dispose();
  });

  test('loads persisted tasks from the repository', () async {
    final repository = MemoryTaskRepository();
    final reminders = FakeReminderScheduler();
    final first = TaskStore(repository: repository, reminderScheduler: reminders);

    await first.addTask(title: 'Persistent task');
    first.dispose();

    final second = TaskStore(repository: repository, reminderScheduler: reminders);
    await second.load();

    expect(second.tasks, hasLength(1));
    expect(second.tasks.single.title, 'Persistent task');
    second.dispose();
  });

  test('rejects a reminder without a due time', () async {
    final store = TaskStore(
      repository: MemoryTaskRepository(),
      reminderScheduler: FakeReminderScheduler(),
    );

    expect(
      () => store.addTask(title: 'Reminder', reminderType: TaskReminderType.once),
      throwsArgumentError,
    );
    store.dispose();
  });

  test('rejects an invalid repeating reminder interval', () async {
    final store = TaskStore(
      repository: MemoryTaskRepository(),
      reminderScheduler: FakeReminderScheduler(),
    );

    expect(
      () => store.addTask(
        title: 'Repeat',
        dueAt: DateTime.now().add(const Duration(minutes: 5)),
        reminderType: TaskReminderType.interval,
      ),
      throwsArgumentError,
    );
    store.dispose();
  });
}
