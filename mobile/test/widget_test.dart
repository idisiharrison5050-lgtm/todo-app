import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:todo_mobile/features/reminders/application/reminder_scheduler.dart';
import 'package:todo_mobile/features/tasks/application/task_store.dart';
import 'package:todo_mobile/features/tasks/data/task_repository_memory.dart';
import 'package:todo_mobile/features/tasks/domain/task.dart';
import 'package:todo_mobile/features/tasks/presentation/home_page.dart';
import 'package:todo_mobile/features/tasks/presentation/task_detail_page.dart';
import 'package:todo_mobile/features/tasks/presentation/today_page.dart';

TaskStore createTestStore() {
  return TaskStore(repository: MemoryTaskRepository(), reminderScheduler: NoopReminderScheduler());
}

void main() {
  testWidgets('renders the Today screen', (WidgetTester tester) async {
    final store = createTestStore();

    await tester.pumpWidget(MaterialApp(home: TodayPage(store: store)));
    await tester.pump();

    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Your tasks'), findsOneWidget);
    expect(find.text('Nothing planned yet'), findsOneWidget);
    expect(find.text('Add task'), findsOneWidget);

    store.dispose();
  });

  testWidgets('renders the full task navigation', (WidgetTester tester) async {
    final store = createTestStore();

    await tester.pumpWidget(MaterialApp(home: HomePage(store: store)));
    await tester.pump();

    expect(find.text('Today'), findsWidgets);
    expect(find.text('Upcoming'), findsWidgets);
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
    expect(find.text('Settings'), findsWidgets);

    await tester.tap(find.text('Upcoming').first);
    await tester.pump();
    expect(find.text('Nothing upcoming'), findsOneWidget);

    await tester.tap(find.text('Done').first);
    await tester.pump();
    expect(find.text('Nothing completed yet'), findsOneWidget);

    await tester.tap(find.text('Settings').first);
    await tester.pump();
    expect(find.text('Local storage'), findsOneWidget);

    store.dispose();
  });

  testWidgets('shows search and clears completed tasks', (WidgetTester tester) async {
    final store = createTestStore();
    await store.addTask(title: 'Buy groceries');
    await store.addTask(title: 'Write report');

    await tester.pumpWidget(MaterialApp(home: HomePage(store: store)));
    await tester.pump();

    expect(find.text('Buy groceries'), findsOneWidget);
    expect(find.text('Write report'), findsOneWidget);
    expect(find.byIcon(Icons.search), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'groceries');
    await tester.pump();
    expect(find.text('Buy groceries'), findsOneWidget);
    expect(find.text('Write report'), findsNothing);

    await tester.tap(find.byIcon(Icons.clear));
    await tester.pump();
    expect(find.text('Write report'), findsOneWidget);

    await store.toggleCompleted(store.tasks.first.id);
    await tester.pump();
    await tester.tap(find.text('Done').first);
    await tester.pump();
    expect(find.text('Buy groceries'), findsOneWidget);
    expect(find.byIcon(Icons.delete_sweep_outlined), findsOneWidget);

    await tester.tap(find.byIcon(Icons.delete_sweep_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear all'));
    await tester.pump();
    expect(find.text('Nothing completed yet'), findsOneWidget);

    store.dispose();
  });

  testWidgets('groups upcoming tasks and opens task details', (WidgetTester tester) async {
    final store = createTestStore();
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    await store.addTask(title: 'Tomorrow task', dueAt: DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 9));

    await tester.pumpWidget(MaterialApp(home: HomePage(store: store)));
    await tester.pump();
    await tester.tap(find.text('Upcoming').first);
    await tester.pump();

    expect(find.text('Tomorrow'), findsOneWidget);
    expect(find.text('Tomorrow task'), findsOneWidget);

    await tester.tap(find.text('Tomorrow task'));
    await tester.pumpAndSettle();
    expect(find.text('Task details'), findsOneWidget);
    expect(find.text('Schedule'), findsOneWidget);
    expect(find.text('Priority'), findsOneWidget);
    expect(find.byType(TaskDetailPage), findsOneWidget);

    store.dispose();
  });

  testWidgets('shows later-today tasks in Upcoming and filters by priority', (WidgetTester tester) async {
    final store = createTestStore();
    final now = DateTime.now();
    final laterToday = now.add(const Duration(minutes: 20));
    final tomorrow = now.add(const Duration(days: 1));

    await store.addTask(
      title: 'Later today task',
      dueAt: DateTime(laterToday.year, laterToday.month, laterToday.day, laterToday.hour, laterToday.minute),
      priority: TaskPriority.high,
    );
    await store.addTask(
      title: 'Tomorrow low task',
      dueAt: DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 9),
      priority: TaskPriority.low,
    );

    await tester.pumpWidget(MaterialApp(home: HomePage(store: store)));
    await tester.pump();
    await tester.tap(find.text('Upcoming').first);
    await tester.pump();

    expect(find.text('Later today'), findsOneWidget);
    expect(find.text('Later today task'), findsOneWidget);
    expect(find.text('Tomorrow'), findsOneWidget);
    expect(find.text('Tomorrow low task'), findsOneWidget);

    await tester.tap(find.text('High'));
    await tester.pump();
    expect(find.text('Later today task'), findsOneWidget);
    expect(find.text('Tomorrow low task'), findsNothing);

    store.dispose();
  });

  testWidgets('shows overdue tasks in Today and keeps completed tasks out of active views', (WidgetTester tester) async {
    final store = createTestStore();
    final yesterday = DateTime.now().subtract(const Duration(days: 1));

    await store.addTask(
      title: 'Overdue task',
      dueAt: DateTime(yesterday.year, yesterday.month, yesterday.day, 9),
    );
    await store.addTask(title: 'Completed task');
    await store.toggleCompleted(store.tasks.last.id);

    await tester.pumpWidget(MaterialApp(home: HomePage(store: store)));
    await tester.pump();

    expect(find.text('Overdue task'), findsOneWidget);
    expect(find.textContaining('Overdue'), findsOneWidget);
    expect(find.text('Completed task'), findsNothing);

    await tester.tap(find.text('Done').first);
    await tester.pump();
    expect(find.text('Completed task'), findsOneWidget);
    expect(find.text('Overdue task'), findsNothing);

    store.dispose();
  });
}
