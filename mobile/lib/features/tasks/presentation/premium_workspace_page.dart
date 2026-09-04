import 'package:flutter/material.dart';

import '../application/task_store.dart';
import '../domain/task.dart';
import 'add_task_page.dart';
import 'calendar_page.dart';
import 'home_page.dart' show CalendarPage, FocusView, SettingsView;
import 'task_detail_page.dart';

class PremiumWorkspacePage extends StatefulWidget {
  const PremiumWorkspacePage({super.key, required this.store, required this.onLogout});

  final TaskStore store;
  final Future<void> Function() onLogout;

  @override
  State<PremiumWorkspacePage> createState() => _PremiumWorkspacePageState();
}

class _PremiumWorkspacePageState extends State<PremiumWorkspacePage> {
  int _index = 0;

  void _addTask() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AddTaskPage(store: widget.store)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      _PremiumHome(store: widget.store, onAdd: _addTask, onSearch: () => setState(() => _index = 3)),
      CalendarPage(store: widget.store),
      FocusView(store: widget.store),
      _PremiumSearch(store: widget.store),
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
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.calendar_today_outlined), selectedIcon: Icon(Icons.calendar_today_rounded), label: 'Calendar'),
          NavigationDestination(icon: Icon(Icons.center_focus_weak), selectedIcon: Icon(Icons.center_focus_strong), label: 'Focus'),
          NavigationDestination(icon: Icon(Icons.search_rounded), selectedIcon: Icon(Icons.search_rounded), label: 'Search'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings_rounded), label: 'Settings'),
        ],
      ),
      floatingActionButton: _index == 0
          ? FloatingActionButton.extended(
              onPressed: _addTask,
              icon: const Icon(Icons.add_rounded),
              label: const Text('New task'),
            )
          : null,
    );
  }
}

class _PremiumHome extends StatelessWidget {
  const _PremiumHome({required this.store, required this.onAdd, required this.onSearch});

  final TaskStore store;
  final VoidCallback onAdd;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final tasks = store.tasks;
    final completed = tasks.where((task) => task.isCompleted).length;
    final active = tasks.where((task) => !task.isCompleted).toList();
    final today = active.where((task) => _isToday(task.dueAt, now)).toList()..sort(_sortByDue);
    final overdue = active.where((task) => task.dueAt != null && task.dueAt!.isBefore(now)).toList()..sort(_sortByDue);
    final priority = active.where((task) => task.priority == TaskPriority.high).toList()..sort(_sortByDue);
    final upcoming = active.where((task) => task.dueAt != null && task.dueAt!.isAfter(now)).toList()..sort(_sortByDue);
    final favorites = active.where((task) => task.isFavorite).toList()..sort(_sortByDue);
    final progress = tasks.isEmpty ? 0.0 : completed / tasks.length;

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_greeting(), style: themeText(context, 14, FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text('Let\'s make it a productive day.', style: themeText(context, 22, FontWeight.w900)),
                      ],
                    ),
                  ),
                  IconButton.filledTonal(onPressed: onSearch, icon: const Icon(Icons.search_rounded)),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
            sliver: SliverToBoxAdapter(child: _DailyHero(progress: progress, completed: completed, total: tasks.length, overdue: overdue.length)),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 8),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Expanded(child: _Metric(icon: Icons.today_rounded, value: '${today.length}', label: 'Today', color: scheme.primary)),
                  const SizedBox(width: 8),
                  Expanded(child: _Metric(icon: Icons.check_circle_rounded, value: '$completed', label: 'Completed', color: scheme.tertiary)),
                  const SizedBox(width: 8),
                  Expanded(child: _Metric(icon: Icons.warning_amber_rounded, value: '${overdue.length}', label: 'Overdue', color: scheme.error)),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Expanded(child: Text('Today', style: themeText(context, 20, FontWeight.w900))),
                  TextButton(onPressed: onSearch, child: const Text('See all')),
                ],
              ),
            ),
          ),
          if (today.isEmpty)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 2, 20, 10),
              sliver: SliverToBoxAdapter(child: _EmptyState(onAdd: onAdd)),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 2, 20, 4),
              sliver: SliverList.separated(
                itemCount: today.take(4).length,
                itemBuilder: (context, index) => _PremiumTaskRow(task: today[index], store: store),
                separatorBuilder: (context, index) => const SizedBox(height: 8),
              ),
            ),
          if (overdue.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
              sliver: SliverToBoxAdapter(child: _OverdueBanner(count: overdue.length)),
            ),
          if (priority.isNotEmpty) ...[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              sliver: SliverToBoxAdapter(child: _SectionTitle(title: 'Priority', icon: Icons.bolt_rounded, color: scheme.error)),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 2, 20, 4),
              sliver: SliverList.separated(
                itemCount: priority.take(3).length,
                itemBuilder: (context, index) => _PremiumTaskRow(task: priority[index], store: store, accent: scheme.error),
                separatorBuilder: (context, index) => const SizedBox(height: 8),
              ),
            ),
          ],
          if (favorites.isNotEmpty) ...[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              sliver: SliverToBoxAdapter(child: _SectionTitle(title: 'Favorites', icon: Icons.star_rounded, color: scheme.primary)),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 2, 20, 8),
              sliver: SliverToBoxAdapter(
                child: SizedBox(
                  height: 108,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: favorites.take(5).length,
                    itemBuilder: (context, index) => _FavoriteTask(task: favorites[index], store: store),
                    separatorBuilder: (context, index) => const SizedBox(width: 10),
                  ),
                ),
              ),
            ),
          ],
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
            sliver: SliverToBoxAdapter(child: _UpcomingCard(tasks: upcoming)),
          ),
        ],
      ),
    );
  }

  static bool _isToday(DateTime? value, DateTime now) => value != null && value.year == now.year && value.month == now.month && value.day == now.day;

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
}

