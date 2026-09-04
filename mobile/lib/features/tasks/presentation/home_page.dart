import 'dart:async';

import 'package:flutter/material.dart';

import '../application/task_store.dart';
import '../domain/task.dart';
import 'add_task_page.dart';
import 'calendar_page.dart';
import 'task_detail_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.store, required this.onLogout});

  final TaskStore store;
  final Future<void> Function() onLogout;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;

  void _addTask() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AddTaskPage(store: widget.store)),
    );
  }

  void _openAllTasks() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('All tasks')),
          body: TaskListView(
            store: widget.store,
            filter: TaskFilter.all,
            title: 'All tasks',
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      _HomeOverview(store: widget.store, onAddTask: _addTask, onOpenAll: _openAllTasks),
      TaskListView(store: widget.store, filter: TaskFilter.today, title: 'Today'),
      CalendarPage(store: widget.store),
      FocusView(store: widget.store),
      SettingsView(onLogout: widget.onLogout),
    ];

    return Scaffold(
      body: AnimatedBuilder(
        animation: widget.store,
        builder: (context, child) => IndexedStack(index: _index, children: pages),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.today_outlined),
            selectedIcon: Icon(Icons.today_rounded),
            label: 'Today',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month_rounded),
            label: 'Calendar',
          ),
          NavigationDestination(
            icon: Icon(Icons.center_focus_weak),
            selectedIcon: Icon(Icons.center_focus_strong),
            label: 'Focus',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
      floatingActionButton: _index == 4 || _index == 2
          ? null
          : FloatingActionButton.extended(
              onPressed: _addTask,
              icon: const Icon(Icons.add_rounded),
              label: Text(_index == 3 ? 'Add focus task' : 'New task'),
            ),
    );
  }
}

class _HomeOverview extends StatelessWidget {
  const _HomeOverview({
    required this.store,
    required this.onAddTask,
    required this.onOpenAll,
  });

