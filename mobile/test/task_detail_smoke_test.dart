import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_mobile/features/reminders/application/reminder_scheduler.dart';
import 'package:todo_mobile/features/tasks/application/task_store.dart';
import 'package:todo_mobile/features/tasks/data/task_repository_memory.dart';
import 'package:todo_mobile/features/tasks/domain/task.dart';
import 'package:todo_mobile/features/tasks/presentation/task_detail_page.dart';

class _FakeReminderScheduler implements ReminderScheduler {
  @override
  Future<bool> areNotificationsEnabled() async => true;

  @override
  Future<bool> requestPermission() async => true;
  @override
  Future<void> schedule(Task task) async {}
  @override
  Future<void> snooze(Task task, int minutes) async {}
  @override
  Future<void> cancel(String taskId) async {}
  @override
  Future<void> cancelAll() async {}
}

void main() {
  testWidgets('renders the premium task detail workflow', (tester) async {
    final store = TaskStore(
      repository: MemoryTaskRepository(),
      reminderScheduler: _FakeReminderScheduler(),
    );
    await store.addTask(
      title: 'Ship the new experience',
      notes: 'Review the final details before release.',
      dueAt: DateTime.now().add(const Duration(hours: 2)),
      priority: TaskPriority.high,
      category: 'Product',
      tags: const ['release', 'ui'],
    );
    final task = store.tasks.single;

    await tester.pumpWidget(
      MaterialApp(
        home: TaskDetailPage(store: store, task: task),
      ),
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 500));

    expect(find.text('Ship the new experience'), findsOneWidget);
    expect(find.text('Edit task details'), findsOneWidget);
    expect(find.text('Notes'), findsOneWidget);
    expect(find.text('High priority'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Checklist'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Checklist'), findsOneWidget);
    expect(find.text('Activity'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Complete task'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Complete task'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Edit task details'),
      -400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Edit task details'));
    await tester.pumpAndSettle(const Duration(milliseconds: 500));
    expect(find.text('Edit task'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);

    store.dispose();
  });
}
