import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:todo_mobile/features/tasks/application/task_store.dart';
import 'package:todo_mobile/features/tasks/data/task_repository_memory.dart';
import 'package:todo_mobile/features/tasks/presentation/home_page.dart';
import 'package:todo_mobile/features/tasks/presentation/today_page.dart';

void main() {
  testWidgets('renders the Today screen', (WidgetTester tester) async {
    final store = TaskStore(repository: MemoryTaskRepository());

    await tester.pumpWidget(MaterialApp(home: TodayPage(store: store)));
    await tester.pump();

    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Your tasks'), findsOneWidget);
    expect(find.text('Nothing planned yet'), findsOneWidget);
    expect(find.text('Add task'), findsOneWidget);

    store.dispose();
  });

  testWidgets('renders the full task navigation', (WidgetTester tester) async {
    final store = TaskStore(repository: MemoryTaskRepository());

    await tester.pumpWidget(MaterialApp(home: HomePage(store: store)));
    await tester.pump();

    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Upcoming'), findsOneWidget);
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    await tester.tap(find.text('Upcoming'));
    await tester.pump();
    expect(find.text('Nothing upcoming'), findsOneWidget);

    await tester.tap(find.text('Done'));
    await tester.pump();
    expect(find.text('Nothing completed yet'), findsOneWidget);

    await tester.tap(find.text('Settings'));
    await tester.pump();
    expect(find.text('Local storage'), findsOneWidget);

    store.dispose();
  });
}