  final TaskStore store;
  final VoidCallback onAddTask;
  final VoidCallback onOpenAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final now = DateTime.now();
    final tasks = store.tasks;
    final completed = tasks.where((task) => task.isCompleted).length;
    final active = tasks.where((task) => !task.isCompleted).toList();
    final overdue = active.where((task) => task.dueAt != null && task.dueAt!.isBefore(now)).length;
    final today = active.where((task) => _isToday(task.dueAt, now)).toList()
      ..sort(_sortByDue);
    final upcoming = active.where((task) => task.dueAt != null && task.dueAt!.isAfter(now)).toList()
      ..sort(_sortByDue);
    final favorites = active.where((task) => task.isFavorite).toList()
      ..sort(_sortByDue);
    final highPriority = active.where((task) => task.priority == TaskPriority.high).toList()
      ..sort(_sortByDue);
    final progress = tasks.isEmpty ? 0.0 : completed / tasks.length;

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_greeting(), style: theme.textTheme.bodyMedium),
                        const SizedBox(height: 3),
                        Text(_dateLabel(context, now), style: theme.textTheme.headlineMedium),
                      ],
                    ),
                  ),
                  IconButton.filledTonal(
                    tooltip: 'Quick add task',
                    onPressed: onAddTask,
                    icon: const Icon(Icons.add_rounded),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
            sliver: SliverToBoxAdapter(
              child: _HeroProgress(
                progress: progress,
                completed: completed,
                total: tasks.length,
                overdue: overdue,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Expanded(child: _StatTile(icon: Icons.today_rounded, value: '${today.length}', label: 'Today')),
                  const SizedBox(width: 8),
                  Expanded(child: _StatTile(icon: Icons.priority_high_rounded, value: '${highPriority.length}', label: 'Priority')),
                  const SizedBox(width: 8),
                  Expanded(child: _StatTile(icon: Icons.star_rounded, value: '${favorites.length}', label: 'Favorites')),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Expanded(child: Text('Today', style: theme.textTheme.titleLarge)),
                  TextButton(onPressed: onOpenAll, child: const Text('All tasks')),
                ],
              ),
            ),
          ),
          if (today.isEmpty)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              sliver: SliverToBoxAdapter(child: _EmptyPanel(onAddTask: onAddTask)),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              sliver: SliverList.separated(
                itemCount: today.take(4).length,
                itemBuilder: (context, index) => _CompactTaskTile(
                  task: today[index],
                  store: store,
                ),
                separatorBuilder: (context, index) => const SizedBox(height: 8),
              ),
            ),
          if (overdue > 0)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
              sliver: SliverToBoxAdapter(child: _AttentionBanner(count: overdue)),
            ),
          if (highPriority.isNotEmpty) ...[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Expanded(child: Text('Priority', style: theme.textTheme.titleLarge)),
                    Icon(Icons.bolt_rounded, color: scheme.error),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              sliver: SliverList.separated(
                itemCount: highPriority.take(3).length,
                itemBuilder: (context, index) => _CompactTaskTile(
                  task: highPriority[index],
                  store: store,
                  accent: scheme.error,
                ),
                separatorBuilder: (context, index) => const SizedBox(height: 8),
              ),
            ),
          ],
          if (favorites.isNotEmpty) ...[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              sliver: SliverToBoxAdapter(child: Text('Favorites', style: theme.textTheme.titleLarge)),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              sliver: SliverToBoxAdapter(
                child: SizedBox(
                  height: 116,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: favorites.take(5).length,
                    itemBuilder: (context, index) => _FavoriteCard(
                      task: favorites[index],
                      store: store,
                    ),
                    separatorBuilder: (context, index) => const SizedBox(width: 10),
                  ),
                ),
              ),
            ),
          ],
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
            sliver: SliverToBoxAdapter(
              child: _UpcomingStrip(
                tasks: upcoming,
                onOpenCalendar: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => CalendarPage(store: store)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static bool _isToday(DateTime? value, DateTime now) {
    return value != null &&
        value.year == now.year &&
        value.month == now.month &&
        value.day == now.day;
  }

  static int _sortByDue(Task a, Task b) {
    if (a.dueAt == null && b.dueAt == null) return 0;
    if (a.dueAt == null) return 1;
    if (b.dueAt == null) return -1;
    return a.dueAt!.compareTo(b.dueAt!);
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  String _dateLabel(BuildContext context, DateTime value) {
    return MaterialLocalizations.of(context).formatMediumDate(value);
  }
}

class _HeroProgress extends StatelessWidget {
  const _HeroProgress({
    required this.progress,
    required this.completed,
    required this.total,
    required this.overdue,
  });

  final double progress;
  final int completed;
  final int total;
  final int overdue;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final percent = (progress * 100).round();
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [scheme.primary, scheme.tertiary],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Your day, in control.',
                  style: TextStyle(
                    color: scheme.onPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Icon(Icons.auto_awesome_rounded, color: scheme.onPrimary),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              SizedBox(
                width: 72,
                height: 72,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 7,
                      backgroundColor: scheme.onPrimary.withValues(alpha: .16),
                      color: scheme.onPrimary,
                    ),
                    Text(
                      '$percent%',
                      style: TextStyle(
                        color: scheme.onPrimary,
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$completed of $total completed',
                      style: TextStyle(
                        color: scheme.onPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      overdue == 0
                          ? 'You are on track. Keep the momentum.'
                          : '$overdue task${overdue == 1 ? '' : 's'} need your attention.',
                      style: TextStyle(
                        color: scheme.onPrimary.withValues(alpha: .82),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.icon, required this.value, required this.label});

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 10, 13),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: .62),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: scheme.primary),
          const SizedBox(height: 9),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 1),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _CompactTaskTile extends StatelessWidget {
  const _CompactTaskTile({required this.task, required this.store, this.accent});

  final Task task;
  final TaskStore store;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final due = task.dueAt;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => TaskDetailPage(store: store, task: task),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 14, 10),
          child: Row(
            children: [
              Checkbox(
                value: task.isCompleted,
                onChanged: (_) => store.toggleCompleted(task.id),
              ),
              Container(
                width: 4,
                height: 42,
                decoration: BoxDecoration(
                  color: accent ?? scheme.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (due != null) ...[
                          Icon(Icons.schedule_rounded, size: 14, color: accent ?? scheme.primary),
                          const SizedBox(width: 4),
                          Text(TimeOfDay.fromDateTime(due).format(context)),
                        ],
                        if (task.category.isNotEmpty) ...[
                          if (due != null) const SizedBox(width: 8),
                          Flexible(child: Text(task.category, overflow: TextOverflow.ellipsis)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FavoriteCard extends StatelessWidget {
  const _FavoriteCard({required this.task, required this.store});

  final Task task;
  final TaskStore store;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 210,
      child: Card(
        color: scheme.primaryContainer.withValues(alpha: .65),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TaskDetailPage(store: store, task: task),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.star_rounded, color: scheme.primary),
                const Spacer(),
                Text(
                  task.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UpcomingStrip extends StatelessWidget {
  const _UpcomingStrip({required this.tasks, required this.onOpenCalendar});

  final List<Task> tasks;
  final VoidCallback onOpenCalendar;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Coming up',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
                TextButton(onPressed: onOpenCalendar, child: const Text('Calendar')),
              ],
            ),
            if (tasks.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('Nothing scheduled next.'),
              ),
            ...tasks.take(3).map(
              (task) => Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  children: [
                    Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: scheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        task.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Text(TimeOfDay.fromDateTime(task.dueAt!).format(context)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttentionBanner extends StatelessWidget {
  const _AttentionBanner({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: scheme.onErrorContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$count overdue task${count == 1 ? '' : 's'}',
              style: TextStyle(
                color: scheme.onErrorContainer,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            'Review',
            style: TextStyle(
              color: scheme.onErrorContainer,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({required this.onAddTask});

  final VoidCallback onAddTask;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.wb_sunny_outlined, color: scheme.primary),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Your day is clear', style: TextStyle(fontWeight: FontWeight.w900)),
                  SizedBox(height: 3),
                  Text('Add something worth getting done.'),
                ],
              ),
            ),
            IconButton(onPressed: onAddTask, icon: const Icon(Icons.add_rounded)),
          ],
        ),
      ),
    );
  }
}

enum TaskFilter { today, upcoming, all, completed }

class TaskListView extends StatefulWidget {
  const TaskListView({super.key, required this.store, required this.filter, required this.title});

  final TaskStore store;
  final TaskFilter filter;
  final String title;

  @override
  State<TaskListView> createState() => _TaskListViewState();
}

class _TaskListViewState extends State<TaskListView> {
  String _query = '';
  TaskPriority? _priorityFilter;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final all = widget.store.tasks;
    final completed = all.where((task) => task.isCompleted).length;
    final active = all.length - completed;
    final visible = all
        .where((task) => _matchesFilter(task, now))
        .where(_matchesPriority)
        .toList()
      ..sort(_compareTasks);
    final query = _query.trim().toLowerCase();
    final filtered = query.isEmpty
        ? visible
        : visible
            .where(
              (task) =>
                  '${task.title} ${task.notes} ${task.category} ${task.tags.join(' ')}'
                      .toLowerCase()
                      .contains(query),
            )
            .toList();

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 8),
            sliver: SliverToBoxAdapter(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.title, style: Theme.of(context).textTheme.headlineMedium),
                        const SizedBox(height: 4),
                        Text(_headerText(active, completed, filtered.length)),
                      ],
                    ),
                  ),
                  if (widget.filter == TaskFilter.today)
                    Chip(
                      avatar: const Icon(Icons.bolt_rounded, size: 16),
                      label: Text('${filtered.length} left'),
                    ),
                  if (widget.filter == TaskFilter.completed && completed > 0)
                    IconButton(
                      tooltip: 'Clear completed',
                      onPressed: () => _clearCompleted(context),
                      icon: const Icon(Icons.delete_sweep_outlined),
                    ),
                ],
              ),
            ),
          ),
          if (all.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
              sliver: SliverToBoxAdapter(
                child: Column(
                  children: [
                    TextField(
                      onChanged: (value) => setState(() => _query = value),
                      decoration: InputDecoration(
                        hintText: 'Search title, notes, tags…',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _query.isEmpty
                            ? null
                            : IconButton(
                                onPressed: () => setState(() => _query = ''),
                                icon: const Icon(Icons.clear_rounded),
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          FilterChip(
                            label: const Text('All'),
                            selected: _priorityFilter == null,
                            onSelected: (_) => setState(() => _priorityFilter = null),
                          ),
                          const SizedBox(width: 8),
                          FilterChip(
                            label: const Text('High'),
                            selected: _priorityFilter == TaskPriority.high,
                            onSelected: (_) => setState(() => _priorityFilter = TaskPriority.high),
                          ),
                          const SizedBox(width: 8),
                          FilterChip(
                            label: const Text('Normal'),
                            selected: _priorityFilter == TaskPriority.normal,
                            onSelected: (_) => setState(() => _priorityFilter = TaskPriority.normal),
                          ),
                          const SizedBox(width: 8),
                          FilterChip(
                            label: const Text('Low'),
                            selected: _priorityFilter == TaskPriority.low,
                            onSelected: (_) => setState(() => _priorityFilter = TaskPriority.low),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (widget.filter == TaskFilter.today)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              sliver: SliverToBoxAdapter(
                child: _ProgressCard(total: all.length, completed: completed),
              ),
            ),
          if (filtered.isEmpty)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
              sliver: SliverToBoxAdapter(
                child: _EmptyTasks(
                  filter: widget.filter,
                  searching: _query.isNotEmpty || _priorityFilter != null,
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
              sliver: SliverList.separated(
                itemCount: filtered.length,
                itemBuilder: (context, index) => _TaskCard(
                  task: filtered[index],
                  store: widget.store,
                  now: now,
                  showOverdue: widget.filter == TaskFilter.today,
                ),
                separatorBuilder: (context, index) => const SizedBox(height: 10),
              ),
            ),
        ],
      ),
    );
  }

  String _headerText(int active, int completed, int shown) {
    if (widget.filter == TaskFilter.completed) return '$shown completed';
    if (widget.filter == TaskFilter.upcoming) return '$shown upcoming';
    if (widget.filter == TaskFilter.all) return '$shown active';
    return '$active active';
  }

  bool _matchesPriority(Task task) {
    return _priorityFilter == null || task.priority == _priorityFilter;
  }

  bool _matchesFilter(Task task, DateTime now) {
    if (widget.filter == TaskFilter.completed) return task.isCompleted;
    if (task.isCompleted) return false;
    if (widget.filter == TaskFilter.all) return true;
    final due = task.dueAt;
    if (due == null) return widget.filter == TaskFilter.today;
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    if (widget.filter == TaskFilter.today) return due.isBefore(tomorrow);
    if (widget.filter == TaskFilter.upcoming) return due.isAfter(now);
    return false;
  }

  int _compareTasks(Task a, Task b) {
    if (a.dueAt == null && b.dueAt == null) {
      return b.priority.index.compareTo(a.priority.index);
    }
    if (a.dueAt == null) return 1;
    if (b.dueAt == null) return -1;
    final compare = a.dueAt!.compareTo(b.dueAt!);
    return compare == 0 ? b.priority.index.compareTo(a.priority.index) : compare;
  }

  Future<void> _clearCompleted(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear completed tasks?'),
        content: const Text('This permanently removes every completed task.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Clear all')),
        ],
      ),
    );
    if (confirmed == true) await widget.store.clearCompleted();
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({required this.task, required this.store, required this.now, required this.showOverdue});

  final Task task;
  final TaskStore store;
  final DateTime now;
  final bool showOverdue;

  @override
  Widget build(BuildContext context) {
    final overdue = task.dueAt != null && task.dueAt!.isBefore(now) && !task.isCompleted;
    final scheme = Theme.of(context).colorScheme;
    return Dismissible(
      key: ValueKey(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: scheme.errorContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(Icons.delete_outline, color: scheme.onErrorContainer),
      ),
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) => store.deleteTask(task.id),
      child: Card(
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          leading: Checkbox(
            value: task.isCompleted,
            onChanged: (_) => store.toggleCompleted(task.id),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  task.title,
                  style: TextStyle(
                    decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (task.isFavorite)
                Icon(Icons.star_rounded, size: 18, color: scheme.primary),
              if (task.priority != TaskPriority.normal)
                Icon(
                  task.priority == TaskPriority.high
                      ? Icons.priority_high_rounded
                      : Icons.arrow_downward_rounded,
                  size: 18,
                  color: task.priority == TaskPriority.high ? scheme.error : scheme.primary,
                ),
            ],
          ),
          subtitle: _subtitle(context, overdue),
          trailing: PopupMenuButton<String>(
            tooltip: 'Task actions',
            icon: const Icon(Icons.more_horiz),
            onSelected: (value) => _handleAction(context, value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.edit_outlined),
                  title: Text('Edit task'),
                ),
              ),
              PopupMenuItem(
                value: 'complete',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.check_circle_outline),
                  title: Text('Mark complete'),
                ),
              ),
              const PopupMenuItem(
                value: 'reminder',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.notifications_outlined),
                  title: Text('Reminder & time'),
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.delete_outline),
                  title: Text('Delete task'),
                ),
              ),
            ],
          ),
          onTap: () => _openDetails(context),
        ),
      ),
    );
  }

  Widget? _subtitle(BuildContext context, bool overdue) {
    final parts = <String>[];
    if (task.dueAt != null) {
      parts.add(
        '${overdue && showOverdue ? 'Overdue' : 'Due'} ${TimeOfDay.fromDateTime(task.dueAt!).format(context)}',
      );
    }
    if (task.reminderType != TaskReminderType.none) {
      parts.add(
        task.reminderType == TaskReminderType.interval
            ? 'Repeating reminder'
            : 'Reminder set',
      );
    }
    if (task.category.isNotEmpty) parts.add(task.category);
    if (task.notes.isNotEmpty) parts.add(task.notes);
    return parts.isEmpty ? null : Text(parts.join(' • '), maxLines: 2, overflow: TextOverflow.ellipsis);
  }

  void _openDetails(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => TaskDetailPage(store: store, task: task)),
    );
  }

  Future<void> _handleAction(BuildContext context, String action) async {
    if (action == 'edit' || action == 'reminder') {
      _openDetails(context);
      return;
    }
    if (action == 'complete') {
      await store.toggleCompleted(task.id);
      return;
    }
    if (action == 'delete' && await _confirmDelete(context)) {
      await store.deleteTask(task.id);
    }
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete task?'),
        content: Text('Delete “${task.title}”? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          FilledButton.tonal(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Delete')),
        ],
      ),
    );
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
    return Card(
      color: scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: scheme.primary),
            const SizedBox(width: 10),
            Expanded(child: LinearProgressIndicator(value: progress, minHeight: 8)),
            const SizedBox(width: 10),
            Text('${(progress * 100).round()}%', style: TextStyle(fontWeight: FontWeight.w800, color: scheme.onPrimaryContainer)),
          ],
        ),
      ),
    );
  }
}

