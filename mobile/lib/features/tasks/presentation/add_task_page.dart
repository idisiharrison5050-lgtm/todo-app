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
  late final TextEditingController _tagController;
  late final TextEditingController _customDaysController;
  DateTime? _dueAt;
  TaskPriority _priority = TaskPriority.normal;
  TaskReminderType _reminderType = TaskReminderType.none;
  Duration? _interval = const Duration(hours: 2);
  TaskRepeat _repeat = TaskRepeat.none;
  bool _favorite = false;
  bool _saving = false;
  bool _showAdvanced = false;
  final List<String> _tags = <String>[];

  @override
  void initState() {
    super.initState();
    final t = widget.task;
    _titleController = TextEditingController(text: t?.title ?? '');
    _notesController = TextEditingController(text: t?.notes ?? '');
    _categoryController = TextEditingController(text: t?.category ?? '');
    _tagController = TextEditingController();
    _customDaysController = TextEditingController(text: '${t?.repeatIntervalDays ?? 1}');
    _dueAt = t?.dueAt;
    _priority = t?.priority ?? TaskPriority.normal;
    _reminderType = t?.reminderType ?? TaskReminderType.none;
    _interval = t?.reminderInterval ?? const Duration(hours: 2);
    _repeat = t?.repeat ?? TaskRepeat.none;
    _favorite = t?.isFavorite ?? false;
    _tags.addAll(t?.tags ?? const <String>[]);
    _showAdvanced = widget.isEditing && (_repeat != TaskRepeat.none || _priority != TaskPriority.normal || _tags.isNotEmpty || _categoryController.text.isNotEmpty);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _categoryController.dispose();
    _tagController.dispose();
    _customDaysController.dispose();
    super.dispose();
  }

  void _setDue(DateTime value) {
    final now = DateTime.now();
    final minute = DateTime(now.year, now.month, now.day, now.hour, now.minute);
    final selected = DateTime(value.year, value.month, value.day, value.hour, value.minute);
    if (selected.isBefore(minute)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Choose a future time.')));
      return;
    }
    setState(() {
      _dueAt = selected;
      if (_reminderType == TaskReminderType.none) _reminderType = TaskReminderType.once;
    });
  }

  void _quick(Duration duration) => _setDue(DateTime.now().add(duration));

  void _tomorrow() {
    final value = DateTime.now().add(const Duration(days: 1));
    _setDue(DateTime(value.year, value.month, value.day, 9));
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
    final time = await showWheelTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(initial));
    if (time == null || !mounted) return;
    _setDue(DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  Future<void> _save() async {
    if (_saving) return;
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Give your task a name first.')));
      return;
    }
    final customDays = int.tryParse(_customDaysController.text.trim()) ?? 1;
    if (_repeat == TaskRepeat.custom && (customDays < 1 || customDays > 365)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Custom repeat must be between 1 and 365 days.')));
      return;
    }
    setState(() => _saving = true);
    try {
      final args = <String, dynamic>{
        'title': title,
        'notes': _notesController.text.trim(),
        'dueAt': _dueAt,
        'reminderType': _reminderType,
        'reminderInterval': _reminderType == TaskReminderType.interval ? _interval : null,
        'priority': _priority,
        'repeat': _repeat,
        'repeatIntervalDays': _repeat == TaskRepeat.custom ? customDays : null,
        'isFavorite': _favorite,
        'category': _categoryController.text.trim(),
        'tags': List<String>.from(_tags),
      };
      if (widget.task == null) {
        await widget.store.addTask(
          title: args['title'], notes: args['notes'], dueAt: args['dueAt'], reminderType: args['reminderType'],
          reminderInterval: args['reminderInterval'], priority: args['priority'], repeat: args['repeat'],
          repeatIntervalDays: args['repeatIntervalDays'], isFavorite: args['isFavorite'], category: args['category'], tags: args['tags'],
        );
      } else {
        await widget.store.updateTask(
          widget.task!.id, title: args['title'], notes: args['notes'], dueAt: args['dueAt'], reminderType: args['reminderType'],
          reminderInterval: args['reminderInterval'], priority: args['priority'], repeat: args['repeat'],
          repeatIntervalDays: args['repeatIntervalDays'], isFavorite: args['isFavorite'], category: args['category'], tags: args['tags'],
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      final message = error is ArgumentError ? error.message.toString() : 'Could not save the task. Try again.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  void _addTag() {
    final tag = _tagController.text.trim().replaceAll(RegExp(r'^#+'), '');
    if (tag.isEmpty || _tags.contains(tag)) return;
    setState(() => _tags.add(tag));
    _tagController.clear();
  }

  String _scheduleLabel(BuildContext context) {
    if (_dueAt == null) return 'No date or time';
    final date = MaterialLocalizations.of(context).formatMediumDate(_dueAt!);
    return '$date • ${TimeOfDay.fromDateTime(_dueAt!).format(context)}';
  }

  String _reminderLabel() => switch (_reminderType) {
    TaskReminderType.none => 'Off',
    TaskReminderType.once => 'At task time',
    TaskReminderType.interval => 'Every ${_formatDuration(_interval)}',
  };

  String _formatDuration(Duration? value) {
    if (value == null) return 'Not configured';
    if (value.inHours >= 1 && value.inMinutes % 60 == 0) return '${value.inHours} hour${value.inHours == 1 ? '' : 's'}';
    return '${value.inMinutes} minutes';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit task' : 'New task'),
        actions: [TextButton(onPressed: _saving ? null : _save, child: const Text('Save'))],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
        children: [
          Text(widget.isEditing ? 'Make it better.' : 'What are you getting done?', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 6),
          Text(widget.isEditing ? 'Update the details and keep your plan moving.' : 'Capture it now. Organize the details when you need them.', style: theme.textTheme.bodyMedium),
          const SizedBox(height: 24),
          _SurfaceSection(
            child: Column(children: [
              TextField(
                controller: _titleController,
                autofocus: !widget.isEditing,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                decoration: const InputDecoration(hintText: 'Task name', prefixIcon: Icon(Icons.check_circle_outline)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _notesController,
                minLines: 2,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(hintText: 'Add a note (optional)', prefixIcon: Icon(Icons.notes_outlined)),
              ),
            ]),
          ),
          const SizedBox(height: 20),
          _SectionHeading(icon: Icons.schedule_rounded, title: 'When', subtitle: 'Set a moment or leave it open-ended.'),
          const SizedBox(height: 10),
          _SurfaceSection(
            child: Column(children: [
              Wrap(spacing: 8, runSpacing: 8, children: [
                _QuickChip(label: '15 min', icon: Icons.bolt_rounded, onTap: () => _quick(const Duration(minutes: 15))),
                _QuickChip(label: '1 hour', icon: Icons.schedule_rounded, onTap: () => _quick(const Duration(hours: 1))),
                _QuickChip(label: 'Tomorrow', icon: Icons.wb_sunny_outlined, onTap: _tomorrow),
                _QuickChip(label: 'Pick date', icon: Icons.calendar_today_outlined, onTap: _pickDateTime),
              ]),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                leading: CircleAvatar(backgroundColor: scheme.primary.withValues(alpha: .1), foregroundColor: scheme.primary, child: const Icon(Icons.event_available_outlined)),
                title: Text(_scheduleLabel(context), style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(_dueAt == null ? 'Tap to schedule' : 'Tap to change', style: theme.textTheme.bodySmall),
                trailing: _dueAt == null ? const Icon(Icons.chevron_right_rounded) : IconButton(tooltip: 'Clear schedule', onPressed: () => setState(() { _dueAt = null; _reminderType = TaskReminderType.none; }), icon: const Icon(Icons.close_rounded)),
                onTap: _pickDateTime,
              ),
            ]),
          ),
          const SizedBox(height: 20),
          _SectionHeading(icon: Icons.notifications_active_outlined, title: 'Reminder', subtitle: 'Never rely on memory alone.'),
          const SizedBox(height: 10),
          _SurfaceSection(
            child: Column(children: [
              _ChoiceRow(icon: Icons.notifications_none_rounded, title: 'No reminder', selected: _reminderType == TaskReminderType.none, onTap: () => setState(() => _reminderType = TaskReminderType.none)),
              _ChoiceRow(icon: Icons.notifications_active_outlined, title: 'Remind once', trailing: 'At the scheduled time', selected: _reminderType == TaskReminderType.once, onTap: () => setState(() => _reminderType = TaskReminderType.once)),
              _ChoiceRow(icon: Icons.repeat_rounded, title: 'Keep reminding me', trailing: 'Until completed', selected: _reminderType == TaskReminderType.interval, onTap: () => setState(() => _reminderType = TaskReminderType.interval)),
              if (_reminderType == TaskReminderType.interval) ...[
                const Divider(height: 20),
                DropdownButtonFormField<Duration>(
                  initialValue: _interval,
                  decoration: const InputDecoration(labelText: 'Reminder frequency'),
                  items: const [
                    DropdownMenuItem(value: Duration(minutes: 30), child: Text('Every 30 minutes')),
                    DropdownMenuItem(value: Duration(hours: 1), child: Text('Every hour')),
                    DropdownMenuItem(value: Duration(hours: 2), child: Text('Every 2 hours')),
                    DropdownMenuItem(value: Duration(hours: 4), child: Text('Every 4 hours')),
                  ],
                  onChanged: (v) => setState(() => _interval = v),
                ),
              ],
            ]),
          ),
          const SizedBox(height: 20),
          _SurfaceSection(
            child: Column(children: [
              _SectionHeading(icon: Icons.tune_rounded, title: 'Details', subtitle: _showAdvanced ? 'Fine-tune how this task behaves.' : 'Priority, repeat, list and tags.', compact: true),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(backgroundColor: scheme.primary.withValues(alpha: .1), foregroundColor: scheme.primary, child: const Icon(Icons.tune_rounded)),
                title: const Text('Advanced options', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(_showAdvanced ? 'Shown' : 'Hidden until you need them'),
                trailing: Icon(_showAdvanced ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded),
                onTap: () => setState(() => _showAdvanced = !_showAdvanced),
              ),
              if (_showAdvanced) ...[
                const Divider(height: 20),
                Align(alignment: Alignment.centerLeft, child: Text('Priority', style: theme.textTheme.titleMedium)),
                const SizedBox(height: 10),
                SegmentedButton<TaskPriority>(
                  segments: const [
                    ButtonSegment(value: TaskPriority.low, label: Text('Low'), icon: Icon(Icons.south_rounded)),
                    ButtonSegment(value: TaskPriority.normal, label: Text('Normal'), icon: Icon(Icons.remove_rounded)),
                    ButtonSegment(value: TaskPriority.high, label: Text('High'), icon: Icon(Icons.priority_high_rounded)),
                  ],
                  selected: {_priority},
                  onSelectionChanged: (v) => setState(() => _priority = v.first),
                ),
                const SizedBox(height: 18),
                DropdownButtonFormField<TaskRepeat>(
                  initialValue: _repeat,
                  decoration: const InputDecoration(labelText: 'Repeat task', prefixIcon: Icon(Icons.repeat_rounded)),
                  items: const [
                    DropdownMenuItem(value: TaskRepeat.none, child: Text('Does not repeat')),
                    DropdownMenuItem(value: TaskRepeat.daily, child: Text('Every day')),
                    DropdownMenuItem(value: TaskRepeat.weekdays, child: Text('Weekdays')),
                    DropdownMenuItem(value: TaskRepeat.weekly, child: Text('Every week')),
                    DropdownMenuItem(value: TaskRepeat.monthly, child: Text('Every month')),
                    DropdownMenuItem(value: TaskRepeat.custom, child: Text('Custom interval')),
                  ],
                  onChanged: (v) => setState(() => _repeat = v ?? TaskRepeat.none),
                ),
                if (_repeat == TaskRepeat.custom) ...[
                  const SizedBox(height: 10),
                  TextField(controller: _customDaysController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Repeat every N days', prefixIcon: Icon(Icons.timelapse_rounded))),
                ],
                const SizedBox(height: 12),
                TextField(controller: _categoryController, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'List / category', hintText: 'Work, Personal, Study', prefixIcon: Icon(Icons.folder_outlined))),
                const SizedBox(height: 12),
                TextField(controller: _tagController, textInputAction: TextInputAction.done, onSubmitted: (_) => _addTag(), decoration: const InputDecoration(labelText: 'Add tag', hintText: 'work, study, personal', prefixIcon: Icon(Icons.tag), suffixIcon: Icon(Icons.add_rounded))),
                if (_tags.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Align(alignment: Alignment.centerLeft, child: Wrap(spacing: 6, runSpacing: 6, children: _tags.map<Widget>((tag) => InputChip(label: Text(tag), onDeleted: () => setState(() => _tags.remove(tag)))).toList())),
                ],
                SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Favorite', style: TextStyle(fontWeight: FontWeight.w700)), subtitle: const Text('Keep this task close at hand'), value: _favorite, onChanged: (v) => setState(() => _favorite = v)),
              ],
            ]),
          ),
          const SizedBox(height: 24),
          if (_dueAt != null || _reminderType != TaskReminderType.none || _repeat != TaskRepeat.none)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: scheme.primary.withValues(alpha: .07), borderRadius: BorderRadius.circular(18), border: Border.all(color: scheme.primary.withValues(alpha: .12))),
              child: Row(children: [Icon(Icons.auto_awesome_rounded, color: scheme.primary, size: 20), const SizedBox(width: 10), Expanded(child: Text('Ready: ${_scheduleLabel(context)}${_reminderType == TaskReminderType.none ? '' : ' • ${_reminderLabel()}'}', style: const TextStyle(fontWeight: FontWeight.w700)))]),
            ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : Icon(widget.isEditing ? Icons.check_rounded : Icons.add_rounded),
            label: Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Text(_saving ? 'Saving…' : widget.isEditing ? 'Save changes' : 'Create task')),
          ),
        ],
      ),
    );
  }
}

