import 'package:flutter/material.dart';
import '../application/task_store.dart';
import 'add_task_page.dart';
import 'task_detail_page.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key, required this.store});
  final TaskStore store;
  @override State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _selected = DateTime.now();
  bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final first = DateTime(_month.year, _month.month, 1);
    final days = DateTime(_month.year, _month.month + 1, 0).day;
    final cells = <DateTime?>[
      ...List<DateTime?>.filled(first.weekday - 1, null),
      ...List.generate(days, (i) => DateTime(_month.year, _month.month, i + 1)),
    ];
    while (cells.length % 7 != 0) { cells.add(null); }
    final selectedTasks = widget.store.tasks.where((t) => t.dueAt != null && _sameDay(t.dueAt!, _selected)).toList()
      ..sort((a, b) => a.dueAt!.compareTo(b.dueAt!));

    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 36), children: [
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
          Row(children: [
            IconButton(onPressed: () => setState(() => _month = DateTime(_month.year, _month.month - 1)), icon: const Icon(Icons.chevron_left_rounded)),
            Expanded(child: Text('${_month.month}/${_month.year}', textAlign: TextAlign.center, style: theme.textTheme.titleLarge)),
            IconButton(onPressed: () => setState(() => _month = DateTime(_month.year, _month.month + 1)), icon: const Icon(Icons.chevron_right_rounded)),
          ]),
          const SizedBox(height: 8),
          Row(children: ['M','T','W','T','F','S','S'].map<Widget>((d) => Expanded(child: Center(child: Text(d, style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800))))).toList()),
          const SizedBox(height: 8),
          GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: cells.length, gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, mainAxisExtent: 58), itemBuilder: (_, i) {
            final date = cells[i];
            if (date == null) return const SizedBox();
            final hasTasks = widget.store.tasks.any((t) => t.dueAt != null && _sameDay(t.dueAt!, date));
            final selected = _sameDay(date, _selected);
            final today = _sameDay(date, DateTime.now());
            return InkWell(onTap: () => setState(() => _selected = date), borderRadius: BorderRadius.circular(14), child: Container(margin: const EdgeInsets.all(3), decoration: BoxDecoration(color: selected ? theme.colorScheme.primary : null, borderRadius: BorderRadius.circular(14)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text('${date.day}', style: TextStyle(fontWeight: selected || today ? FontWeight.w800 : FontWeight.w500, color: selected ? theme.colorScheme.onPrimary : null)), if (hasTasks) Container(width: 5, height: 5, margin: const EdgeInsets.only(top: 5), decoration: BoxDecoration(color: selected ? theme.colorScheme.onPrimary : theme.colorScheme.primary, shape: BoxShape.circle))])));
          }),
        ]))),
        const SizedBox(height: 22),
        Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Your day', style: theme.textTheme.titleLarge), const SizedBox(height: 3), Text('${_selected.day}/${_selected.month}/${_selected.year}', style: theme.textTheme.bodyMedium)])), FilledButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddTaskPage(store: widget.store))), icon: const Icon(Icons.add_rounded), label: const Text('Add task'))]),
        const SizedBox(height: 12),
        if (selectedTasks.isEmpty) Card(child: Padding(padding: const EdgeInsets.all(26), child: Column(children: [Icon(Icons.event_available_rounded, size: 38, color: theme.colorScheme.primary), const SizedBox(height: 10), Text('Nothing scheduled', style: theme.textTheme.titleMedium), const SizedBox(height: 4), const Text('A clear day is a good day to plan ahead.', textAlign: TextAlign.center)])))
        else ...selectedTasks.map((task) => Card(margin: const EdgeInsets.only(bottom: 8), child: ListTile(leading: Checkbox(value: task.isCompleted, onChanged: (_) => widget.store.toggleCompleted(task.id)), title: Text(task.title, style: TextStyle(decoration: task.isCompleted ? TextDecoration.lineThrough : null, fontWeight: FontWeight.w700)), subtitle: Text(TimeOfDay.fromDateTime(task.dueAt!).format(context)), trailing: const Icon(Icons.chevron_right_rounded), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TaskDetailPage(store: widget.store, task: task))))),
      ]),
    );
  }
}