class _EmptyTasks extends StatelessWidget {
  const _EmptyTasks({required this.filter, this.searching = false});

  final TaskFilter filter;
  final bool searching;

  @override
  Widget build(BuildContext context) {
    final message = searching
        ? ('No matching tasks', 'Try a different title, note, tag, or priority.')
        : switch (filter) {
            TaskFilter.completed => ('Nothing completed yet', 'Complete a task and it will appear here.'),
            TaskFilter.upcoming => ('Nothing upcoming', 'Schedule a task to see it here.'),
            TaskFilter.all => ('No active tasks', 'You are all caught up.'),
            TaskFilter.today => ('Nothing planned today', 'Add a task and choose when Todo should remind you.'),
          };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Icon(Icons.task_alt_rounded, size: 48, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 16),
          Text(message.$1, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(message.$2, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class SettingsView extends StatelessWidget {
  const SettingsView({super.key, required this.onLogout});

  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 40),
        children: [
          Text('Settings', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 6),
          Text('Shape Todo around the way you work.', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 22),
          Card(
            child: Column(
              children: const [
                ListTile(
                  leading: Icon(Icons.notifications_active_outlined),
                  title: Text('Notifications'),
                  subtitle: Text('Scheduled reminders can alert you at the right time.'),
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.sync_rounded),
                  title: Text('Sync'),
                  subtitle: Text('Your tasks can work offline and sync when connected.'),
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.lock_outline_rounded),
                  title: Text('Account security'),
                  subtitle: Text('Your workspace is protected by your account.'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.logout_rounded),
              title: const Text('Log out'),
              subtitle: const Text('Sign out of this account on this device.'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: onLogout,
            ),
          ),
        ],
      ),
    );
  }
}

class FocusView extends StatefulWidget {
  const FocusView({super.key, required this.store});

