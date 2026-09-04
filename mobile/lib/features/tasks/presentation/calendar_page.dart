import 'package:flutter/material.dart';

import '../application/task_store.dart';
import '../domain/task.dart';
import 'add_task_page.dart';
import 'task_detail_page.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key, required this.store});
  final TaskStore store;

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _selected = DateTime.now();

  bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  List<Task> _tasksFor(DateTime day) {
    final tasks = widget.store.tasks.where((task) => task.dueAt != null && _sameDay(task.dueAt!, day)).toList();
    tasks.sort((a, b) => a.dueAt!.compareTo(b.dueAt!));
    return tasks;
  }

  void _select(DateTime date) {
    setState(() {
      _selected = date;
      _month = DateTime(date.year, date.month);
    });
  }

  void _goToToday() => _select(DateTime.now());

  void _changeMonth(int offset) {
    setState(() {
      _month = DateTime(_month.year, _month.month + offset);
    });
  }

  void _addTask() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => AddTaskPage(store: widget.store)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final today = DateTime.now();
    final first = DateTime(_month.year, _month.month, 1);
    final lastDay = DateTime(_month.year, _month.month + 1, 0).day;
    final cells = <DateTime?>[];
    for (var i = 0; i < first.weekday - 1; i++) {
      cells.add(null);
    }
    for (var day = 1; day <= lastDay; day++) {
      cells.add(DateTime(_month.year, _month.month, day));
    }
    while (cells.length % 7 != 0) {
      cells.add(null);
    }
    final selectedTasks = _tasksFor(_selected);
    final completed = selectedTasks.where((task) => task.isCompleted).length;
    final isCurrentMonth = _month.year == today.year && _month.month == today.month;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 110),
        children: [
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Planner', style: theme.textTheme.labelLarge?.copyWith(color: scheme.primary, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text('Calendar', style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -1.3)),
              const SizedBox(height: 3),
              Text('See what is coming up.', style: theme.textTheme.bodyMedium),
            ])),
            if (!isCurrentMonth || !_sameDay(_selected, today))
              Padding(
                padding: const EdgeInsets.only(right: 7),
                child: IconButton.filledTonal(tooltip: 'Jump to today', onPressed: _goToToday, icon: const Icon(Icons.today_rounded)),
              ),
            IconButton.filled(onPressed: _addTask, tooltip: 'Add task', icon: const Icon(Icons.add_rounded)),
          ]),
          const SizedBox(height: 18),
          _WeekStrip(selected: _selected, today: today, tasksFor: _tasksFor, onSelect: _select),
          const SizedBox(height: 18),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: SlideTransition(position: Tween<Offset>(begin: const Offset(0, .025), end: Offset.zero).animate(animation), child: child)),
            child: Container(
              key: ValueKey('${_month.year}-${_month.month}'),
              padding: const EdgeInsets.fromLTRB(12, 13, 12, 15),
              decoration: BoxDecoration(color: scheme.surface, borderRadius: BorderRadius.circular(26), border: Border.all(color: scheme.outlineVariant.withValues(alpha: .42)), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .035), blurRadius: 22, offset: const Offset(0, 8))]),
              child: Column(children: [
                Row(children: [
                  IconButton.filledTonal(onPressed: () => _changeMonth(-1), tooltip: 'Previous month', icon: const Icon(Icons.chevron_left_rounded)),
                  Expanded(child: Column(children: [
                    Text(MaterialLocalizations.of(context).formatMonthYear(_month), textAlign: TextAlign.center, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 2),
                    Text('${cells.whereType<DateTime>().length} days', style: theme.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
                  ])),
                  IconButton.filledTonal(onPressed: () => _changeMonth(1), tooltip: 'Next month', icon: const Icon(Icons.chevron_right_rounded)),
                ]),
                const SizedBox(height: 8),
                Row(children: [for (final label in const ['M', 'T', 'W', 'T', 'F', 'S', 'S']) Expanded(child: Center(child: Text(label, style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w900, color: scheme.onSurfaceVariant))))]),
                const SizedBox(height: 7),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: cells.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, mainAxisExtent: 48),
                  itemBuilder: (context, index) {
                    final date = cells[index];
                    if (date == null) return const SizedBox.shrink();
                    final selected = _sameDay(date, _selected);
                    final isToday = _sameDay(date, today);
                    final tasks = _tasksFor(date);
                    final allDone = tasks.isNotEmpty && tasks.every((task) => task.isCompleted);
                    return InkWell(
                      onTap: () => _select(date),
                      borderRadius: BorderRadius.circular(15),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: selected ? scheme.primary : null,
                          borderRadius: BorderRadius.circular(15),
                          border: isToday && !selected ? Border.all(color: scheme.primary.withValues(alpha: .55), width: 1.4) : null,
                        ),
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Text('${date.day}', style: TextStyle(fontSize: 13, fontWeight: selected || isToday ? FontWeight.w900 : FontWeight.w600, color: selected ? scheme.onPrimary : null)),
                          const SizedBox(height: 4),
                          if (tasks.isNotEmpty)
                            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                              for (final task in tasks.take(3))
                                Container(width: 4, height: 4, margin: const EdgeInsets.symmetric(horizontal: 1.5), decoration: BoxDecoration(color: selected ? scheme.onPrimary : task.isCompleted ? scheme.outline : task.priority == TaskPriority.high ? scheme.error : scheme.primary, shape: BoxShape.circle)),
                            ])
                          else
                            const SizedBox(height: 4),
                          if (allDone) ...[
                            const SizedBox(height: 2),
                            Icon(Icons.check_rounded, size: 9, color: selected ? scheme.onPrimary : scheme.primary),
                          ],
                        ]),
                      ),
                    );
                  },
                ),
              ]),
            ),
          ),
          const SizedBox(height: 25),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Agenda', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 3),
              Text(MaterialLocalizations.of(context).formatFullDate(_selected), style: theme.textTheme.bodySmall),
            ])),
            if (selectedTasks.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: completed == selectedTasks.length ? scheme.primaryContainer : scheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(12)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(completed == selectedTasks.length ? Icons.done_all_rounded : Icons.task_alt_rounded, size: 15, color: scheme.primary),
                  const SizedBox(width: 5),
                  Text('$completed/${selectedTasks.length}', style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w900, fontSize: 12)),
                ]),
              )
            else
              Text('0 tasks', style: theme.textTheme.bodySmall),
          ]),
          const SizedBox(height: 11),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: selectedTasks.isEmpty
                ? _EmptyAgenda(key: ValueKey(_selected.toIso8601String()), onAdd: _addTask)
                : Column(key: ValueKey(selectedTasks.map((task) => task.id).join(',')), children: [for (final task in selectedTasks) _CalendarTask(task: task, store: widget.store)]),
          ),
        ],
      ),
    );
  }
}

