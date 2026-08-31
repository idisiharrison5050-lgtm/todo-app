import 'package:flutter/material.dart';

import 'theme/app_theme.dart';
import '../features/reminders/data/local_notification_service.dart';
import '../features/tasks/application/task_store.dart';
import '../features/tasks/presentation/home_page.dart';
import '../features/tasks/presentation/task_detail_page.dart';

class TodoApp extends StatefulWidget {
  const TodoApp({super.key});
  @override State<TodoApp> createState() => _TodoAppState();
}

class _TodoAppState extends State<TodoApp> {
  late final TaskStore _taskStore;
  late final Future<void> _loadFuture;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override void initState() { super.initState(); _taskStore = TaskStore(); LocalNotificationService.onNotificationTap = _openTaskFromNotification; _loadFuture = _taskStore.load(); }
  void _openTaskFromNotification(String taskId) { final context = _navigatorKey.currentContext; if (context == null) return; final matches = _taskStore.tasks.where((task) => task.id == taskId); if (matches.isEmpty) return; Navigator.of(context).push(MaterialPageRoute(builder: (_) => TaskDetailPage(store: _taskStore, task: matches.first))); }
  @override void dispose() { LocalNotificationService.onNotificationTap = null; _taskStore.dispose(); super.dispose(); }

  @override Widget build(BuildContext context) => MaterialApp(
    navigatorKey: _navigatorKey,
    title: 'Todo',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    darkTheme: AppTheme.dark,
    themeMode: ThemeMode.system,
    themeAnimationDuration: const Duration(milliseconds: 350),
    themeAnimationCurve: Curves.easeOutCubic,
    builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)), child: child ?? const SizedBox.shrink()),
    home: FutureBuilder<void>(future: _loadFuture, builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) return const _PremiumLoading();
      if (snapshot.hasError) return _LoadError(onRetry: () => setState(() {}));
      return HomePage(store: _taskStore);
    }),
  );
}

class _PremiumLoading extends StatelessWidget {
  const _PremiumLoading();
  @override Widget build(BuildContext context) => Scaffold(body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Container(width: 64, height: 64, decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, borderRadius: BorderRadius.circular(20)), child: const Icon(Icons.check_rounded, color: Colors.white, size: 34)), const SizedBox(height: 22), Text('Preparing your workspace', style: Theme.of(context).textTheme.titleMedium), const SizedBox(height: 12), const SizedBox(width: 120, child: LinearProgressIndicator(minHeight: 3))]));
}
class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry}); final VoidCallback onRetry;
  @override Widget build(BuildContext context) => Scaffold(body: Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.cloud_off_rounded, size: 48, color: Theme.of(context).colorScheme.error), const SizedBox(height: 16), Text('We could not load your workspace', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge), const SizedBox(height: 8), const Text('Your tasks are safe. Try loading them again.', textAlign: TextAlign.center), const SizedBox(height: 20), FilledButton(onPressed: onRetry, child: const Text('Try again'))]))));
}
