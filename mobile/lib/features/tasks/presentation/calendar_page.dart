import 'package:flutter/material.dart';
import '../application/task_store.dart';
import '../domain/task.dart';
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

  @override Widget build(BuildContext context) {
    final first = DateTime(_month.year, _month.month, 1);
    final days = DateTime(_month.year, _month.month + 1, 0).day;
    final cells = <DateTime?>[...List<DateTime?>.filled(first.weekday - 1, null), ...List.generate(days, (i) => DateTime(_month.year, _month.month, i + 1))];
    while (cells.length % 7 != 0) cells.add(null);
    final selectedTasks = widget.store.tasks.where((t) => t.dueAt != null && _sameDay(t.dueAt!, _selected)).toList()..sort((a,b) => a.dueAt!.compareTo(b.dueAt!));
    return Scaffold(appBar: AppBar(title: const Text('Calendar')), body: ListView(padding: const EdgeInsets.all(16), children: [
      Row(children: [IconButton(onPressed: () => setState(() => _month = DateTime(_month.year, _month.month - 1)), icon: const Icon(Icons.chevron_left)), Expanded(child: Text('${_month.month}/${_month.year}', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800))), IconButton(onPressed: () => setState(() => _month = DateTime(_month.year, _month.month + 1)), icon: const Icon(Icons.chevron_right))]),
      Row(children: ['M','T','W','T','F','S','S'].map((d) => Expanded(child: Center(child: Text(d, style: const TextStyle(fontWeight: FontWeight.w700)))).toList()),
      const SizedBox(height: 8),
      GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: cells.length, gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, mainAxisExtent: 54), itemBuilder: (_, i) { final date = cells[i]; if (date == null) return const SizedBox(); final hasTasks = widget.store.tasks.any((t) => t.dueAt != null && _sameDay(t.dueAt!, date)); final selected = _sameDay(date, _selected); return InkWell(onTap: () => setState(() => _selected = date), borderRadius: BorderRadius.circular(14), child: Container(margin: const EdgeInsets.all(3), decoration: BoxDecoration(color: selected ? Theme.of(context).colorScheme.primaryContainer : null, borderRadius: BorderRadius.circular(14)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text('${date.day}', style: TextStyle(fontWeight: selected ? FontWeight.w800 : FontWeight.w500)), if (hasTasks) Container(width: 5, height: 5, margin: const EdgeInsets.only(top: 5), decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, shape: BoxShape.circle))]))); }),
      const SizedBox(height: 20),
      Row(children: [Expanded(child: Text('Tasks for ${_selected.day}/${_selected.month}', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800))), FilledButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddTaskPage(store: widget.store))), icon: const Icon(Icons.add), label: const Text('Add'))]),
      const SizedBox(height: 10),
      if (selectedTasks.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(24), child: Center(child: Text('No tasks scheduled for this date.')))) else ...selectedTasks.map((task) => Card(child: ListTile(leading: Checkbox(value: task.isCompleted, onChanged: (_) => widget.store.toggleCompleted(task.id)), title: Text(task.title), subtitle: Text(TimeOfDay.fromDateTime(task.dueAt!).format(context)), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TaskDetailPage(store: widget.store, task: task))))))
    ]));
  }
}
