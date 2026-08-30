import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:todo_mobile/features/tasks/application/task_store.dart';
import 'package:todo_mobile/features/tasks/data/preferences_task_repository.dart';
import 'package:todo_mobile/features/tasks/presentation/today_page.dart';

void main() {
  testWidgets('renders the Today screen', (WidgetTester tester) async {
    final store = TaskStore(repository: PreferencesTaskRepository());

    await tester.pumpWidget(
      MaterialApp(
        home: TodayPage(store: store),
      ),
    );
    await tester.pump();

    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Your tasks'), findsOneWidget);
    expect(find.text('Nothing planned yet'), findsOneWidget);
    expect(find.text('Add task'), findsOneWidget);

    store.dispose();
  });
}
