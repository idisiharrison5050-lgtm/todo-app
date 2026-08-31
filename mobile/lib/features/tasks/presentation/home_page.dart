import 'package:flutter/material.dart';

import '../application/task_store.dart';
import '../domain/task.dart';
import 'add_task_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.store});
  final TaskStore store;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    const titles = ['Today', 'Upcoming', 'All Tasks', 'Completed', 'Settings'];
    return Scaffold(
      body: AnimatedBuilder(
        animation: widget.store,
        builder: (context, _) => IndexedStack(index: _index, children: [
          TaskListView(store: widget.store, filter: TaskFilter.today, title: titles[0]),
          TaskListView(store: widget.store, filter: TaskFilter.upcoming, title: titles[1]),
          TaskListView(store: widget.store, filter: TaskFilter.all, title: titles[2]),
          TaskListView(store: widget.store, filter: TaskFilter.completed, title: titles[3]),
          const SettingsView(),
        ]),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.today_outlined), selectedIcon: Icon(Icons.today), label: 'Today'),
          NavigationDestination(icon: Icon(Icons.event_outlined), selectedIcon: Icon(Icons.event), label: 'Upcoming'),
          NavigationDestination(icon: Icon(Icons.checklist_outlined), selectedIcon: Icon(Icons.checklist), label: 'All'),
          NavigationDestination(icon: Icon(Icons.task_alt_outlined), selectedIcon: Icon(Icons.task_alt), label: 'Done'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
      floatingActionButton: _index == 4 ? null : FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => AddTaskPage(store: widget.store))),
        icon: const Icon(Icons.add), label: const Text('Add task'),
      ),
    );
  }
}

enum TaskFilter { today, upcoming, all, completed }

class TaskListView extends StatelessWidget {
  const TaskListView({super.key, required this.store, required this.filter, required this.title});
  final TaskStore store;
  final TaskFilter filter;
  final String title;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final all = store.tasks;
    final completed = all.where((task) => task.isCompleted).length;
    final visible = all.where((task) {
      if (filter == TaskFilter.completed) return task.isCompleted;
      if (task.isCompleted) return false;
      if (filter == TaskFilter.all) return true;
      if (task.dueAt == null) return filter == TaskFilter.today;
      final due = task.dueAt!;
      if (filter == TaskFilter.today) return due.year == now.year && due.month == now.month && due.day == now.day;
      return due.isAfter(DateTime(now.year, now.month, now.day + 1));
    }).toList()..sort((a, b) {
      if (a.dueAt == null && b.dueAt == null) return 0;
      if (a.dueAt == null) return 1;
      if (b.dueAt == null) return -1;
      return a.dueAt!.compareTo(b.dueAt!);
    });

