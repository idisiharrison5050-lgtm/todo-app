import 'package:flutter/material.dart';

import '../application/task_store.dart';
import '../domain/task.dart';

class AddTaskPage extends StatefulWidget {
  const AddTaskPage({super.key, required this.store});

  final TaskStore store;

  @override
  State<AddTaskPage> createState() => _AddTaskPageState();
}

class _AddTaskPageState extends State<AddTaskPage> {
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime? _dueAt;
  TaskPriority _priority = TaskPriority.normal;
  TaskReminderType _reminderType = TaskReminderType.none;
  Duration? _interval = const Duration(hours: 2);

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 5),
      initialDate: _dueAt ?? now,
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dueAt ?? now),
    );
    if (time == null) return;

    setState(() {
      _dueAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  void _save() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Give your task a name first.')),
      );
      return;
    }

    widget.store.addTask(
      title: title,
      notes: _notesController.text,
      dueAt: _dueAt,
      reminderType: _reminderType,
      reminderInterval: _reminderType == TaskReminderType.interval ? _interval : null,
      priority: _priority,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('New task'),
        actions: [
          TextButton(onPressed: _save, child: const Text('Save')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: [
          TextField(
            controller: _titleController,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'What needs to be done?',
              prefixIcon: Icon(Icons.check_circle_outline),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            minLines: 2,
            maxLines: 5,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'Notes (optional)',
              prefixIcon: Icon(Icons.notes_outlined),
            ),
          ),
          const SizedBox(height: 28),
          Text('Schedule', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.schedule_outlined),
            title: Text(_dueAt == null ? 'Set date & time' : _formatDateTime(_dueAt!)),
            subtitle: const Text('Choose when this task is due'),
            trailing: _dueAt == null ? const Icon(Icons.chevron_right) : IconButton(onPressed: () => setState(() => _dueAt = null), icon: const Icon(Icons.close)),
            onTap: _pickDateTime,
          ),
          const Divider(height: 24),
          Text('Reminder', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          DropdownButtonFormField<TaskReminderType>(
            initialValue: _reminderType,
            decoration: const InputDecoration(prefixIcon: Icon(Icons.notifications_outlined)),
            items: const [
              DropdownMenuItem(value: TaskReminderType.none, child: Text('No reminder')),
              DropdownMenuItem(value: TaskReminderType.once, child: Text('Remind once')),
              DropdownMenuItem(value: TaskReminderType.interval, child: Text('Repeat reminder')),
            ],
            onChanged: (value) => setState(() => _reminderType = value ?? TaskReminderType.none),
          ),
          if (_reminderType == TaskReminderType.interval) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<Duration>(
              initialValue: _interval,
              decoration: const InputDecoration(prefixIcon: Icon(Icons.repeat)),
              items: const [
                DropdownMenuItem(value: Duration(minutes: 30), child: Text('Every 30 minutes')),
                DropdownMenuItem(value: Duration(hours: 1), child: Text('Every hour')),
                DropdownMenuItem(value: Duration(hours: 2), child: Text('Every 2 hours')),
                DropdownMenuItem(value: Duration(hours: 4), child: Text('Every 4 hours')),
              ],
              onChanged: (value) => setState(() => _interval = value),
            ),
          ],
          const SizedBox(height: 28),
          Text('Priority', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          SegmentedButton<TaskPriority>(
            segments: const [
              ButtonSegment(value: TaskPriority.low, label: Text('Low')),
              ButtonSegment(value: TaskPriority.normal, label: Text('Normal')),
              ButtonSegment(value: TaskPriority.high, label: Text('High')),
            ],
            selected: {_priority},
            onSelectionChanged: (value) => setState(() => _priority = value.first),
          ),
          const SizedBox(height: 36),
          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.add_task),
            label: const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Text('Create task')),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime value) {
    final time = TimeOfDay.fromDateTime(value).format(context);
    return '${value.day}/${value.month}/${value.year} at $time';
  }
}
