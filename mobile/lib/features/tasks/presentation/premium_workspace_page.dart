import 'package:flutter/material.dart';

import '../application/task_store.dart';
import '../domain/task.dart';
import 'calendar_page.dart';
import 'premium_focus_page.dart';
import 'premium_settings_page.dart';
import 'quick_add_sheet.dart';
import 'task_detail_page.dart';

class PremiumWorkspacePage extends StatefulWidget {
  const PremiumWorkspacePage({super.key, required this.store, required this.onLogout, this.initialIndex = 0});
  final TaskStore store;
  final Future<void> Function() onLogout;
  final int initialIndex;

  @override
  State<PremiumWorkspacePage> createState() => _PremiumWorkspacePageState();
}

class _PremiumWorkspacePageState extends State<PremiumWorkspacePage> {
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, 4);
  }

  void _select(int value) => setState(() => _index = value);
  Future<void> _add() => showQuickAddTask(context, widget.store);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.store,
      builder: (context, _) {
        final pages = <Widget>[
          _Today(store: widget.store, onAdd: _add, onSearch: () => _select(3)),
          CalendarPage(store: widget.store),
          PremiumFocusPage(store: widget.store),
          _Search(store: widget.store),
          PremiumSettingsPage(onLogout: widget.onLogout),
        ];

        return Scaffold(
          body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: KeyedSubtree(key: ValueKey(_index), child: pages[_index]),
          ),
          bottomNavigationBar: _Dock(index: _index, onChanged: _select),
          floatingActionButton: _index == 0
              ? FloatingActionButton.extended(
                  onPressed: _add,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('New task'),
                )
              : null,
        );
      },
    );
  }
}

class _Dock extends StatelessWidget {
  const _Dock({required this.index, required this.onChanged});
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const icons = [Icons.check_circle_outline_rounded, Icons.calendar_month_outlined, Icons.timer_outlined, Icons.search_rounded, Icons.tune_rounded];
    const labels = ['Today', 'Calendar', 'Focus', 'Search', 'More'];

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(14, 7, 14, 10),
      child: Container(
        height: 70,
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: scheme.outlineVariant.withValues(alpha: .45)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .07), blurRadius: 28, offset: const Offset(0, 8))],
        ),
        child: Row(
          children: List.generate(5, (i) {
            final selected = i == index;
            return Expanded(
              child: InkWell(
                onTap: () => onChanged(i),
                borderRadius: BorderRadius.circular(19),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(color: selected ? scheme.primaryContainer : Colors.transparent, borderRadius: BorderRadius.circular(19)),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icons[i], size: 22, color: selected ? scheme.primary : scheme.onSurfaceVariant),
                      const SizedBox(height: 3),
                      Text(labels[i], style: TextStyle(fontSize: 10.5, fontWeight: selected ? FontWeight.w800 : FontWeight.w600, color: selected ? scheme.primary : scheme.onSurfaceVariant)),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _Today extends StatelessWidget {
  const _Today({required this.store, required this.onAdd, required this.onSearch});
  final TaskStore store;
  final VoidCallback onAdd;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final all = store.tasks;
    final active = all.where((task) => !task.isCompleted).toList();
    final today = active.where((task) {
      final due = task.dueAt;
      if (due == null) return false;
      final isToday = due.year == now.year && due.month == now.month && due.day == now.day;
      final isOverdue = due.isBefore(now);
      return isToday || isOverdue;
    }).toList()
      ..sort((a, b) => a.dueAt!.compareTo(b.dueAt!));

    final completed = all.where((task) => task.isCompleted).length;
    final progress = all.isEmpty ? 0.0 : completed / all.length;
    final overdue = active.where((task) => task.dueAt != null && task.dueAt!.isBefore(now)).length;

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 0),
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('YOUR DAY', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 11, letterSpacing: 1.4, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 5),
                    Text('Today', style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -1.4)),
                  ]),
                ),
                IconButton(onPressed: onSearch, icon: const Icon(Icons.search_rounded)),
              ]),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 0),
            sliver: SliverToBoxAdapter(child: _Progress(progress: progress, completed: completed, total: all.length)),
          ),
          if (overdue > 0)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 0),
              sliver: SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(color: Theme.of(context).colorScheme.errorContainer, borderRadius: BorderRadius.circular(16)),
                  child: Row(children: [
                    Icon(Icons.warning_amber_rounded, size: 18, color: Theme.of(context).colorScheme.error),
                    const SizedBox(width: 8),
                    Text('$overdue overdue ${overdue == 1 ? 'task' : 'tasks'}', style: TextStyle(color: Theme.of(context).colorScheme.error, fontWeight: FontWeight.w800)),
                  ]),
                ),
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 10),
            sliver: SliverToBoxAdapter(
              child: Row(children: [
                Expanded(child: Text('Today’s plan', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900))),
                Text('${today.length}', style: Theme.of(context).textTheme.bodySmall),
              ]),
            ),
          ),
          if (today.isEmpty)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(22, 5, 22, 110),
              sliver: SliverToBoxAdapter(child: _Empty(onAdd: onAdd)),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 110),
              sliver: SliverList.separated(
                itemCount: today.length,
                itemBuilder: (_, i) => _TaskTile(task: today[i], store: store),
                separatorBuilder: (_, __) => const SizedBox(height: 9),
              ),
            ),
        ],
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.progress, required this.completed, required this.total});
  final double progress;
  final int completed;
  final int total;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [scheme.primary, scheme.tertiary]), borderRadius: BorderRadius.circular(27)),
      child: Row(children: [
        SizedBox(
          width: 76,
          height: 76,
          child: Stack(alignment: Alignment.center, children: [
            CircularProgressIndicator(value: progress, strokeWidth: 6, backgroundColor: scheme.onPrimary.withValues(alpha: .18), color: scheme.onPrimary),
            Text('${(progress * 100).round()}%', style: TextStyle(color: scheme.onPrimary, fontWeight: FontWeight.w900)),
          ]),
        ),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('DAILY MOMENTUM', style: TextStyle(color: scheme.onPrimary.withValues(alpha: .72), fontSize: 11, letterSpacing: 1.1, fontWeight: FontWeight.w900)),
          const SizedBox(height: 5),
          Text('$completed of $total completed', style: TextStyle(color: scheme.onPrimary, fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(progress >= 1 ? 'Everything is done.' : 'Keep moving forward.', style: TextStyle(color: scheme.onPrimary.withValues(alpha: .82), fontSize: 12.5)),
        ])),
      ]),
    );
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({required this.task, required this.store});
  final Task task;
  final TaskStore store;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isOverdue = !task.isCompleted && task.dueAt != null && task.dueAt!.isBefore(DateTime.now());
    final accent = isOverdue ? scheme.error : (task.priority == TaskPriority.high ? scheme.error : scheme.primary);
    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(21),
      child: InkWell(
        borderRadius: BorderRadius.circular(21),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TaskDetailPage(store: store, task: task))),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(21),
            border: Border.all(color: isOverdue ? scheme.error.withValues(alpha: .55) : scheme.outlineVariant.withValues(alpha: .45)),
          ),
          child: Row(children: [
            GestureDetector(
              onTap: () => store.toggleCompleted(task.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 28,
                height: 28,
                decoration: BoxDecoration(color: task.isCompleted ? accent : Colors.transparent, shape: BoxShape.circle, border: Border.all(color: task.isCompleted ? accent : scheme.outline, width: 2)),
                child: task.isCompleted ? Icon(Icons.check_rounded, size: 17, color: scheme.onPrimary) : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(task.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, decoration: task.isCompleted ? TextDecoration.lineThrough : null)),
              if (task.dueAt != null) ...[
                const SizedBox(height: 5),
                Row(children: [
                  if (isOverdue) ...[
                    Icon(Icons.warning_amber_rounded, size: 14, color: scheme.error),
                    const SizedBox(width: 4),
                    Text('Overdue · ${MaterialLocalizations.of(context).formatMediumDate(task.dueAt!)} · ', style: TextStyle(fontSize: 11.5, color: scheme.error, fontWeight: FontWeight.w900)),
                  ],
                  Text(TimeOfDay.fromDateTime(task.dueAt!).format(context), style: TextStyle(fontSize: 11.5, color: accent, fontWeight: FontWeight.w700)),
                ]),
              ],
            ])),
            if (task.isFavorite) Icon(Icons.star_rounded, size: 19, color: scheme.primary),
          ]),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(color: scheme.surfaceContainerHighest.withValues(alpha: .55), borderRadius: BorderRadius.circular(24)),
      child: Column(children: [
        Icon(Icons.done_all_rounded, size: 42, color: scheme.primary),
        const SizedBox(height: 12),
        Text('Nothing on your schedule', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 5),
        const Text('Your day is clear. Add something you want to accomplish.', textAlign: TextAlign.center),
        const SizedBox(height: 15),
        OutlinedButton.icon(onPressed: onAdd, icon: const Icon(Icons.add_rounded), label: const Text('Add task')),
      ]),
    );
  }
}