class _SurfaceSection extends StatelessWidget {
  const _SurfaceSection({required this.child});
  final Widget child;
  @override Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(16), child: child));
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.icon, required this.title, required this.subtitle, this.compact = false});
  final IconData icon;
  final String title;
  final String subtitle;
  final bool compact;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(children: [
      if (!compact) ...[CircleAvatar(radius: 19, backgroundColor: scheme.primary.withValues(alpha: .1), foregroundColor: scheme.primary, child: Icon(icon, size: 20)), const SizedBox(width: 11)],
      if (compact) ...[Icon(icon, color: scheme.primary, size: 20), const SizedBox(width: 9)],
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: Theme.of(context).textTheme.titleMedium), const SizedBox(height: 2), Text(subtitle, style: Theme.of(context).textTheme.bodySmall)])),
    ]);
  }
}

class _QuickChip extends StatelessWidget {
  const _QuickChip({required this.label, required this.icon, required this.onTap});
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  @override Widget build(BuildContext context) => ActionChip(avatar: Icon(icon, size: 16), label: Text(label), onPressed: onTap);
}

class _ChoiceRow extends StatelessWidget {
  const _ChoiceRow({required this.icon, required this.title, required this.selected, required this.onTap, this.trailing});
  final IconData icon;
  final String title;
  final String? trailing;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 2),
      leading: CircleAvatar(backgroundColor: selected ? scheme.primary.withValues(alpha: .12) : scheme.surfaceContainerHighest, foregroundColor: selected ? scheme.primary : scheme.onSurfaceVariant, child: Icon(icon, size: 20)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: trailing == null ? null : Text(trailing!),
      trailing: selected ? Icon(Icons.check_circle_rounded, color: scheme.primary) : const Icon(Icons.radio_button_unchecked_rounded),
      onTap: onTap,
    );
  }
}

