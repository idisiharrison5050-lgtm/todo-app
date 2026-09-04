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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final first = DateTime(_month.year, _month.month, 1);
    final days = DateTime(_month.year, _month.month + 1, 0).day;
    final cells = <DateTime?>[...List<DateTime?>.filled(first.weekday - 1, null), ...List.generate(days, (i) => DateTime(_month.year, _month.month, i + 1))];
    while (cells.length % 7 != 0) { cells.add(null); }
    final selectedTasks = widget.store.tasks.where((task) => task.dueAt != null && _sameDay(task.dueAt!, _selected)).toList()..sort((a, b) => a.dueAt!.compareTo(b.dueAt!));
    final monthName = MaterialLocalizations.of(context).formatMonthYear(_month);
    const dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
        children: [
          Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Calendar', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900)), const SizedBox(height: 3), Text('Plan your days at a glance', style: theme.textTheme.bodyMedium)])), IconButton.filledTonal(tooltip: 'Add task', onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => AddTaskPage(store: widget.store))), icon: const Icon(Icons.add_rounded))]),
          const SizedBox(height: 16),
          Card(child: Padding(padding: const EdgeInsets.fromLTRB(12, 12, 12, 16), child: Column(children: [
            Row(children: [IconButton(onPressed: () => setState(() => _month = DateTime(_month.year, _month.month - 1)), icon: const Icon(Icons.chevron_left_rounded)), Expanded(child: Text(monthName, textAlign: TextAlign.center, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900))), IconButton(onPressed: () => setState(() => _month = DateTime(_month.year, _month.month + 1)), icon: const Icon(Icons.chevron_right_rounded))]),
            const SizedBox(height: 8),
            Row(children: [for (final label in dayLabels) Expanded(child: Center(child: Text(label, style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800))))]),
            const SizedBox(height: 8),
            GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: cells.length, gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, mainAxisExtent: 54), itemBuilder: (context, index) {
              final date = cells[index];
              if (date == null) return const SizedBox.shrink();
              final selected = _sameDay(date, _selected);
              final today = _sameDay(date, DateTime.now());
              final dayTasks = widget.store.tasks.where((task) => task.dueAt != null && _sameDay(task.dueAt!, date)).toList();
              return InkWell(onTap: () => setState(() => _selected = date), borderRadius: BorderRadius.circular(16), child: AnimatedContainer(duration: const Duration(milliseconds: 180), margin: const EdgeInsets.all(2), decoration: BoxDecoration(color: selected ? scheme.primary : today ? scheme.primaryContainer.withValues(alpha: .5) : null, borderRadius: BorderRadius.circular(16), border: today && !selected ? Border.all(color: scheme.primary.withValues(alpha: .45)) : null), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text('${date.day}', style: TextStyle(fontWeight: selected || today ? FontWeight.w900 : FontWeight.w500, color: selected ? scheme.onPrimary : null)), const SizedBox(height: 4), if (dayTasks.isNotEmpty) Row(mainAxisAlignment: MainAxisAlignment.center, children: [for (final task in dayTasks.take(3)) Padding(padding: const EdgeInsets.symmetric(horizontal: 1.5), child: Container(width: 4, height: 4, decoration: BoxDecoration(color: selected ? scheme.onPrimary : task.priority == TaskPriority.high ? scheme.error : scheme.primary, shape: BoxShape.circle)))]) else const SizedBox(height: 4)])));
            }),
          ]))),
          const SizedBox(height: 22),
          Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Your day', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)), const SizedBox(height: 3), Text(MaterialLocalizations.of(context).formatFullDate(_selected))])), Text('${selectedTasks.length} task${selectedTasks.length == 1 ? '' : 's'}', style: theme.textTheme.labelLarge?.copyWith(color: scheme.primary, fontWeight: FontWeight.w800))]),
          const SizedBox(height: 10),
          if (selectedTasks.isEmpty) Card(child: Padding(padding: const EdgeInsets.all(24), child: Column(children: [Icon(Icons.event_available_rounded, size: 40, color: scheme.primary), const SizedBox(height: 10), Text('Nothing scheduled', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)), const SizedBox(height: 4), const Text('A clear day is a good day to plan ahead.', textAlign: TextAlign.center)]))) else ...selectedTasks.map((task) => _CalendarTask(task: task, store: widget.store)),
        ],
      ),
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
    final color = task.priority == TaskPriority.high ? scheme.error : scheme.primary;
    return Card(margin: const EdgeInsets.only(bottom: 8), child: InkWell(borderRadius: BorderRadius.circular(22), onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => TaskDetailPage(store: store, task: task))), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), child: Row(children: [Container(width: 4, height: 48, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(5))), const SizedBox(width: 10), Checkbox(value: task.isCompleted, onChanged: (_) => store.toggleCompleted(task.id)), const SizedBox(width: 4), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(task.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w800, decoration: task.isCompleted ? TextDecoration.lineThrough : null)), const SizedBox(height: 4), Row(children: [Icon(Icons.schedule_rounded, size: 14, color: color), const SizedBox(width: 4), Text(TimeOfDay.fromDateTime(task.dueAt!).format(context)), if (task.category.isNotEmpty) ...[const SizedBox(width: 8), Flexible(child: Text(task.category, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall))]])])), const Icon(Icons.chevron_right_rounded)])));
  }
}
