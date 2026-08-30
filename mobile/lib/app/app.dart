import 'package:flutter/material.dart';

import 'theme/app_theme.dart';
import '../features/tasks/application/task_store.dart';
import '../features/tasks/presentation/today_page.dart';

class TodoApp extends StatefulWidget {
  const TodoApp({super.key});

  @override
  State<TodoApp> createState() => _TodoAppState();
}

class _TodoAppState extends State<TodoApp> {
  late final TaskStore _taskStore;
  late final Future<void> _loadFuture;

  @override
  void initState() {
    super.initState();
    _taskStore = TaskStore();
    _loadFuture = _taskStore.load();
  }

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
      home: FutureBuilder<void>(
        future: _loadFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return TodayPage(store: _taskStore);
        },
      ),
    );
  }
}