class _WeekStrip extends StatelessWidget {
  const _WeekStrip({required this.selected, required this.today, required this.tasksFor, required this.onSelect});
  final DateTime selected;
  final DateTime today;
  final List<Task> Function(DateTime) tasksFor;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final monday = selected.subtract(Duration(days: selected.weekday - 1));
    const labels = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    return SizedBox(
      height: 78,
      child: Row(children: List.generate(7, (index) {
        final date = DateTime(monday.year, monday.month, monday.day + index);
        final selectedDay = _same(date, selected);
        final todayDay = _same(date, today);
        final hasTasks = tasksFor(date).isNotEmpty;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index == 6 ? 0 : 6),
            child: InkWell(
              onTap: () => onSelect(date),
              borderRadius: BorderRadius.circular(19),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                decoration: BoxDecoration(color: selectedDay ? scheme.primary : scheme.surfaceContainerHighest.withValues(alpha: .5), borderRadius: BorderRadius.circular(19), border: todayDay && !selectedDay ? Border.all(color: scheme.primary.withValues(alpha: .5)) : null),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(labels[index], style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: selectedDay ? scheme.onPrimary.withValues(alpha: .75) : scheme.onSurfaceVariant)),
                  const SizedBox(height: 5),
                  Text('${date.day}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: selectedDay ? scheme.onPrimary : null)),
                  const SizedBox(height: 4),
                  Container(width: hasTasks ? 5 : 3, height: 3, decoration: BoxDecoration(color: selectedDay ? scheme.onPrimary : hasTasks ? scheme.primary : scheme.outlineVariant, borderRadius: BorderRadius.circular(5))),
                ]),
              ),
            ),
          ),
        );
      })),
    );
  }

  static bool _same(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
}

class _EmptyAgenda extends StatelessWidget {
  const _EmptyAgenda({super.key, required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
      decoration: BoxDecoration(color: scheme.surfaceContainerHighest.withValues(alpha: .45), borderRadius: BorderRadius.circular(22)),
      child: Column(children: [
        Container(width: 52, height: 52, decoration: BoxDecoration(color: scheme.primaryContainer, shape: BoxShape.circle), child: Icon(Icons.event_available_rounded, size: 28, color: scheme.primary)),
        const SizedBox(height: 10),
        Text('Nothing planned', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        const Text('This day is open. Add a task when you are ready.', textAlign: TextAlign.center),
        const SizedBox(height: 14),
        OutlinedButton.icon(onPressed: onAdd, icon: const Icon(Icons.add_rounded), label: const Text('Add task')),
      ]),
    );
  }
}

class _CalendarTask extends StatelessWidget {
  const _CalendarTask({required this.task, required this.store});
  final Task task;
  final TaskStore store;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = task.priority == TaskPriority.high ? scheme.error : scheme.primary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Material(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(21),
        child: InkWell(
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => TaskDetailPage(store: store, task: task))),
          borderRadius: BorderRadius.circular(21),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(color: task.isCompleted ? scheme.surfaceContainerHighest.withValues(alpha: .55) : scheme.surface, borderRadius: BorderRadius.circular(21), border: Border.all(color: scheme.outlineVariant.withValues(alpha: .42))),
            child: Row(children: [
              AnimatedContainer(duration: const Duration(milliseconds: 180), width: 4, height: 48, decoration: BoxDecoration(color: task.isCompleted ? scheme.outline : accent, borderRadius: BorderRadius.circular(5))),
              const SizedBox(width: 11),
              GestureDetector(
                onTap: () => store.toggleCompleted(task.id),
                child: AnimatedContainer(duration: const Duration(milliseconds: 180), width: 25, height: 25, decoration: BoxDecoration(shape: BoxShape.circle, color: task.isCompleted ? accent : Colors.transparent, border: Border.all(color: task.isCompleted ? accent : scheme.outline, width: 2)), child: task.isCompleted ? const Icon(Icons.check_rounded, size: 16, color: Colors.white) : null),
              ),
              const SizedBox(width: 11),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(task.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w800, decoration: task.isCompleted ? TextDecoration.lineThrough : null, color: task.isCompleted ? scheme.onSurfaceVariant : null)),
                const SizedBox(height: 5),
                Row(children: [
                  Icon(Icons.schedule_rounded, size: 14, color: task.isCompleted ? scheme.onSurfaceVariant : accent),
                  const SizedBox(width: 4),
                  Text(TimeOfDay.fromDateTime(task.dueAt!).format(context), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: scheme.onSurfaceVariant)),
                  if (task.category.isNotEmpty) ...[const SizedBox(width: 8), Flexible(child: Text(task.category, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall))],
                ]),
              ])),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
            ]),
          ),
        ),
      ),
    );
  }
}
