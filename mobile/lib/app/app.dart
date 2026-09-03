import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import '../features/auth/application/auth_store.dart';
import '../features/auth/presentation/auth_page.dart';
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
  late final AuthStore _authStore;
  late Future<void> _loadFuture;
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _taskStore = TaskStore();
    _authStore = AuthStore();
    LocalNotificationService.onNotificationTap = _openTask;
    _loadFuture = _initialize();
  }

  Future<void> _initialize() async {
    await _authStore.restore();
    await _taskStore.load();
  }

  void _openTask(String id) {
    final context = _navigatorKey.currentContext;
    if (context == null) return;
    for (final task in _taskStore.tasks) {
      if (task.id == id) {
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => TaskDetailPage(store: _taskStore, task: task)));
        break;
      }
    }
  }

  void _authenticated() => setState(() {});

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
      themeAnimationDuration: const Duration(milliseconds: 350),
      themeAnimationCurve: Curves.easeOutCubic,
      home: FutureBuilder<void>(
        future: _loadFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) return const _Loading();
          if (snapshot.hasError) return _Error(onRetry: () => setState(() => _loadFuture = _initialize()));
          if (!_authStore.hasSession) return AuthPage(store: _authStore, onAuthenticated: _authenticated);
          return HomePage(store: _taskStore, onLogout: _logout);
        },
      ),
    );
  }

  Future<void> _logout() async {
    final context = _navigatorKey.currentContext;
    if (context == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You will stay logged out until you sign in again. Reminders already scheduled on this device will continue to work.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Log out')),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    await _authStore.logout();
    if (mounted) setState(() {});
  }
}

class _Loading extends StatelessWidget {
  const _Loading();
  @override Widget build(BuildContext context) => Scaffold(body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 64, height: 64, decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, borderRadius: BorderRadius.circular(20)), child: const Icon(Icons.check_rounded, color: Colors.white, size: 34)),
    const SizedBox(height: 20), Text('Preparing your workspace', style: Theme.of(context).textTheme.titleMedium), const SizedBox(height: 12),
    const SizedBox(width: 120, child: LinearProgressIndicator(minHeight: 3)),
  ])));
}

class _Error extends StatelessWidget {
  const _Error({required this.onRetry});
  final VoidCallback onRetry;
  @override Widget build(BuildContext context) => Scaffold(body: Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisSize: MainAxisSize.min, children: [
    Icon(Icons.cloud_off_rounded, size: 48, color: Theme.of(context).colorScheme.error), const SizedBox(height: 16),
    Text('We could not load your workspace', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge), const SizedBox(height: 8),
    const Text('Your tasks are safe. Try loading them again.', textAlign: TextAlign.center), const SizedBox(height: 20), FilledButton(onPressed: onRetry, child: const Text('Try again')),
  ]))));
}