  final TaskStore store;

  @override
  State<FocusView> createState() => _FocusViewState();
}

class _FocusViewState extends State<FocusView> {
  static const _sessionLength = Duration(minutes: 25);

  Timer? _timer;
  Duration _remaining = _sessionLength;
  bool _running = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleTimer() {
    if (_running) {
      _timer?.cancel();
      setState(() => _running = false);
      return;
    }
    setState(() => _running = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remaining <= const Duration(seconds: 1)) {
        _timer?.cancel();
        if (mounted) {
          setState(() {
            _remaining = _sessionLength;
            _running = false;
          });
        }
        return;
      }
      if (mounted) {
        setState(() => _remaining -= const Duration(seconds: 1));
      }
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _remaining = _sessionLength;
      _running = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tasks = widget.store.tasks.where((task) {
      return !task.isCompleted &&
          (task.priority == TaskPriority.high || task.dueAt != null);
    }).toList()
      ..sort((a, b) {
        if (a.priority != b.priority) {
          return b.priority.index.compareTo(a.priority.index);
        }
        if (a.dueAt == null && b.dueAt == null) return 0;
        if (a.dueAt == null) return 1;
        if (b.dueAt == null) return -1;
        return a.dueAt!.compareTo(b.dueAt!);
      });
    final completed = widget.store.tasks.where((task) => task.isCompleted).length;
    final total = widget.store.tasks.length;
    final timerProgress = 1 - (_remaining.inSeconds / _sessionLength.inSeconds);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 100),
        children: [
          Text('Focus', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 5),
          Text('One task. One session. Less noise.', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: scheme.inverseSurface,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              children: [
                Text(
                  _formatTimer(_remaining),
                  style: TextStyle(
                    color: scheme.onInverseSurface,
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.5,
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: timerProgress,
                    minHeight: 7,
                    backgroundColor: scheme.onInverseSurface.withValues(alpha: .16),
                    color: scheme.onInverseSurface,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: scheme.onInverseSurface,
                        foregroundColor: scheme.inverseSurface,
                      ),
                      onPressed: _toggleTimer,
                      icon: Icon(_running ? Icons.pause_rounded : Icons.play_arrow_rounded),
                      label: Text(_running ? 'Pause' : 'Start 25 min'),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      onPressed: _resetTimer,
                      tooltip: 'Reset focus timer',
                      icon: const Icon(Icons.restart_alt_rounded),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: Text('Focus queue', style: Theme.of(context).textTheme.titleLarge)),
              Text('${tasks.length} tasks'),
            ],
          ),
          const SizedBox(height: 10),
          if (tasks.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(Icons.self_improvement_rounded, size: 42, color: scheme.primary),
                    const SizedBox(height: 10),
                    Text('Nothing competing for attention', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    const Text('Add a high-priority task or a task with a due time.', textAlign: TextAlign.center),
                  ],
                ),
              ),
            )
          else
            ...tasks.take(8).map(
              (task) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _CompactTaskTile(
                  task: task,
                  store: widget.store,
                  accent: task.priority == TaskPriority.high ? scheme.error : scheme.primary,
                ),
              ),
            ),
          const SizedBox(height: 14),
          Card(
            color: scheme.secondaryContainer.withValues(alpha: .7),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Icon(Icons.insights_rounded, color: scheme.onSecondaryContainer),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Progress snapshot', style: TextStyle(fontWeight: FontWeight.w900, color: scheme.onSecondaryContainer)),
                        const SizedBox(height: 3),
                        Text('$completed of $total tasks completed overall.', style: TextStyle(color: scheme.onSecondaryContainer)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimer(Duration value) {
    return '${value.inMinutes.toString().padLeft(2, '0')}:${(value.inSeconds % 60).toString().padLeft(2, '0')}';
  }
}
