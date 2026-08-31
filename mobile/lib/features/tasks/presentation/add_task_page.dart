import 'package:flutter/material.dart';

import '../application/task_store.dart';
import '../domain/task.dart';

class AddTaskPage extends StatefulWidget {
  const AddTaskPage({super.key, required this.store, this.task});

  final TaskStore store;
  final Task? task;

  bool get isEditing => task != null;

  @override
  State<AddTaskPage> createState() => _AddTaskPageState();
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
    _reminderType = task?.reminderType ?? TaskReminderType.none;
    _interval = task?.reminderInterval ?? const Duration(hours: 2);
  }

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

    final selectedDate = DateTime(date.year, date.month, date.day);
    final sameDay = selectedDate.year == now.year && selectedDate.month == now.month && selectedDate.day == now.day;
    final minimum = now.add(const Duration(minutes: 1));
    final defaultTime = sameDay ? now.add(const Duration(minutes: 2)) : (_dueAt ?? DateTime(date.year, date.month, date.day, 9));

    final time = await _showScrollTimePicker(
      initialDateTime: defaultTime,
      minimumDateTime: sameDay ? minimum : null,
    );
    if (time == null || !mounted) return;

    final value = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    if (sameDay && !_isSelectableTime(value, now)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Choose at least 1 minute from now.')));
      return;
    }

    setState(() {
      _dueAt = value;
      if (_reminderType == TaskReminderType.none) _reminderType = TaskReminderType.once;
    });
  }

  Future<TimeOfDay?> _showScrollTimePicker({
    required DateTime initialDateTime,
    DateTime? minimumDateTime,
  }) async {
    final defaultDateTime = minimumDateTime != null && initialDateTime.isBefore(minimumDateTime)
        ? minimumDateTime.add(const Duration(minutes: 1))
        : initialDateTime;
    final initial = TimeOfDay.fromDateTime(defaultDateTime);
    var selectedHour = initial.hourOfPeriod == 0 ? 12 : initial.hourOfPeriod;
    var selectedMinute = initial.minute;
    var selectedPeriod = initial.period;

    final result = await showModalBottomSheet<TimeOfDay>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        final hourController = FixedExtentScrollController(initialItem: selectedHour - 1);
        final minuteController = FixedExtentScrollController(initialItem: selectedMinute);
        final periodController = FixedExtentScrollController(initialItem: selectedPeriod == DayPeriod.am ? 0 : 1);

        return StatefulBuilder(
          builder: (context, setSheetState) {
            final candidate = _timeOfDayDateTime(selectedHour, selectedMinute, selectedPeriod);
            final valid = minimumDateTime == null || _isSelectableTime(candidate, minimumDateTime);
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Align(alignment: Alignment.centerLeft, child: Text('Choose time', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800))),
                    const SizedBox(height: 6),
                    Text(
                      minimumDateTime == null ? 'Scroll to choose a reminder time.' : 'Default is 2 minutes ahead. You can choose from 1 minute ahead.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 190,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _timeWheel(controller: hourController, itemCount: 12, builder: (index) => '${index + 1}', onChanged: (index) => setSheetState(() => selectedHour = index + 1)),
                          const Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Text(':', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800))),
                          _timeWheel(controller: minuteController, itemCount: 60, builder: (index) => index.toString().padLeft(2, '0'), onChanged: (index) => setSheetState(() => selectedMinute = index)),
                          const SizedBox(width: 12),
                          _timeWheel(controller: periodController, itemCount: 2, builder: (index) => index == 0 ? 'AM' : 'PM', onChanged: (index) => setSheetState(() => selectedPeriod = index == 0 ? DayPeriod.am : DayPeriod.pm)),
                        ],
                      ),
                    ),
                    if (!valid) const Padding(padding: EdgeInsets.only(bottom: 8), child: Text('That time has already passed.', style: TextStyle(fontWeight: FontWeight.w600))),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: valid ? () => Navigator.of(sheetContext).pop(TimeOfDay(hour: selectedPeriod == DayPeriod.am ? selectedHour % 12 : (selectedHour % 12) + 12, minute: selectedMinute)) : null,
                        child: const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('Set reminder time')),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    return result;
  }

  Widget _timeWheel({
    required FixedExtentScrollController controller,
    required int itemCount,
    required String Function(int index) builder,
    required ValueChanged<int> onChanged,
  }) {
    return SizedBox(
      width: 72,
      child: ListWheelScrollView.useDelegate(
        controller: controller,
        itemExtent: 48,
        perspective: 0.003,
        diameterRatio: 1.5,
        physics: const FixedExtentScrollPhysics(),
        onSelectedItemChanged: onChanged,
        childDelegate: ListWheelChildBuilderDelegate(
          childCount: itemCount,
          builder: (context, index) => Center(child: Text(builder(index), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700))),
        ),
      ),
    );
  }

  DateTime _timeOfDayDateTime(int hour, int minute, DayPeriod period) {
    final now = DateTime.now();
    final hour24 = period == DayPeriod.am ? hour % 12 : (hour % 12) + 12;
    return DateTime(now.year, now.month, now.day, hour24, minute);
  }

  bool _isSelectableTime(DateTime value, DateTime reference) {
    final valueMinute = DateTime(value.year, value.month, value.day, value.hour, value.minute);
    final referenceMinute = DateTime(reference.year, reference.month, reference.day, reference.hour, reference.minute);
    return valueMinute.isAfter(referenceMinute);
  }

  void _setQuickDue(Duration offset) {
    final value = DateTime.now().add(offset);
    setState(() {
      _dueAt = DateTime(value.year, value.month, value.day, value.hour, value.minute);
      if (_reminderType == TaskReminderType.none) _reminderType = TaskReminderType.once;
    });
  }

  void _setTomorrow() {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    setState(() {
      _dueAt = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 9, 0);
      if (_reminderType == TaskReminderType.none) _reminderType = TaskReminderType.once;
    });
  }

  void _clearDueDate() {
    setState(() {
      _dueAt = null;
      _reminderType = TaskReminderType.none;
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Give your task a name first.')));
      return;
    }
    if (_dueAt != null && _reminderType != TaskReminderType.none && !_dueAt!.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Choose a future time for the reminder.')));
      return;
    }
    if (_reminderType == TaskReminderType.interval && _interval == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Choose how often to repeat the reminder.')));
      return;
    }
    setState(() => _saving = true);
    try {
      if (widget.task == null) {
        await widget.store.addTask(title: title, notes: _notesController.text, dueAt: _dueAt, reminderType: _reminderType, reminderInterval: _reminderType == TaskReminderType.interval ? _interval : null, priority: _priority);
      } else {
        await widget.store.updateTask(widget.task!.id, title: title, notes: _notesController.text, dueAt: _dueAt, reminderType: _reminderType, reminderInterval: _reminderType == TaskReminderType.interval ? _interval : null, priority: _priority);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not save the task. Try again.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit task' : 'New task'),
        actions: [TextButton(onPressed: _saving ? null : _save, child: const Text('Save'))],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: [
          TextField(controller: _titleController, autofocus: !widget.isEditing, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(hintText: 'What needs to be done?', prefixIcon: Icon(Icons.check_circle_outline))),
          const SizedBox(height: 12),
          TextField(controller: _notesController, minLines: 2, maxLines: 5, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(hintText: 'Notes (optional)', prefixIcon: Icon(Icons.notes_outlined))),
          const SizedBox(height: 28),
          Text('Schedule', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            ActionChip(label: const Text('15 min'), onPressed: () => _setQuickDue(const Duration(minutes: 15))),
            ActionChip(label: const Text('1 hour'), onPressed: () => _setQuickDue(const Duration(hours: 1))),
            ActionChip(label: const Text('Tomorrow'), onPressed: _setTomorrow),
          ]),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.schedule_outlined),
            title: Text(_dueAt == null ? 'Set date & time' : _formatDateTime(_dueAt!)),
            subtitle: const Text('Choose when this task is due'),
            trailing: _dueAt == null ? const Icon(Icons.chevron_right) : IconButton(tooltip: 'Clear due date', onPressed: _clearDueDate, icon: const Icon(Icons.close)),
            onTap: _pickDateTime,
          ),
          const Divider(height: 24),
          Text('Reminder', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(_reminderType == TaskReminderType.none ? 'Off' : _reminderType == TaskReminderType.once ? 'On — remind once' : 'On — repeating', style: theme.textTheme.bodySmall),
          const SizedBox(height: 8),
          DropdownButtonFormField<TaskReminderType>(
            initialValue: _reminderType,
            decoration: const InputDecoration(prefixIcon: Icon(Icons.notifications_outlined)),
            items: const [
              DropdownMenuItem(value: TaskReminderType.none, child: Text('Turn reminder off')),
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
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.add_task),
            label: Padding(padding: const EdgeInsets.symmetric(vertical: 14), child: Text(_saving ? 'Saving…' : widget.isEditing ? 'Save changes' : 'Create task')),
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