    return SafeArea(child: CustomScrollView(slivers: [
      SliverPadding(padding: const EdgeInsets.fromLTRB(20, 24, 20, 12), sliver: SliverToBoxAdapter(child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.8)),
          if (filter == TaskFilter.today) ...[const SizedBox(height: 4), Text(_dateLabel(now), style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant))],
        ])),
        if (filter != TaskFilter.completed) Chip(label: Text('$completed done')),
      ]))),
      if (filter == TaskFilter.today) SliverPadding(padding: const EdgeInsets.fromLTRB(20, 8, 20, 12), sliver: SliverToBoxAdapter(child: _ProgressCard(total: all.length, completed: completed))),
      if (visible.isEmpty)
        SliverPadding(padding: const EdgeInsets.fromLTRB(20, 24, 20, 120), sliver: SliverToBoxAdapter(child: _EmptyTasks(filter: filter)))
      else
        SliverPadding(padding: const EdgeInsets.fromLTRB(20, 8, 20, 120), sliver: SliverList.separated(
          itemCount: visible.length,
          itemBuilder: (context, index) => _TaskCard(task: visible[index], store: store, now: now),
          separatorBuilder: (_, __) => const SizedBox(height: 10),
        )),
    ]));
  }

  String _dateLabel(DateTime date) => '${const ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'][date.weekday - 1]}, ${const ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'][date.month - 1]} ${date.day}';
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({required this.task, required this.store, required this.now});
  final Task task;
  final TaskStore store;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final overdue = task.dueAt != null && task.dueAt!.isBefore(now) && !task.isCompleted;
    final scheme = Theme.of(context).colorScheme;
    return Dismissible(
      key: ValueKey(task.id), direction: DismissDirection.endToStart,
      background: Container(alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 24), decoration: BoxDecoration(color: scheme.errorContainer, borderRadius: BorderRadius.circular(20)), child: Icon(Icons.delete_outline, color: scheme.onErrorContainer)),
      confirmDismiss: (_) => _confirmDelete(context), onDismissed: (_) => store.deleteTask(task.id),
      child: Card(child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        leading: Checkbox(value: task.isCompleted, onChanged: (_) => store.toggleCompleted(task.id)),
        title: Text(task.title, style: TextStyle(decoration: task.isCompleted ? TextDecoration.lineThrough : null, fontWeight: FontWeight.w700)),
        subtitle: _subtitle(context, overdue),
        trailing: IconButton(tooltip: 'Edit task', onPressed: () => _edit(context), icon: const Icon(Icons.more_horiz)),
        onTap: () => _edit(context),
      )),
    );
  }

  Widget? _subtitle(BuildContext context, bool overdue) {
    final parts = <String>[];
    if (task.dueAt != null) parts.add('${overdue ? 'Overdue' : 'Due'} ${TimeOfDay.fromDateTime(task.dueAt!).format(context)}');
    if (task.priority == TaskPriority.high) parts.add('High priority');
    if (task.reminderType != TaskReminderType.none) parts.add(task.reminderType == TaskReminderType.interval ? 'Repeating reminder' : 'Reminder');
    if (task.notes.isNotEmpty) parts.add(task.notes);
    return parts.isEmpty ? null : Text(parts.join(' • '), maxLines: 2, overflow: TextOverflow.ellipsis);
  }

  void _edit(BuildContext context) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => AddTaskPage(store: store, task: task)));

  Future<bool> _confirmDelete(BuildContext context) async {
    final result = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(
      title: const Text('Delete task?'), content: Text('Delete “${task.title}”? This cannot be undone.'),
      actions: [TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')), FilledButton.tonal(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Delete'))],
    ));
    return result ?? false;
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.total, required this.completed});
  final int total;
  final int completed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final progress = total == 0 ? 0.0 : completed / total;
    return Card(color: scheme.primaryContainer, child: Padding(padding: const EdgeInsets.all(18), child: Column(children: [
      Row(children: [Icon(Icons.check_circle_rounded, color: scheme.primary), const SizedBox(width: 10), Expanded(child: Text(total == 0 ? 'A fresh start' : '$completed of $total tasks completed', style: TextStyle(fontWeight: FontWeight.w800, color: scheme.onPrimaryContainer))), Text('${(progress * 100).round()}%', style: TextStyle(fontWeight: FontWeight.w800, color: scheme.onPrimaryContainer))]),
      const SizedBox(height: 12), ClipRRect(borderRadius: BorderRadius.circular(20), child: LinearProgressIndicator(value: progress, minHeight: 8)),
    ])));
  }
}

class _EmptyTasks extends StatelessWidget {
  const _EmptyTasks({required this.filter});
  final TaskFilter filter;

  @override
  Widget build(BuildContext context) {
    final text = switch (filter) {
      TaskFilter.completed => ('Nothing completed yet', 'Complete a task and it will appear here.'),
      TaskFilter.upcoming => ('Nothing upcoming', 'Schedule a task to see it here.'),
      TaskFilter.all => ('No active tasks', 'You are all caught up.'),
      TaskFilter.today => ('Nothing planned today', 'Add a task and choose when Todo should remind you.'),
    };
    final scheme = Theme.of(context).colorScheme;
    return Container(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48), decoration: BoxDecoration(border: Border.all(color: scheme.outlineVariant), borderRadius: BorderRadius.circular(24)), child: Column(children: [
      Icon(Icons.task_alt_rounded, size: 48, color: scheme.primary), const SizedBox(height: 16),
      Text(text.$1, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)), const SizedBox(height: 8),
      Text(text.$2, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
    ]));
  }
}

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(child: ListView(padding: const EdgeInsets.fromLTRB(20, 24, 20, 40), children: [
      Text('Settings', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
      const SizedBox(height: 8), Text('Your tasks and reminders are stored locally on this device.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
      const SizedBox(height: 24), Card(child: Column(children: const [
        ListTile(leading: Icon(Icons.notifications_active_outlined), title: Text('Notifications'), subtitle: Text('Permissions are requested when you create a reminder.')),
        Divider(height: 1), ListTile(leading: Icon(Icons.storage_outlined), title: Text('Local storage'), subtitle: Text('Tasks persist after closing and reopening the app.')),
        Divider(height: 1), ListTile(leading: Icon(Icons.alarm_outlined), title: Text('Exact reminders'), subtitle: Text('Android reminders target the selected minute.')),
      ])),
    ]));
  }
}
