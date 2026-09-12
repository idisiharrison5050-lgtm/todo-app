import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:todo_mobile/features/tasks/application/task_store.dart';
import 'package:todo_mobile/features/tasks/data/task_repository_memory.dart';
import 'package:todo_mobile/features/tasks/domain/task.dart';
import 'package:todo_mobile/features/tasks/presentation/task_detail_page.dart';

void main() {
  testWidgets('renders the premium task detail workflow', (tester) async {
    final store = TaskStore(repository: MemoryTaskRepository());
    await store.addTask(
      title: 'Ship the new experience',
      notes: 'Prepare the final release checklist.',
      dueAt: DateTime.now().add(const Duration(hours: 2)),
      priority: TaskPriority.high,
      repeat: TaskRepeat.none,
    );
    final task = store.tasks.single;

    await tester.pumpWidget(MaterialApp(home: TaskDetailPage(store: store, task: task)));
    await tester.pumpAndSettle();

    expect(find.text('Ship the new experience'), findsOneWidget);
    expect(find.text('Complete task'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Ship the new experience'),
      -400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    final editButton = find.widgetWithText(
      OutlinedButton,
      'Edit task details',
    );
    expect(editButton, findsOneWidget);
    await tester.tap(editButton);
    await tester.pumpAndSettle(const Duration(milliseconds: 500));
    expect(find.text('Edit task'), findsOneWidget);
    expect(find.text('Save changes'), findsOneWidget);

    store.dispose();
  });
}