TextStyle themeText(BuildContext context, double size, FontWeight weight) => Theme.of(context).textTheme.bodyLarge!.copyWith(fontSize: size, fontWeight: weight);

class _DailyHero extends StatelessWidget {
  const _DailyHero({required this.progress, required this.completed, required this.total, required this.overdue});
  final double progress;
  final int completed;
  final int total;
  final int overdue;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final percent = (progress * 100).round();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [scheme.primary, scheme.secondary]),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: scheme.primary.withValues(alpha: .18), blurRadius: 26, offset: const Offset(0, 12))],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 78,
            height: 78,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(value: progress, strokeWidth: 7, backgroundColor: scheme.onPrimary.withValues(alpha: .16), color: scheme.onPrimary),
                Text('$percent%', style: TextStyle(color: scheme.onPrimary, fontSize: 17, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your day, in control.', style: TextStyle(color: scheme.onPrimary, fontSize: 20, fontWeight: FontWeight.w900)),
                const SizedBox(height: 5),
                Text('$completed of $total completed', style: TextStyle(color: scheme.onPrimary, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(overdue == 0 ? 'You are on track. Keep the momentum.' : '$overdue task${overdue == 1 ? '' : 's'} need your attention.', style: TextStyle(color: scheme.onPrimary.withValues(alpha: .82), height: 1.25)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.icon, required this.value, required this.label, required this.color});
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
      decoration: BoxDecoration(color: scheme.surfaceContainerHighest.withValues(alpha: .62), borderRadius: BorderRadius.circular(18), border: Border.all(color: scheme.outlineVariant.withValues(alpha: .35))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 7),
        Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
        Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
      ]),
    );
  }
}

class _PremiumTaskRow extends StatelessWidget {
  const _PremiumTaskRow({required this.task, required this.store, this.accent});
  final Task task;
  final TaskStore store;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = accent ?? scheme.primary;
    final due = task.dueAt;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => TaskDetailPage(store: store, task: task))),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          child: Row(children: [
            Checkbox(value: task.isCompleted, onChanged: (_) => store.toggleCompleted(task.id)),
            Container(width: 4, height: 42, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(5))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(task.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w800, decoration: task.isCompleted ? TextDecoration.lineThrough : null)),
              const SizedBox(height: 4),
              Row(children: [
                if (due != null) ...[Icon(Icons.schedule_rounded, size: 14, color: color), const SizedBox(width: 4), Text(TimeOfDay.fromDateTime(due).format(context), style: Theme.of(context).textTheme.bodySmall)],
                if (task.category.isNotEmpty) ...[const SizedBox(width: 8), Flexible(child: Text(task.category, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall))],
              ]),
            ])),
            if (task.isFavorite) Icon(Icons.star_rounded, size: 20, color: scheme.primary),
          ]),
        ),
      ),
    );
  }
}

class _FavoriteTask extends StatelessWidget {
  const _FavoriteTask({required this.task, required this.store});
  final Task task;
  final TaskStore store;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 210,
      child: Card(
        color: scheme.primaryContainer.withValues(alpha: .72),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => TaskDetailPage(store: store, task: task))),
          child: Padding(padding: const EdgeInsets.all(15), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.star_rounded, color: scheme.primary),
            const Spacer(),
            Text(task.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
          ])),
        ),
      ),
    );
  }
}

