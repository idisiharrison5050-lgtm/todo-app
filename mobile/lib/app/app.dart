import 'package:flutter/material.dart';

import 'theme/app_theme.dart';
import '../features/reminders/data/local_notification_service.dart';
import '../features/tasks/application/task_store.dart';
import '../features/tasks/domain/task.dart';
import '../features/tasks/presentation/home_page.dart';
import '../features/tasks/presentation/task_detail_page.dart';

class TodoApp extends StatefulWidget {
  const TodoApp({super.key});

  @override
  State<TodoApp> createState() => _TodoAppState();
}

class _TodoAppState extends State<TodoApp> {
  late final TaskStore _taskStore;
  late final Future<void> _loadFuture;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _taskStore = TaskStore();
    LocalNotificationService.onNotificationTap = _openTaskFromNotification;
    _loadFuture = _taskStore.load();
  }

  void _openTaskFromNotification(String taskId) {
    final context = _navigatorKey.currentContext;
    if (context == null) return;
    final matches = _taskStore.tasks.where((task) => task.id == taskId);
    if (matches.isEmpty) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => TaskDetailPage(store: _taskStore, task: matches.first),
    ));
  }

  @override
  void dispose() {
    LocalNotificationService.onNotificationTap = null;
    _taskStore.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'Todo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: FutureBuilder<void>(
        future: _loadFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          return HomePage(store: _taskStore);
        },
      ),
    );
  }
}