class _Search extends StatefulWidget {
  const _Search({required this.store});
  final TaskStore store;
  @override
  State<_Search> createState() => _SearchState();
}

class _SearchState extends State<_Search> {
  final _controller = TextEditingController();
  String _query = '';
  String _filter = 'All';

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final q = _query.toLowerCase().trim();
    final results = widget.store.tasks.where((task) {
      final text = '${task.title} ${task.notes} ${task.category} ${task.tags.join(' ')}'.toLowerCase();
      if (q.isNotEmpty && !text.contains(q)) return false;
      if (_filter == 'Active' && task.isCompleted) return false;
      if (_filter == 'Completed' && !task.isCompleted) return false;
      if (_filter == 'Favorites' && !task.isFavorite) return false;
      return true;
    }).toList();

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverPadding(padding: const EdgeInsets.fromLTRB(22, 22, 22, 14), sliver: SliverToBoxAdapter(child: Text('Find anything', style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w900)))),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            sliver: SliverToBoxAdapter(child: TextField(
              controller: _controller,
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: 'Tasks, notes, tags…',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: q.isEmpty ? null : IconButton(onPressed: () { _controller.clear(); setState(() => _query = ''); }, icon: const Icon(Icons.close_rounded)),
              ),
            )),
          ),
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(22, 13, 22, 12),
              child: Row(children: ['All', 'Active', 'Completed', 'Favorites'].map<Widget>((value) => Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: Text(value), selected: _filter == value, onSelected: (_) => setState(() => _filter = value)))).toList()),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(22, 0, 22, 8),
            sliver: SliverToBoxAdapter(
              child: Text(
                '${results.length} results',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
          ),
          if (results.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Text('No matching tasks.')),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 110),
              sliver: SliverList.separated(
                itemCount: results.length,
                itemBuilder: (_, i) => _TaskTile(task: results[i], store: widget.store),
                separatorBuilder: (_, __) => const SizedBox(height: 9),
              ),
            ),
        ],
      ),
    );
  }
}