class _OverdueBanner extends StatelessWidget {
  const _OverdueBanner({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: scheme.errorContainer, borderRadius: BorderRadius.circular(18)),
      child: Row(children: [Icon(Icons.warning_amber_rounded, color: scheme.onErrorContainer), const SizedBox(width: 10), Expanded(child: Text('$count overdue task${count == 1 ? '' : 's'}', style: TextStyle(color: scheme.onErrorContainer, fontWeight: FontWeight.w800))), Icon(Icons.chevron_right_rounded, color: scheme.onErrorContainer)]),
    );
  }
}

class _UpcomingCard extends StatelessWidget {
  const _UpcomingCard({required this.tasks});
  final List<Task> tasks;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(padding: const EdgeInsets.all(17), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Coming up', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
        if (tasks.isEmpty) const Padding(padding: EdgeInsets.only(top: 10), child: Text('Nothing scheduled next.')),
        ...tasks.take(3).map((task) => Padding(padding: const EdgeInsets.only(top: 11), child: Row(children: [Container(width: 9, height: 9, decoration: BoxDecoration(color: scheme.primary, shape: BoxShape.circle)), const SizedBox(width: 10), Expanded(child: Text(task.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700))), Text(TimeOfDay.fromDateTime(task.dueAt!).format(context), style: Theme.of(context).textTheme.bodySmall)]))),
      ])),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.icon, required this.color});
  final String title;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(children: [Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900))), Icon(icon, color: color)]);
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(18), child: Row(children: [Container(width: 46, height: 46, decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer, borderRadius: BorderRadius.circular(15)), child: Icon(Icons.wb_sunny_outlined, color: Theme.of(context).colorScheme.primary)), const SizedBox(width: 12), const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Your day is clear', style: TextStyle(fontWeight: FontWeight.w900)), SizedBox(height: 3), Text('Add something worth getting done.') ])), IconButton(onPressed: onAdd, icon: const Icon(Icons.add_rounded))]));
}

class _PremiumSearch extends StatefulWidget {
  const _PremiumSearch({required this.store});
  final TaskStore store;

  @override
  State<_PremiumSearch> createState() => _PremiumSearchState();
}

class _PremiumSearchState extends State<_PremiumSearch> {
  final _controller = TextEditingController();
  String _query = '';
  String _filter = 'All';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final query = _query.trim().toLowerCase();
    var results = widget.store.tasks.where((task) {
      final haystack = '${task.title} ${task.notes} ${task.category} ${task.tags.join(' ')}'.toLowerCase();
      if (query.isNotEmpty && !haystack.contains(query)) return false;
      if (_filter == 'Active' && task.isCompleted) return false;
      if (_filter == 'Completed' && !task.isCompleted) return false;
      if (_filter == 'Favorites' && !task.isFavorite) return false;
      return true;
    }).toList();
    results.sort((a, b) {
      if (a.isCompleted != b.isCompleted) return a.isCompleted ? 1 : -1;
      if (a.dueAt == null && b.dueAt == null) return 0;
      if (a.dueAt == null) return 1;
      if (b.dueAt == null) return -1;
      return a.dueAt!.compareTo(b.dueAt!);
    });

    return SafeArea(
      child: CustomScrollView(slivers: [
        SliverPadding(padding: const EdgeInsets.fromLTRB(20, 20, 20, 10), sliver: SliverToBoxAdapter(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Search', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900)), const SizedBox(height: 4), Text('Find tasks, notes, tags and categories.')]))),
        SliverPadding(padding: const EdgeInsets.fromLTRB(20, 4, 20, 8), sliver: SliverToBoxAdapter(child: TextField(controller: _controller, onChanged: (value) => setState(() => _query = value), textInputAction: TextInputAction.search, decoration: InputDecoration(hintText: 'Search tasks, tags or notes…', prefixIcon: const Icon(Icons.search_rounded), suffixIcon: _query.isEmpty ? null : IconButton(onPressed: () { _controller.clear(); setState(() => _query = ''); }, icon: const Icon(Icons.close_rounded))))),
        SliverPadding(padding: const EdgeInsets.fromLTRB(20, 2, 20, 10), sliver: SliverToBoxAdapter(child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: ['All', 'Active', 'Completed', 'Favorites'].map((value) => Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: Text(value), selected: _filter == value, onSelected: (_) => setState(() => _filter = value))).toList())))),
        if (results.isEmpty)
          const SliverPadding(padding: EdgeInsets.fromLTRB(20, 30, 20, 100), sliver: SliverToBoxAdapter(child: Center(child: Text('No matching tasks.'))))
        else
          SliverPadding(padding: const EdgeInsets.fromLTRB(20, 2, 20, 100), sliver: SliverList.separated(itemCount: results.length, itemBuilder: (context, index) => _PremiumTaskRow(task: results[index], store: widget.store), separatorBuilder: (context, index) => const SizedBox(height: 8))),
      ]),
    );
  }
}
