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
  late final TextEditingController _categoryController;
  DateTime? _dueAt;
  TaskPriority _priority = TaskPriority.normal;
  TaskReminderType _reminderType = TaskReminderType.none;
  Duration? _interval = const Duration(hours: 2);
  TaskRepeat _repeat = TaskRepeat.none;
  int _customDays = 1;
  bool _favorite = false;
  bool _saving = false;
  final List<String> _tags = <String>[];

  @override
  void initState() {
    super.initState();
    final t = widget.task;
    _titleController = TextEditingController(text: t?.title ?? '');
    _notesController = TextEditingController(text: t?.notes ?? '');
    _categoryController = TextEditingController(text: t?.category ?? '');
    _dueAt = t?.dueAt;
    _priority = t?.priority ?? TaskPriority.normal;
    _reminderType = t?.reminderType ?? TaskReminderType.none;
    _interval = t?.reminderInterval ?? const Duration(hours: 2);
    _repeat = t?.repeat ?? TaskRepeat.none;
    _customDays = t?.repeatIntervalDays ?? 1;
    _favorite = t?.isFavorite ?? false;
    _tags.addAll(t?.tags ?? const <String>[]);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 5),
      initialDate: _dueAt ?? now,
    );
    if (date == null || !mounted) return;
    final initial = _dueAt ?? now;
    final time = await showWheelTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !mounted) return;
    final value = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    final currentMinute = DateTime(now.year, now.month, now.day, now.hour, now.minute);
    final selectedMinute = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    if (selectedMinute.isBefore(currentMinute)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Choose a future time.')));
      return;
    }
    setState(() {
      _dueAt = value;
      if (_reminderType == TaskReminderType.none) _reminderType = TaskReminderType.once;
    });
  }

  void _quick(Duration duration) {
    final value = DateTime.now().add(duration);
    setState(() {
      _dueAt = DateTime(value.year, value.month, value.day, value.hour, value.minute);
      if (_reminderType == TaskReminderType.none) _reminderType = TaskReminderType.once;
    });
  }

  void _tomorrow() {
    final value = DateTime.now().add(const Duration(days: 1));
    setState(() {
      _dueAt = DateTime(value.year, value.month, value.day, 9);
      if (_reminderType == TaskReminderType.none) _reminderType = TaskReminderType.once;
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Give your task a name first.')));
      return;
    }
    setState(() => _saving = true);
    try {
      if (widget.task == null) {
        await widget.store.addTask(title: title, notes: _notesController.text, dueAt: _dueAt, reminderType: _reminderType, reminderInterval: _reminderType == TaskReminderType.interval ? _interval : null, priority: _priority, repeat: _repeat, repeatIntervalDays: _repeat == TaskRepeat.custom ? _customDays : null, isFavorite: _favorite, category: _categoryController.text.trim(), tags: _tags);
      } else {
        await widget.store.updateTask(widget.task!.id, title: title, notes: _notesController.text, dueAt: _dueAt, reminderType: _reminderType, reminderInterval: _reminderType == TaskReminderType.interval ? _interval : null, priority: _priority, repeat: _repeat, repeatIntervalDays: _repeat == TaskRepeat.custom ? _customDays : null, isFavorite: _favorite, category: _categoryController.text.trim(), tags: _tags);
      }
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not save the task. Try again.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final children = <Widget>[
      TextField(controller: _titleController, autofocus: !widget.isEditing, decoration: const InputDecoration(hintText: 'What needs to be done?', prefixIcon: Icon(Icons.check_circle_outline))),
      const SizedBox(height: 12),
      TextField(controller: _notesController, minLines: 3, maxLines: 6, decoration: const InputDecoration(hintText: 'Notes', prefixIcon: Icon(Icons.notes_outlined))),
      const SizedBox(height: 24),
      Text('Schedule', style: theme.textTheme.titleMedium),
      Wrap(spacing: 8, children: [
        ActionChip(label: const Text('15 min'), onPressed: () => _quick(const Duration(minutes: 15))),
        ActionChip(label: const Text('1 hour'), onPressed: () => _quick(const Duration(hours: 1))),
        ActionChip(label: const Text('Tomorrow'), onPressed: _tomorrow),
      ]),
      ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.schedule_outlined), title: Text(_dueAt == null ? 'Set date & time' : '${_dueAt!.day}/${_dueAt!.month}/${_dueAt!.year} at ${TimeOfDay.fromDateTime(_dueAt!).format(context)}'), onTap: _pickDateTime),
      const Divider(),
      Text('Reminder', style: theme.textTheme.titleMedium),
      DropdownButtonFormField<TaskReminderType>(initialValue: _reminderType, items: const [
        DropdownMenuItem(value: TaskReminderType.none, child: Text('Off')),
        DropdownMenuItem(value: TaskReminderType.once, child: Text('Remind once')),
        DropdownMenuItem(value: TaskReminderType.interval, child: Text('Repeat reminder')),
      ], onChanged: (v) => setState(() => _reminderType = v ?? TaskReminderType.none)),
    ];
    if (_reminderType == TaskReminderType.interval) {
      children.add(DropdownButtonFormField<Duration>(initialValue: _interval, items: const [
        DropdownMenuItem(value: Duration(minutes: 30), child: Text('Every 30 minutes')),
        DropdownMenuItem(value: Duration(hours: 1), child: Text('Every hour')),
        DropdownMenuItem(value: Duration(hours: 2), child: Text('Every 2 hours')),
        DropdownMenuItem(value: Duration(hours: 4), child: Text('Every 4 hours')),
      ], onChanged: (v) => setState(() => _interval = v)));
    }
    children.addAll([
      const SizedBox(height: 18),
      Text('Repeat task', style: theme.textTheme.titleMedium),
      DropdownButtonFormField<TaskRepeat>(initialValue: _repeat, items: const [
        DropdownMenuItem(value: TaskRepeat.none, child: Text('Does not repeat')),
        DropdownMenuItem(value: TaskRepeat.daily, child: Text('Daily')),
        DropdownMenuItem(value: TaskRepeat.weekdays, child: Text('Weekdays')),
        DropdownMenuItem(value: TaskRepeat.weekly, child: Text('Weekly')),
        DropdownMenuItem(value: TaskRepeat.monthly, child: Text('Monthly')),
        DropdownMenuItem(value: TaskRepeat.custom, child: Text('Custom')),
      ], onChanged: (v) => setState(() => _repeat = v ?? TaskRepeat.none)),
    ]);
    if (_repeat == TaskRepeat.custom) {
      children.add(TextFormField(initialValue: '$_customDays', keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Repeat every N days'), onChanged: (v) => _customDays = int.tryParse(v) ?? 1));
    }
    children.addAll([
      const SizedBox(height: 18),
      Text('Priority', style: theme.textTheme.titleMedium),
      SegmentedButton<TaskPriority>(segments: const [ButtonSegment(value: TaskPriority.low, label: Text('Low')), ButtonSegment(value: TaskPriority.normal, label: Text('Normal')), ButtonSegment(value: TaskPriority.high, label: Text('High'))], selected: {_priority}, onSelectionChanged: (v) => setState(() => _priority = v.first)),
      SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Favorite'), value: _favorite, onChanged: (v) => setState(() => _favorite = v)),
      TextField(controller: _categoryController, decoration: const InputDecoration(labelText: 'Category / list', prefixIcon: Icon(Icons.folder_outlined))),
      const SizedBox(height: 12),
      TextField(decoration: const InputDecoration(labelText: 'Tags', hintText: 'work, study, personal', prefixIcon: Icon(Icons.tag)), onSubmitted: (v) { final tag = v.trim(); if (tag.isNotEmpty && !_tags.contains(tag)) setState(() => _tags.add(tag)); }),
    ]);
    if (_tags.isNotEmpty) {
      children.add(Wrap(spacing: 6, children: _tags.map<Widget>((tag) => InputChip(label: Text(tag), onDeleted: () => setState(() => _tags.remove(tag)))).toList()));
    }
    children.addAll([
      const SizedBox(height: 28),
      FilledButton.icon(onPressed: _saving ? null : _save, icon: const Icon(Icons.save_outlined), label: Padding(padding: const EdgeInsets.symmetric(vertical: 14), child: Text(_saving ? 'Saving…' : widget.isEditing ? 'Save changes' : 'Create task'))),
    ]);
    return Scaffold(appBar: AppBar(title: Text(widget.isEditing ? 'Edit task' : 'New task'), actions: [TextButton(onPressed: _saving ? null : _save, child: const Text('Save'))]), body: ListView(padding: const EdgeInsets.fromLTRB(20, 12, 20, 40), children: children));
  }
}

Future<TimeOfDay?> showWheelTimePicker({required BuildContext context, required TimeOfDay initialTime}) {
  return showModalBottomSheet<TimeOfDay>(
    context: context,
    backgroundColor: Colors.black,
    barrierColor: Colors.black87,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => _WheelTimePicker(initialTime: initialTime),
  );
}

class _WheelTimePicker extends StatefulWidget {
  const _WheelTimePicker({required this.initialTime});
  final TimeOfDay initialTime;
  @override State<_WheelTimePicker> createState() => _WheelTimePickerState();
}

class _WheelTimePickerState extends State<_WheelTimePicker> {
  late int _hour;
  late int _minute;
  late final FixedExtentScrollController _hourController;
  late final FixedExtentScrollController _minuteController;

  @override
  void initState() {
    super.initState();
    _hour = widget.initialTime.hour;
    _minute = widget.initialTime.minute;
    _hourController = FixedExtentScrollController(initialItem: _hour);
    _minuteController = FixedExtentScrollController(initialItem: _minute);
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  String _twoDigits(int value) => value.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      decoration: const BoxDecoration(color: Colors.black, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 42, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(4))),
          const SizedBox(height: 18),
          Row(children: [
            const Expanded(child: Text('Set time', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700))),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            const SizedBox(width: 4),
            FilledButton(onPressed: () => Navigator.pop(context, TimeOfDay(hour: _hour, minute: _minute)), child: const Text('Done')),
          ]),
          const SizedBox(height: 18),
          SizedBox(
            height: 218,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: IgnorePointer(
                    child: Center(
                      child: Container(
                        height: 64,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(border: Border.symmetric(horizontal: BorderSide(color: Colors.white.withOpacity(.08)))),
                      ),
                    ),
                  ),
                ),
                Row(children: [
                  Expanded(child: _wheel(controller: _hourController, count: 24, selected: _hour, onChanged: (value) => setState(() => _hour = value))),
                  const _WheelSeparator(text: 'h'),
                  Expanded(child: _wheel(controller: _minuteController, count: 60, selected: _minute, onChanged: (value) => setState(() => _minute = value))),
                  const _WheelSeparator(text: 'm'),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _wheel({required FixedExtentScrollController controller, required int count, required int selected, required ValueChanged<int> onChanged}) {
    return ListWheelScrollView.useDelegate(
      controller: controller,
      itemExtent: 76,
      diameterRatio: 1.9,
      perspective: 0.003,
      physics: const FixedExtentScrollPhysics(),
      onSelectedItemChanged: onChanged,
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: count,
        builder: (context, index) {
          if (index == null) return null;
          final distance = (index - selected).abs();
          final opacity = distance == 0 ? 1.0 : distance == 1 ? .32 : .12;
          final scale = distance == 0 ? 1.0 : .82;
          return Center(
            child: Opacity(
              opacity: opacity,
              child: Transform.scale(
                scale: scale,
                child: Text(_twoDigits(index), style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w300, height: 1)),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _WheelSeparator extends StatelessWidget {
  const _WheelSeparator({required this.text});
  final String text;
  @override Widget build(BuildContext context) => SizedBox(width: 24, child: Center(child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 22, fontWeight: FontWeight.w400))));
}
