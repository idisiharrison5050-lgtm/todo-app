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
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    _titleController = TextEditingController(text: task?.title ?? '');
    _notesController = TextEditingController(text: task?.notes ?? '');
    _dueAt = task?.dueAt;
    _priority = task?.priority ?? TaskPriority.normal;
    _reminderType = task?.reminderType ?? (task?.dueAt != null ? TaskReminderType.once : TaskReminderType.none);
    _interval = task?.reminderInterval ?? const Duration(hours: 2);
  }

  @override void dispose() { _titleController.dispose(); _notesController.dispose(); super.dispose(); }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(context: context, firstDate: DateTime(now.year, now.month, now.day), lastDate: DateTime(now.year + 5), initialDate: _dueAt ?? now);
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_dueAt ?? now));
    if (time == null || !mounted) return;
    setState(() { _dueAt = DateTime(date.year, date.month, date.day, time.hour, time.minute); if (_reminderType == TaskReminderType.none) _reminderType = TaskReminderType.once; });
  }

  void _setQuickDue(Duration offset) { final value = DateTime.now().add(offset); setState(() { _dueAt = DateTime(value.year, value.month, value.day, value.hour, value.minute); if (_reminderType == TaskReminderType.none) _reminderType = TaskReminderType.once; }); }
  void _setTomorrow() { final now = DateTime.now().add(const Duration(days: 1)); setState(() { _dueAt = DateTime(now.year, now.month, now.day, 9, 0); if (_reminderType == TaskReminderType.none) _reminderType = TaskReminderType.once; }); }

  Future<void> _save() async {
    if (_saving) return;
    final title = _titleController.text.trim();
    if (title.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Give your task a name first.'))); return; }
    final reminderType = _dueAt == null ? TaskReminderType.none : _reminderType;
    if (_dueAt != null && reminderType != TaskReminderType.none && !_dueAt!.isAfter(DateTime.now())) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Choose a future time for the reminder.'))); return; }
    if (reminderType == TaskReminderType.interval && _interval == null) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Choose how often to repeat the reminder.'))); return; }
    setState(() => _saving = true);
    try {
      if (widget.task == null) {
        await widget.store.addTask(title: title, notes: _notesController.text, dueAt: _dueAt, reminderType: reminderType, reminderInterval: reminderType == TaskReminderType.interval ? _interval : null, priority: _priority);
      } else {
        await widget.store.updateTask(widget.task!.id, title: title, notes: _notesController.text, dueAt: _dueAt, reminderType: reminderType, reminderInterval: reminderType == TaskReminderType.interval ? _interval : null, priority: _priority);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (_) { if (!mounted) return; setState(() => _saving = false); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not save the task. Try again.'))); }
  }

  @override Widget build(BuildContext context) {
    final theme = Theme.of(context); final reminderOn = _dueAt != null && _reminderType != TaskReminderType.none;
    return Scaffold(
      appBar: AppBar(title: Text(widget.isEditing ? 'Edit task' : 'New task'), actions: [TextButton(onPressed: _saving ? null : _save, child: const Text('Save'))]),
      body: ListView(padding: const EdgeInsets.fromLTRB(20, 12, 20, 40), children: [
        TextField(controller: _titleController, autofocus: !widget.isEditing, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(hintText: 'What needs to be done?', prefixIcon: Icon(Icons.check_circle_outline))),
        const SizedBox(height: 12),
        TextField(controller: _notesController, minLines: 2, maxLines: 5, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(hintText: 'Notes (optional)', prefixIcon: Icon(Icons.notes_outlined))),
        const SizedBox(height: 28), Text('Schedule', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)), const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [ActionChip(label: const Text('15 min'), onPressed: () => _setQuickDue(const Duration(minutes: 15))), ActionChip(label: const Text('1 hour'), onPressed: () => _setQuickDue(const Duration(hours: 1))), ActionChip(label: const Text('Tomorrow'), onPressed: _setTomorrow)]),
        const SizedBox(height: 8),
        ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.schedule_outlined), title: Text(_dueAt == null ? 'Set date & time' : _formatDateTime(_dueAt!)), subtitle: const Text('Choose when this task is due'), trailing: _dueAt == null ? const Icon(Icons.chevron_right) : IconButton(tooltip: 'Clear due date', onPressed: () => setState(() { _dueAt = null; _reminderType = TaskReminderType.none; }), icon: const Icon(Icons.close)), onTap: _pickDateTime),
        const Divider(height: 24),
        Card(margin: EdgeInsets.zero, child: SwitchListTile(secondary: Icon(reminderOn ? Icons.notifications_active : Icons.notifications_off_outlined), title: const Text('Reminder'), subtitle: Text(reminderOn ? 'Remind once at the due time' : _dueAt == null ? 'Set a date and time to enable reminders' : 'Off'), value: reminderOn, onChanged: _dueAt == null ? null : (enabled) => setState(() => _reminderType = enabled ? TaskReminderType.once : TaskReminderType.none))),
        if (reminderOn) ...[const SizedBox(height: 8), DropdownButtonFormField<TaskReminderType>(initialValue: _reminderType, decoration: const InputDecoration(prefixIcon: Icon(Icons.notifications_outlined), labelText: 'Reminder type'), items: const [DropdownMenuItem(value: TaskReminderType.once, child: Text('Remind once')), DropdownMenuItem(value: TaskReminderType.interval, child: Text('Repeat reminder'))], onChanged: (value) => setState(() => _reminderType = value ?? TaskReminderType.once))],
        if (_reminderType == TaskReminderType.interval && reminderOn) ...[const SizedBox(height: 12), DropdownButtonFormField<Duration>(initialValue: _interval, decoration: const InputDecoration(prefixIcon: Icon(Icons.repeat), labelText: 'Repeat every'), items: const [DropdownMenuItem(value: Duration(minutes: 30), child: Text('30 minutes')), DropdownMenuItem(value: Duration(hours: 1), child: Text('1 hour')), DropdownMenuItem(value: Duration(hours: 2), child: Text('2 hours')), DropdownMenuItem(value: Duration(hours: 4), child: Text('4 hours'))], onChanged: (value) => setState(() => _interval = value))],
        const SizedBox(height: 28), Text('Priority', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)), const SizedBox(height: 8),
        SegmentedButton<TaskPriority>(segments: const [ButtonSegment(value: TaskPriority.low, label: Text('Low')), ButtonSegment(value: TaskPriority.normal, label: Text('Normal')), ButtonSegment(value: TaskPriority.high, label: Text('High'))], selected: {_priority}, onSelectionChanged: (value) => setState(() => _priority = value.first)),
        const SizedBox(height: 36), FilledButton.icon(onPressed: _saving ? null : _save, icon: const Icon(Icons.add_task), label: Padding(padding: const EdgeInsets.symmetric(vertical: 14), child: Text(_saving ? 'Saving…' : widget.isEditing ? 'Save changes' : 'Create task'))),
      ]),
    );
  }
  String _formatDateTime(DateTime value) => '${value.day}/${value.month}/${value.year} at ${TimeOfDay.fromDateTime(value).format(context)}';
}
