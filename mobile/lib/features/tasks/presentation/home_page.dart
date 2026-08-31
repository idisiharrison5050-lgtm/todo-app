import 'package:flutter/material.dart';

import '../application/task_store.dart';
import '../domain/task.dart';
import 'add_task_page.dart';
import 'task_detail_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.store});
  final TaskStore store;
  @override State<HomePage> createState() => _HomePageState();
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
      bottomNavigationBar: NavigationBar(selectedIndex: _index, onDestinationSelected: (value) => setState(() => _index = value), destinations: const [
        NavigationDestination(icon: Icon(Icons.today_outlined), selectedIcon: Icon(Icons.today), label: 'Today'),
        NavigationDestination(icon: Icon(Icons.event_outlined), selectedIcon: Icon(Icons.event), label: 'Upcoming'),
        NavigationDestination(icon: Icon(Icons.checklist_outlined), selectedIcon: Icon(Icons.checklist), label: 'All'),
        NavigationDestination(icon: Icon(Icons.task_alt_outlined), selectedIcon: Icon(Icons.task_alt), label: 'Done'),
        NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Settings'),
      ]),
      floatingActionButton: _index == 4 ? null : FloatingActionButton.extended(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => AddTaskPage(store: widget.store))), icon: const Icon(Icons.add), label: const Text('Add task')),
    );
  }
}

enum TaskFilter { today, upcoming, all, completed }

class TaskListView extends StatefulWidget {
  const TaskListView({super.key, required this.store, required this.filter, required this.title});
  final TaskStore store; final TaskFilter filter; final String title;
  @override State<TaskListView> createState() => _TaskListViewState();
}

