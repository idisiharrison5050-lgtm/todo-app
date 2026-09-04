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
  return TaskStore(
    repository: MemoryTaskRepository(),
    reminderScheduler: NoopReminderScheduler(),
  );
}

void main() {
  testWidgets('renders the Today screen', (WidgetTester tester) async {
    final store = createTestStore();
    await tester.pumpWidget(MaterialApp(home: TodayPage(store: store)));
    await tester.pump();
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Your tasks'), findsOneWidget);
    expect(find.text('Nothing planned today'), findsOneWidget);
    expect(find.text('Add task'), findsOneWidget);
    store.dispose();
  });

  testWidgets('renders the redesigned workspace navigation', (WidgetTester tester) async {
    final store = createTestStore();
    await tester.pumpWidget(
      MaterialApp(home: HomePage(store: store, onLogout: () async {})),
    );
    await tester.pump();

    expect(find.descendant(
      of: find.byType(NavigationDestination),
      matching: find.text('Home'),
    ), findsOneWidget);
    expect(find.descendant(
      of: find.byType(NavigationDestination),
      matching: find.text('Today'),
    ), findsOneWidget);
    expect(find.descendant(
      of: find.byType(NavigationDestination),
      matching: find.text('Calendar'),
    ), findsOneWidget);
    expect(find.descendant(
      of: find.byType(NavigationDestination),
      matching: find.text('Focus'),
    ), findsOneWidget);
    expect(find.descendant(
      of: find.byType(NavigationDestination),
      matching: find.text('Settings'),
    ), findsOneWidget);
    expect(find.text('Your day, in control.'), findsOneWidget);
    expect(find.text('Your day is clear'), findsOneWidget);

    await tester.tap(find.text('Focus'));
    await tester.pump();
    expect(find.text('One task. One session. Less noise.'), findsOneWidget);
    expect(find.text('Start 25 min'), findsOneWidget);

    await tester.tap(find.text('Calendar'));
    await tester.pump();
    expect(find.text('Calendar'), findsWidgets);

    await tester.tap(find.text('Settings'));
    await tester.pump();
    expect(find.text('Account security'), findsOneWidget);
    store.dispose();
  });

  testWidgets('creates and completes a task from the home workspace', (WidgetTester tester) async {
    final store = createTestStore();
    await store.addTask(title: 'Buy groceries', dueAt: DateTime.now());
    await tester.pumpWidget(
      MaterialApp(home: HomePage(store: store, onLogout: () async {})),
    );
    await tester.pump();

    expect(find.text('Buy groceries'), findsOneWidget);
    expect(find.text('Today'), findsNWidgets(3));
    expect(find.text('All tasks'), findsOneWidget);

    await tester.tap(find.text('Buy groceries'));
    await tester.pumpAndSettle();
    expect(find.byType(TaskDetailPage), findsOneWidget);

    final detailScrollable = find.byType(Scrollable);
    await tester.scrollUntilVisible(
      find.text('Checklist'),
      500,
      scrollable: detailScrollable,
    );
    expect(find.text('Checklist'), findsOneWidget);
    expect(find.text('Activity'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Complete task'),
      500,
      scrollable: detailScrollable,
    );
    await tester.tap(find.text('Complete task'));
    await tester.pumpAndSettle();
    expect(find.text('Mark active'), findsOneWidget);
    expect(store.tasks.singleWhere((task) => task.title == 'Buy groceries').isCompleted, isTrue);
    store.dispose();
  });

  testWidgets('searches and filters all tasks', (WidgetTester tester) async {
    final store = createTestStore();
    await store.addTask(title: 'Buy groceries', priority: TaskPriority.high);
    await store.addTask(title: 'Write report', priority: TaskPriority.low);
    await tester.pumpWidget(
      MaterialApp(home: HomePage(store: store, onLogout: () async {})),
    );
    await tester.pump();

    await tester.tap(find.text('All tasks'));
    await tester.pumpAndSettle();
    expect(find.text('Buy groceries'), findsOneWidget);
    expect(find.text('Write report'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'groceries');
    await tester.pump();
    expect(find.text('Buy groceries'), findsOneWidget);
    expect(find.text('Write report'), findsNothing);

    await tester.tap(find.byIcon(Icons.clear_rounded));
    await tester.pump();
    await tester.tap(find.text('High'));
    await tester.pump();
    expect(find.text('Buy groceries'), findsOneWidget);
    expect(find.text('Write report'), findsNothing);
    store.dispose();
  });

  testWidgets('focus timer starts and pauses', (WidgetTester tester) async {
    final store = createTestStore();
    await tester.pumpWidget(
      MaterialApp(home: HomePage(store: store, onLogout: () async {})),
    );
    await tester.pump();
    await tester.tap(find.text('Focus'));
    await tester.pump();

    expect(find.text('25:00'), findsOneWidget);
    await tester.tap(find.text('Start 25 min'));
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Pause'), findsOneWidget);
    expect(find.text('25:00'), findsNothing);
    await tester.tap(find.text('Pause'));
    await tester.pump();
    expect(find.text('Start 25 min'), findsOneWidget);
    store.dispose();
  });
}
