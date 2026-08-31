import 'package:flutter/material.dart';

import '../application/task_store.dart';
import '../domain/task.dart';

class AddTaskPage extends StatefulWidget {
  const AddTaskPage({super.key, required this.store, this.task});
  final TaskStore store;
  final Task? task;
  bool get isEditing => task != null;
  @override State<AddTaskPage> createState() => _AddTaskPageState();
}

class _AddTaskPageState extends State<AddTaskPage> {
  late final TextEditingController _titleController;
  late final TextEditingController _notesController;
  DateTime? _dueAt;
  TaskPriority _priority = TaskPriority.normal;
  TaskReminderType _reminderType = TaskReminderType.none;
  Duration? _interval = const Duration(hours: 2);
  TaskRepeat _repeat = TaskRepeat.none;
  int _customDays = 1;
  bool _favorite = false;
  String _category = '';
  final List<String> _tags = <String>[];
  bool _saving = false;

  @override void initState() { super.initState(); final task = widget.task; _titleController = TextEditingController(text: task?.title ?? ''); _notesController = TextEditingController(text: task?.notes ?? ''); _dueAt = task?.dueAt; _priority = task?.priority ?? TaskPriority.normal; _reminderType = task?.reminderType ?? TaskReminderType.none; _interval = task?.reminderInterval ?? const Duration(hours: 2); _repeat = task?.repeat ?? TaskRepeat.none; _customDays = task?.repeatIntervalDays ?? 1; _favorite = task?.isFavorite ?? false; _category = task?.category ?? ''; _tags.addAll(task?.tags ?? const <String>[]); }
  @override void dispose() { _titleController.dispose(); _notesController.dispose(); super.dispose(); }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(context: context, firstDate: DateTime(now.year, now.month, now.day), lastDate: DateTime(now.year + 5), initialDate: _dueAt ?? now);
    if (date == null || !mounted) return;
    final sameDay = date.year == now.year && date.month == now.month && date.day == now.day;
    final defaultTime = sameDay ? now.add(const Duration(minutes: 2)) : (_dueAt ?? DateTime(date.year, date.month, date.day, 9));
    final time = await _showScrollTimePicker(initialDateTime: defaultTime, minimumDateTime: sameDay ? now.add(const Duration(minutes: 1)) : null);
    if (time == null || !mounted) return;
    final value = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    if (sameDay && !value.isAfter(DateTime(now.year, now.month, now.day, now.hour, now.minute))) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Choose at least 1 minute from now.'))); return; }
    setState(() { _dueAt = value; if (_reminderType == TaskReminderType.none) _reminderType = TaskReminderType.once; });
  }

  Future<TimeOfDay?> _showScrollTimePicker({required DateTime initialDateTime, DateTime? minimumDateTime}) async {
    final initial = minimumDateTime != null && initialDateTime.isBefore(minimumDateTime) ? minimumDateTime.add(const Duration(minutes: 1)) : initialDateTime;
    var hour = initial.hourOfPeriod == 0 ? 12 : initial.hourOfPeriod;
    var minute = initial.minute;
    var period = initial.period;
    return showModalBottomSheet<TimeOfDay>(context: context, showDragHandle: true, isScrollControlled: true, builder: (sheetContext) {
      final hc = FixedExtentScrollController(initialItem: hour - 1); final mc = FixedExtentScrollController(initialItem: minute); final pc = FixedExtentScrollController(initialItem: period == DayPeriod.am ? 0 : 1);
      return StatefulBuilder(builder: (context, setSheetState) { final candidate = DateTime(initial.year, initial.month, initial.day, period == DayPeriod.am ? hour % 12 : hour % 12 + 12, minute); final valid = minimumDateTime == null || candidate.isAfter(DateTime(minimumDateTime.year, minimumDateTime.month, minimumDateTime.day, minimumDateTime.hour, minimumDateTime.minute)); return SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(20, 4, 20, 20), child: Column(mainAxisSize: MainAxisSize.min, children: [const Align(alignment: Alignment.centerLeft, child: Text('Choose time', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800))), const SizedBox(height: 6), Text(minimumDateTime == null ? 'Scroll to choose a time.' : 'Default is 2 minutes ahead. You can choose from 1 minute ahead.', style: Theme.of(context).textTheme.bodySmall), const SizedBox(height: 14), SizedBox(height: 190, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [_wheel(hc, 12, (i) => '${i + 1}', (i) => setSheetState(() => hour = i + 1)), const Text(':', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)), _wheel(mc, 60, (i) => i.toString().padLeft(2, '0'), (i) => setSheetState(() => minute = i)), const SizedBox(width: 12), _wheel(pc, 2, (i) => i == 0 ? 'AM' : 'PM', (i) => setSheetState(() => period = i == 0 ? DayPeriod.am : DayPeriod.pm))])), if (!valid) const Padding(padding: EdgeInsets.only(bottom: 8), child: Text('That time has already passed.')), SizedBox(width: double.infinity, child: FilledButton(onPressed: valid ? () => Navigator.pop(sheetContext, TimeOfDay(hour: period == DayPeriod.am ? hour % 12 : hour % 12 + 12, minute: minute)) : null, child: const Text('Set time')))]))); });
    });
  }
  Widget _wheel(FixedExtentScrollController controller, int count, String Function(int) label, ValueChanged<int> changed) => SizedBox(width: 72, child: ListWheelScrollView.useDelegate(controller: controller, itemExtent: 48, physics: const FixedExtentScrollPhysics(), onSelectedItemChanged: changed, childDelegate: ListWheelChildBuilderDelegate(childCount: count, builder: (_, i) => Center(child: Text(label(i), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700))))));
  void _setQuick(Duration d) { final v = DateTime.now().add(d); setState(() { _dueAt = DateTime(v.year, v.month, v.day, v.hour, v.minute); if (_reminderType == TaskReminderType.none) _reminderType = TaskReminderType.once; }); }
  void _setTomorrow() { final v = DateTime.now().add(const Duration(days: 1)); setState(() { _dueAt = DateTime(v.year, v.month, v.day, 9); if (_reminderType == TaskReminderType.none) _reminderType = TaskReminderType.once; }); }

  Future<void> _save() async {
    if (_saving) return; final title = _titleController.text.trim(); if (title.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Give your task a name first.'))); return; }
    setState(() => _saving = true);
    try {
      final args = <String, dynamic>{'title': title, 'notes': _notesController.text, 'dueAt': _dueAt, 'reminderType': _reminderType, 'reminderInterval': _reminderType == TaskReminderType.interval ? _interval : null, 'priority': _priority, 'repeat': _repeat, 'repeatIntervalDays': _repeat == TaskRepeat.custom ? _customDays : null, 'isFavorite': _favorite, 'category': _category, 'tags': _tags};
      if (widget.task == null) await widget.store.addTask(title: args['title'], notes: args['notes'], dueAt: args['dueAt'], reminderType: args['reminderType'], reminderInterval: args['reminderInterval'], priority: args['priority'], repeat: args['repeat'], repeatIntervalDays: args['repeatIntervalDays'], isFavorite: args['isFavorite'], category: args['category'], tags: args['tags']);
      else await widget.store.updateTask(widget.task!.id, title: args['title'], notes: args['notes'], dueAt: args['dueAt'], reminderType: args['reminderType'], reminderInterval: args['reminderInterval'], priority: args['priority'], repeat: args['repeat'], repeatIntervalDays: args['repeatIntervalDays'], isFavorite: args['isFavorite'], category: args['category'], tags: args['tags']);
      if (mounted) Navigator.pop(context);
    } catch (_) { if (!mounted) return; setState(() => _saving = false); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not save the task. Try again.'))); }
  }

  @override Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(appBar: AppBar(title: Text(widget.isEditing ? 'Edit task' : 'New task'), actions: [TextButton(onPressed: _saving ? null : _save, child: const Text('Save'))]), body: ListView(padding: const EdgeInsets.fromLTRB(20, 12, 20, 40), children: [
      TextField(controller: _titleController, autofocus: !widget.isEditing, decoration: const InputDecoration(hintText: 'What needs to be done?', prefixIcon: Icon(Icons.check_circle_outline))), const SizedBox(height: 12),
      TextField(controller: _notesController, minLines: 3, maxLines: 6, decoration: const InputDecoration(hintText: 'Notes', prefixIcon: Icon(Icons.notes_outlined))), const SizedBox(height: 24),
      Text('Schedule', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)), Wrap(spacing: 8, children: [ActionChip(label: const Text('15 min'), onPressed: () => _setQuick(const Duration(minutes: 15))), ActionChip(label: const Text('1 hour'), onPressed: () => _setQuick(const Duration(hours: 1))), ActionChip(label: const Text('Tomorrow'), onPressed: _setTomorrow)]),
      ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.schedule_outlined), title: Text(_dueAt == null ? 'Set date & time' : '${_dueAt!.day}/${_dueAt!.month}/${_dueAt!.year} at ${TimeOfDay.fromDateTime(_dueAt!).format(context)}'), onTap: _pickDateTime),
      const Divider(), Text('Reminder', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)), DropdownButtonFormField<TaskReminderType>(initialValue: _reminderType, items: const [DropdownMenuItem(value: TaskReminderType.none, child: Text('Off')), DropdownMenuItem(value: TaskReminderType.once, child: Text('Remind once')), DropdownMenuItem(value: TaskReminderType.interval, child: Text('Repeat reminder'))], onChanged: (v) => setState(() => _reminderType = v ?? TaskReminderType.none)),
      if (_reminderType == TaskReminderType.interval) DropdownButtonFormField<Duration>(initialValue: _interval, items: const [DropdownMenuItem(value: Duration(minutes: 30), child: Text('Every 30 minutes')), DropdownMenuItem(value: Duration(hours: 1), child: Text('Every hour')), DropdownMenuItem(value: Duration(hours: 2), child: Text('Every 2 hours')), DropdownMenuItem(value: Duration(hours: 4), child: Text('Every 4 hours'))], onChanged: (v) => setState(() => _interval = v)),
      const SizedBox(height: 18), Text('Repeat task', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)), DropdownButtonFormField<TaskRepeat>(initialValue: _repeat, items: const [DropdownMenuItem(value: TaskRepeat.none, child: Text('Does not repeat')), DropdownMenuItem(value: TaskRepeat.daily, child: Text('Daily')), DropdownMenuItem(value: TaskRepeat.weekdays, child: Text('Weekdays')), DropdownMenuItem(value: TaskRepeat.weekly, child: Text('Weekly')), DropdownMenuItem(value: TaskRepeat.monthly, child: Text('Monthly')), DropdownMenuItem(value: TaskRepeat.custom, child: Text('Custom'))], onChanged: (v) => setState(() => _repeat = v ?? TaskRepeat.none)),
      if (_repeat == TaskRepeat.custom) Padding(padding: const EdgeInsets.only(top: 10), child: TextFormField(initialValue: '$_customDays', keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Repeat every N days'), onChanged: (v) => _customDays = int.tryParse(v) ?? 1)),
      const SizedBox(height: 18), Text('Priority', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)), SegmentedButton<TaskPriority>(segments: const [ButtonSegment(value: TaskPriority.low, label: Text('Low')), ButtonSegment(value: TaskPriority.normal, label: Text('Normal')), ButtonSegment(value: TaskPriority.high, label: Text('High'))], selected: {_priority}, onSelectionChanged: (v) => setState(() => _priority = v.first)),
      SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Favorite'), subtitle: const Text('Keep this task easy to find'), value: _favorite, onChanged: (v) => setState(() => _favorite = v)),
      TextField(controller: TextEditingController(text: _category), decoration: const InputDecoration(labelText: 'Category / list', prefixIcon: Icon(Icons.folder_outlined)), onChanged: (v) => _category = v), const SizedBox(height: 12),
      TextField(decoration: const InputDecoration(labelText: 'Tags', hintText: 'work, study, personal', prefixIcon: Icon(Icons.tag)), onSubmitted: (v) { final tag = v.trim(); if (tag.isNotEmpty && !_tags.contains(tag)) setState(() => _tags.add(tag)); }),
      if (_tags.isNotEmpty) Wrap(spacing: 6, children: _tags.map((tag) => InputChip(label: Text(tag), onDeleted: () => setState(() => _tags.remove(tag))).toList()),
      const SizedBox(height: 28), FilledButton.icon(onPressed: _saving ? null : _save, icon: const Icon(Icons.save_outlined), label: Padding(padding: const EdgeInsets.symmetric(vertical: 14), child: Text(_saving ? 'Saving…' : widget.isEditing ? 'Save changes' : 'Create task'))),
    ]));
  }
}