class _TaskListViewState extends State<TaskListView> {
  String _query = '';
  TaskPriority? _priorityFilter;
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now(); final all = widget.store.tasks; final completed = all.where((task) => task.isCompleted).length; final active = all.length - completed;
    final visible = all.where(_matchesFilter).where(_matchesPriority).toList()..sort(_compareTasks); final query = _query.trim().toLowerCase();
    final filtered = query.isEmpty ? visible : visible.where((task) => '${task.title} ${task.notes}'.toLowerCase().contains(query)).toList();
    return SafeArea(child: CustomScrollView(slivers: [
      SliverPadding(padding: const EdgeInsets.fromLTRB(20, 24, 20, 8), sliver: SliverToBoxAdapter(child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(widget.title, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.8)), const SizedBox(height: 4), Text(widget.filter == TaskFilter.completed ? '$completed completed' : '$active active', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant))])), if (widget.filter == TaskFilter.today) Chip(label: Text('$active left')), if (widget.filter == TaskFilter.completed && completed > 0) IconButton(tooltip: 'Clear completed', onPressed: () => _clearCompleted(context), icon: const Icon(Icons.delete_sweep_outlined))]))),
      if (widget.filter != TaskFilter.completed && all.isNotEmpty) SliverPadding(padding: const EdgeInsets.fromLTRB(20, 4, 20, 4), sliver: SliverToBoxAdapter(child: Column(children: [TextField(onChanged: (value) => setState(() => _query = value), decoration: InputDecoration(hintText: 'Search tasks', prefixIcon: const Icon(Icons.search), suffixIcon: _query.isEmpty ? null : IconButton(onPressed: () => setState(() => _query = ''), icon: const Icon(Icons.clear)))), const SizedBox(height: 8), SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [FilterChip(label: const Text('All priorities'), selected: _priorityFilter == null, onSelected: (_) => setState(() => _priorityFilter = null)), const SizedBox(width: 8), FilterChip(label: const Text('High'), selected: _priorityFilter == TaskPriority.high, onSelected: (_) => setState(() => _priorityFilter = TaskPriority.high)), const SizedBox(width: 8), FilterChip(label: const Text('Normal'), selected: _priorityFilter == TaskPriority.normal, onSelected: (_) => setState(() => _priorityFilter = TaskPriority.normal)), const SizedBox(width: 8), FilterChip(label: const Text('Low'), selected: _priorityFilter == TaskPriority.low, onSelected: (_) => setState(() => _priorityFilter = TaskPriority.low))]))]))),
      if (widget.filter == TaskFilter.today) SliverPadding(padding: const EdgeInsets.fromLTRB(20, 8, 20, 12), sliver: SliverToBoxAdapter(child: _ProgressCard(total: all.length, completed: completed))),
      if (filtered.isEmpty) SliverPadding(padding: const EdgeInsets.fromLTRB(20, 24, 20, 120), sliver: SliverToBoxAdapter(child: _EmptyTasks(filter: widget.filter, searching: _query.isNotEmpty || _priorityFilter != null))) else if (widget.filter == TaskFilter.upcoming) _UpcomingGroups(tasks: filtered, store: widget.store) else SliverPadding(padding: const EdgeInsets.fromLTRB(20, 8, 20, 120), sliver: SliverList.separated(itemCount: filtered.length, itemBuilder: (context, index) => _TaskCard(task: filtered[index], store: widget.store, now: now, showOverdue: widget.filter == TaskFilter.today), separatorBuilder: (_, index) => const SizedBox(height: 10))),
    ]));
  }
  bool _matchesPriority(Task task) => _priorityFilter == null || task.priority == _priorityFilter;
  bool _matchesFilter(Task task) { if (widget.filter == TaskFilter.completed) return task.isCompleted; if (task.isCompleted) return false; if (widget.filter == TaskFilter.all) return true; final due = task.dueAt; if (due == null) return widget.filter == TaskFilter.today; final now = DateTime.now(); final today = DateTime(now.year, now.month, now.day); final tomorrow = today.add(const Duration(days: 1)); if (widget.filter == TaskFilter.today) return due.isBefore(tomorrow); return !due.isBefore(tomorrow); }
  int _compareTasks(Task a, Task b) { if (a.dueAt == null && b.dueAt == null) return b.priority.index.compareTo(a.priority.index); if (a.dueAt == null) return 1; if (b.dueAt == null) return -1; final compare = a.dueAt!.compareTo(b.dueAt!); return compare != 0 ? compare : b.priority.index.compareTo(a.priority.index); }
  Future<void> _clearCompleted(BuildContext context) async { final confirmed = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(title: const Text('Clear completed tasks?'), content: const Text('This permanently removes every completed task.'), actions: [TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Clear all'))])); if (confirmed == true) await widget.store.clearCompleted(); }
}

class _UpcomingGroups extends StatelessWidget {
  const _UpcomingGroups({required this.tasks, required this.store}); final List<Task> tasks; final TaskStore store;
  @override Widget build(BuildContext context) { final groups = <String, List<Task>>{}; for (final task in tasks) { groups.putIfAbsent(_groupLabel(task.dueAt!), () => <Task>[]).add(task); } final keys = groups.keys.toList(); return SliverPadding(padding: const EdgeInsets.fromLTRB(20, 8, 20, 120), sliver: SliverList.builder(itemCount: keys.length, itemBuilder: (context, index) => Padding(padding: EdgeInsets.only(bottom: index == keys.length - 1 ? 0 : 20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Padding(padding: const EdgeInsets.only(bottom: 10, left: 4), child: Text(keys[index], style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800))), ...groups[keys[index]]!.map((task) => Padding(padding: const EdgeInsets.only(bottom: 10), child: _TaskCard(task: task, store: store, now: DateTime.now(), showOverdue: false)))])))); }
  String _groupLabel(DateTime value) { final now = DateTime.now(); final today = DateTime(now.year, now.month, now.day); final date = DateTime(value.year, value.month, value.day); final days = date.difference(today).inDays; if (days == 1) return 'Tomorrow'; if (days <= 7) return 'This week'; if (date.year == today.year && date.month == today.month) return 'Later this month'; return '${value.day}/${value.month}/${value.year}'; }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({required this.task, required this.store, required this.now, required this.showOverdue}); final Task task; final TaskStore store; final DateTime now; final bool showOverdue;
  @override Widget build(BuildContext context) { final overdue = task.dueAt != null && task.dueAt!.isBefore(now) && !task.isCompleted; final scheme = Theme.of(context).colorScheme; final priorityIcon = switch (task.priority) { TaskPriority.high => Icons.priority_high_rounded, TaskPriority.normal => Icons.remove_rounded, TaskPriority.low => Icons.arrow_downward_rounded }; return Dismissible(key: ValueKey(task.id), direction: DismissDirection.endToStart, background: Container(alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 24), decoration: BoxDecoration(color: scheme.errorContainer, borderRadius: BorderRadius.circular(20)), child: Icon(Icons.delete_outline, color: scheme.onErrorContainer)), confirmDismiss: (_) => _confirmDelete(context), onDismissed: (_) => store.deleteTask(task.id), child: Card(child: ListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7), leading: Checkbox(value: task.isCompleted, onChanged: (_) => store.toggleCompleted(task.id)), title: Row(children: [Expanded(child: Text(task.title, style: TextStyle(decoration: task.isCompleted ? TextDecoration.lineThrough : null, fontWeight: FontWeight.w700))), if (task.priority != TaskPriority.normal) Icon(priorityIcon, size: 18, color: task.priority == TaskPriority.high ? scheme.error : scheme.primary)]), subtitle: _subtitle(context, overdue), trailing: IconButton(tooltip: 'Task details', onPressed: () => _openDetails(context), icon: const Icon(Icons.more_horiz)), onTap: () => _openDetails(context)))); }
  Widget? _subtitle(BuildContext context, bool overdue) { final parts = <String>[]; if (task.dueAt != null) parts.add('${overdue && showOverdue ? 'Overdue' : 'Due'} ${TimeOfDay.fromDateTime(task.dueAt!).format(context)}'); if (task.reminderType != TaskReminderType.none) parts.add(task.reminderType == TaskReminderType.interval ? 'Repeating reminder' : 'Reminder set'); if (task.notes.isNotEmpty) parts.add(task.notes); return parts.isEmpty ? null : Text(parts.join(' • '), maxLines: 2, overflow: TextOverflow.ellipsis); }
  void _openDetails(BuildContext context) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => TaskDetailPage(store: store, task: task)));
  Future<bool> _confirmDelete(BuildContext context) async { final result = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(title: const Text('Delete task?'), content: Text('Delete “${task.title}”? This cannot be undone.'), actions: [TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')), FilledButton.tonal(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Delete'))])); return result ?? false; }
}