Future<TimeOfDay?> showWheelTimePicker({required BuildContext context, required TimeOfDay initialTime}) {
  return showModalBottomSheet<TimeOfDay>(
    context: context,
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
  void dispose() { _hourController.dispose(); _minuteController.dispose(); super.dispose(); }
  String _twoDigits(int value) => value.toString().padLeft(2, '0');
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      decoration: BoxDecoration(color: scheme.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(30))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 42, height: 4, decoration: BoxDecoration(color: scheme.onSurface.withValues(alpha: .15), borderRadius: BorderRadius.circular(4))),
        const SizedBox(height: 18),
        Row(children: [Expanded(child: Text('Set time', style: Theme.of(context).textTheme.titleLarge)), TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), const SizedBox(width: 4), FilledButton(onPressed: () => Navigator.pop(context, TimeOfDay(hour: _hour, minute: _minute)), child: const Text('Done'))]),
        const SizedBox(height: 18),
        SizedBox(height: 218, child: Stack(alignment: Alignment.center, children: [
          IgnorePointer(child: Center(child: Container(height: 64, margin: const EdgeInsets.symmetric(horizontal: 4), decoration: BoxDecoration(color: scheme.primary.withValues(alpha: .06), borderRadius: BorderRadius.circular(16), border: Border.symmetric(horizontal: BorderSide(color: scheme.primary.withValues(alpha: .12))))))),
          Row(children: [Expanded(child: _wheel(controller: _hourController, count: 24, selected: _hour, onChanged: (v) => setState(() => _hour = v))), SizedBox(width: 24, child: Center(child: Text(':', style: Theme.of(context).textTheme.headlineSmall))), Expanded(child: _wheel(controller: _minuteController, count: 60, selected: _minute, onChanged: (v) => setState(() => _minute = v)))])
        ])),
      ]),
    );
  }
  Widget _wheel({required FixedExtentScrollController controller, required int count, required int selected, required ValueChanged<int> onChanged}) => ListWheelScrollView.useDelegate(controller: controller, itemExtent: 76, diameterRatio: 1.9, perspective: .003, physics: const FixedExtentScrollPhysics(), onSelectedItemChanged: onChanged, childDelegate: ListWheelChildBuilderDelegate(childCount: count, builder: (context, index) { final distance = (index - selected).abs(); final opacity = distance == 0 ? 1.0 : distance == 1 ? .38 : .12; return Center(child: Opacity(opacity: opacity, child: Text(_twoDigits(index), style: Theme.of(context).textTheme.displaySmall?.copyWith(fontSize: 48, fontWeight: FontWeight.w300)))); }));
}
