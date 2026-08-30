import 'package:flutter/material.dart';

import 'theme/app_theme.dart';
import '../features/tasks/application/task_store.dart';
import '../features/tasks/presentation/add_task_page.dart';
import '../features/tasks/presentation/today_page.dart';

class TodoApp extends StatefulWidget {
  const TodoApp({super.key});

  @override
  State<TodoApp> createState() => _TodoAppState();
}

class _TodoAppState extends State<TodoApp> {
  final TaskStore _taskStore = TaskStore();

  @override
  void dispose() {
    _taskStore.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Todo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: TodayPage(store: _taskStore),
    );
  }
}

class TodoAppShell extends StatelessWidget {
  const TodoAppShell({super.key, required this.store});

  final TaskStore store;

  @override
  Widget build(BuildContext context) {
    return TodayPage(store: store);
  }
}