class _ProgressCard extends StatelessWidget { const _ProgressCard({required this.total, required this.completed}); final int total; final int completed; @override Widget build(BuildContext context) { final scheme = Theme.of(context).colorScheme; final progress = total == 0 ? 0.0 : completed / total; return Card(color: scheme.primaryContainer, child: Padding(padding: const EdgeInsets.all(18), child: Column(children: [Row(children: [Icon(Icons.check_circle_rounded, color: scheme.primary), const SizedBox(width: 10), Expanded(child: Text(total == 0 ? 'A fresh start' : '$completed of $total tasks completed', style: TextStyle(fontWeight: FontWeight.w800, color: scheme.onPrimaryContainer))), Text('${(progress * 100).round()}%', style: TextStyle(fontWeight: FontWeight.w800, color: scheme.onPrimaryContainer))]), const SizedBox(height: 12), ClipRRect(borderRadius: BorderRadius.circular(20), child: LinearProgressIndicator(value: progress, minHeight: 8))]))); } }

class _EmptyTasks extends StatelessWidget { const _EmptyTasks({required this.filter, this.searching = false}); final TaskFilter filter; final bool searching; @override Widget build(BuildContext context) { final text = searching ? ('No matching tasks', 'Try a different title, note, or priority.') : switch (filter) { TaskFilter.completed => ('Nothing completed yet', 'Complete a task and it will appear here.'), TaskFilter.upcoming => ('Nothing upcoming', 'Schedule a task to see it here.'), TaskFilter.all => ('No active tasks', 'You are all caught up.'), TaskFilter.today => ('Nothing planned today', 'Add a task and choose when Todo should remind you.') }; final scheme = Theme.of(context).colorScheme; return Container(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48), decoration: BoxDecoration(border: Border.all(color: scheme.outlineVariant), borderRadius: BorderRadius.circular(24)), child: Column(children: [Icon(Icons.task_alt_rounded, size: 48, color: scheme.primary), const SizedBox(height: 16), Text(text.$1, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)), const SizedBox(height: 8), Text(text.$2, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant))])); } }

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});
  @override Widget build(BuildContext context) => SafeArea(child: ListView(padding: const EdgeInsets.fromLTRB(20, 24, 20, 40), children: [Text('Settings', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)), const SizedBox(height: 8), Text('Todo keeps your tasks and reminders on this device.', style: Theme.of(context).textTheme.bodyMedium), const SizedBox(height: 24), Card(child: Column(children: const [ListTile(leading: Icon(Icons.notifications_active_outlined), title: Text('Notifications'), subtitle: Text('Reminder notifications are enabled for scheduled tasks.')), Divider(height: 1), ListTile(leading: Icon(Icons.storage_outlined), title: Text('Local storage'), subtitle: Text('Tasks persist after closing and reopening the app.')), Divider(height: 1), ListTile(leading: Icon(Icons.alarm_outlined), title: Text('Exact reminders'), subtitle: Text('Reminders target the selected minute and can fire while idle.'))])), const SizedBox(height: 20), const Card(child: ListTile(leading: CircleAvatar(child: Icon(Icons.check_rounded)), title: Text('Todo'), subtitle: Text('Simple tasks. Clear focus.'), trailing: Text('v1.0')))]));
}
