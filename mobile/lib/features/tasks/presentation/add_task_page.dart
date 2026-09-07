import 'package:flutter/material.dart';
import '../application/task_store.dart';
import '../domain/task.dart';

class AddTaskPage extends StatefulWidget {
  const AddTaskPage({super.key, required this.store, this.task, this.initialDueAt});
  final TaskStore store;
  final Task? task;
  final DateTime? initialDueAt;
  bool get isEditing => task != null;
  @override State<AddTaskPage> createState() => _AddTaskPageState();
}

class _AddTaskPageState extends State<AddTaskPage> {
  late final TextEditingController _title, _notes, _category, _tag, _customDays;
  DateTime? _dueAt;
  TaskPriority _priority = TaskPriority.normal;
  TaskReminderType _reminder = TaskReminderType.none;
  Duration? _interval = const Duration(hours: 2);
  TaskRepeat _repeat = TaskRepeat.none;
  bool _favorite = false, _advanced = false, _saving = false;
  final List<String> _tags = [];

  @override void initState() {
    super.initState();
    final task = widget.task;
    _title = TextEditingController(text: task?.title ?? '');
    _notes = TextEditingController(text: task?.notes ?? '');
    _category = TextEditingController(text: task?.category ?? '');
    _tag = TextEditingController();
    _customDays = TextEditingController(text: '${task?.repeatIntervalDays ?? 1}');
    _dueAt = task?.dueAt ?? widget.initialDueAt;
    _priority = task?.priority ?? TaskPriority.normal;
    _reminder = task?.reminderType ?? (widget.initialDueAt == null ? TaskReminderType.none : TaskReminderType.once);
    _interval = task?.reminderInterval ?? const Duration(hours: 2);
    _repeat = task?.repeat ?? TaskRepeat.none;
    _favorite = task?.isFavorite ?? false;
    _tags.addAll(task?.tags ?? const <String>[]);
    _advanced = widget.isEditing && (_priority != TaskPriority.normal || _repeat != TaskRepeat.none || _tags.isNotEmpty || _category.text.isNotEmpty);
  }

  @override void dispose() { _title.dispose(); _notes.dispose(); _category.dispose(); _tag.dispose(); _customDays.dispose(); super.dispose(); }

  void _setDue(DateTime value) {
    if (value.isBefore(DateTime.now())) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Choose a future time.'))); return; }
    setState(() { _dueAt = value; if (_reminder == TaskReminderType.none) _reminder = TaskReminderType.once; });
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(context: context, firstDate: DateTime(now.year, now.month, now.day), lastDate: DateTime(now.year + 5), initialDate: _dueAt ?? now);
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_dueAt ?? now));
    if (time == null || !mounted) return;
    _setDue(DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  Future<void> _save() async {
    if (_saving) return;
    final title = _title.text.trim();
    if (title.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Give your task a name first.'))); return; }
    final customDays = int.tryParse(_customDays.text.trim()) ?? 1;
    if (_repeat == TaskRepeat.custom && (customDays < 1 || customDays > 365)) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Custom repeat must be between 1 and 365 days.'))); return; }
    setState(() => _saving = true);
    try {
      final repeatDays = _repeat == TaskRepeat.custom ? customDays : null;
      final reminderInterval = _reminder == TaskReminderType.interval ? _interval : null;
      if (widget.task == null) {
        await widget.store.addTask(title: title, notes: _notes.text.trim(), dueAt: _dueAt, reminderType: _reminder, reminderInterval: reminderInterval, priority: _priority, repeat: _repeat, repeatIntervalDays: repeatDays, isFavorite: _favorite, category: _category.text.trim(), tags: List<String>.from(_tags));
      } else {
        await widget.store.updateTask(widget.task!.id, title: title, notes: _notes.text.trim(), dueAt: _dueAt, reminderType: _reminder, reminderInterval: reminderInterval, priority: _priority, repeat: _repeat, repeatIntervalDays: repeatDays, isFavorite: _favorite, category: _category.text.trim(), tags: List<String>.from(_tags));
      }
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error is ArgumentError ? error.message.toString() : 'Could not save the task. Try again.')));
    }
  }

  void _addTag() {
    final value = _tag.text.trim().replaceAll(RegExp(r'^#+'), '');
    if (value.isEmpty || _tags.contains(value)) return;
    setState(() => _tags.add(value));
    _tag.clear();
  }

  String _scheduleLabel(BuildContext context) => _dueAt == null ? 'No date or time' : '${MaterialLocalizations.of(context).formatMediumDate(_dueAt!)} · ${TimeOfDay.fromDateTime(_dueAt!).format(context)}';

  @override Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(widget.isEditing ? 'Edit task' : 'New task'), actions: [TextButton(onPressed: _saving ? null : _save, child: const Text('Save'))]),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
        children: [
          Text(widget.isEditing ? 'Make it better.' : 'What are you getting done?', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text(widget.isEditing ? 'Update the details and keep your plan moving.' : 'Capture it now. Organize the details when you need them.', style: theme.textTheme.bodyMedium),
          const SizedBox(height: 24),

          // FAST CAPTURE: the short version stays visible for quick entry.
          _Card(child: Column(children: [
            TextField(controller: _title, autofocus: !widget.isEditing, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(hintText: 'Task name', prefixIcon: Icon(Icons.check_circle_outline))),
            const SizedBox(height: 12),
            TextField(controller: _notes, minLines: 2, maxLines: 5, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(hintText: 'Add a note (optional)', prefixIcon: Icon(Icons.notes_outlined))),
          ])),
          const SizedBox(height: 20),

          _Heading(icon: Icons.schedule_rounded, title: 'When', subtitle: 'Set a moment or leave it open-ended.'),
          const SizedBox(height: 10),
          _Card(child: Column(children: [
            Wrap(spacing: 8, runSpacing: 8, children: [
              _Chip(label: '15 min', onTap: () => _setDue(DateTime.now().add(const Duration(minutes: 15)))),
              _Chip(label: '1 hour', onTap: () => _setDue(DateTime.now().add(const Duration(hours: 1)))),
              _Chip(label: 'Tomorrow', onTap: () { final n = DateTime.now().add(const Duration(days: 1)); _setDue(DateTime(n.year, n.month, n.day, 9)); }),
              _Chip(label: 'Pick date', onTap: _pickDateTime),
            ]),
            const SizedBox(height: 10),
            ListTile(contentPadding: EdgeInsets.zero, leading: CircleAvatar(backgroundColor: scheme.primary.withValues(alpha: .1), foregroundColor: scheme.primary, child: const Icon(Icons.event_available_outlined)), title: Text(_scheduleLabel(context), style: const TextStyle(fontWeight: FontWeight.w700)), subtitle: Text(_dueAt == null ? 'Tap to schedule' : 'Tap to change'), trailing: _dueAt == null ? const Icon(Icons.chevron_right_rounded) : IconButton(onPressed: () => setState(() { _dueAt = null; _reminder = TaskReminderType.none; }), icon: const Icon(Icons.close_rounded)), onTap: _pickDateTime),
          ])),
          const SizedBox(height: 20),

          _Heading(icon: Icons.notifications_active_outlined, title: 'Reminder', subtitle: 'Never rely on memory alone.'),
          const SizedBox(height: 10),
          _Card(child: Column(children: [
            _Choice(title: 'No reminder', selected: _reminder == TaskReminderType.none, onTap: () => setState(() => _reminder = TaskReminderType.none)),
            _Choice(title: 'Remind once', selected: _reminder == TaskReminderType.once, onTap: () => setState(() => _reminder = TaskReminderType.once)),
            _Choice(title: 'Keep reminding me', selected: _reminder == TaskReminderType.interval, onTap: () => setState(() => _reminder = TaskReminderType.interval)),
            if (_reminder == TaskReminderType.interval) ...[
              const Divider(height: 20),
              DropdownButtonFormField<Duration>(initialValue: _interval, decoration: const InputDecoration(labelText: 'Reminder frequency'), items: const [DropdownMenuItem(value: Duration(minutes: 30), child: Text('Every 30 minutes')), DropdownMenuItem(value: Duration(hours: 1), child: Text('Every hour')), DropdownMenuItem(value: Duration(hours: 2), child: Text('Every 2 hours')), DropdownMenuItem(value: Duration(hours: 4), child: Text('Every 4 hours'))], onChanged: (value) => setState(() => _interval = value)),
            ],
          ])),
          const SizedBox(height: 20),

          // FULL EDITOR: restored as an explicit Show more section rather than
          // forcing every user through the long form.
          _Card(child: Column(children: [
            InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => setState(() => _advanced = !_advanced),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(children: [
                  Container(width: 42, height: 42, decoration: BoxDecoration(color: scheme.primary.withValues(alpha: .10), borderRadius: BorderRadius.circular(14)), child: Icon(Icons.tune_rounded, color: scheme.primary)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_advanced ? 'Hide more options' : 'Show more options', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 2),
                    Text(_advanced ? 'Collapse the full task editor.' : 'Priority, repeat, category, tags and favorite.', style: theme.textTheme.bodySmall),
                  ])),
                  Icon(_advanced ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded),
                ]),
              ),
            ),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 220),
              crossFadeState: _advanced ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              firstChild: const SizedBox(width: double.infinity, height: 0),
              secondChild: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Divider(height: 28),
                Text('Priority', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                SegmentedButton<TaskPriority>(segments: const [ButtonSegment(value: TaskPriority.low, label: Text('Low')), ButtonSegment(value: TaskPriority.normal, label: Text('Normal')), ButtonSegment(value: TaskPriority.high, label: Text('High'))], selected: {_priority}, onSelectionChanged: (value) => setState(() => _priority = value.first)),
                const SizedBox(height: 16),
                DropdownButtonFormField<TaskRepeat>(initialValue: _repeat, decoration: const InputDecoration(labelText: 'Repeat task', prefixIcon: Icon(Icons.repeat_rounded)), items: const [DropdownMenuItem(value: TaskRepeat.none, child: Text('Does not repeat')), DropdownMenuItem(value: TaskRepeat.daily, child: Text('Every day')), DropdownMenuItem(value: TaskRepeat.weekdays, child: Text('Weekdays')), DropdownMenuItem(value: TaskRepeat.weekly, child: Text('Every week')), DropdownMenuItem(value: TaskRepeat.monthly, child: Text('Every month')), DropdownMenuItem(value: TaskRepeat.custom, child: Text('Custom interval'))], onChanged: (value) => setState(() => _repeat = value ?? TaskRepeat.none)),
                if (_repeat == TaskRepeat.custom) ...[const SizedBox(height: 10), TextField(controller: _customDays, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Repeat every N days', prefixIcon: Icon(Icons.timelapse_rounded)))],
                const SizedBox(height: 12),
                TextField(controller: _category, decoration: const InputDecoration(labelText: 'List / category', prefixIcon: Icon(Icons.folder_outlined))),
                const SizedBox(height: 12),
                TextField(controller: _tag, onSubmitted: (_) => _addTag(), decoration: const InputDecoration(labelText: 'Add tag', prefixIcon: Icon(Icons.tag_rounded))),
                if (_tags.isNotEmpty) ...[const SizedBox(height: 10), Wrap(spacing: 6, runSpacing: 6, children: _tags.map<Widget>((tag) => InputChip(label: Text(tag), onDeleted: () => setState(() => _tags.remove(tag)))).toList())],
                SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Favorite', style: TextStyle(fontWeight: FontWeight.w700)), value: _favorite, onChanged: (value) => setState(() => _favorite = value)),
              ]),
            ),
          ])),

          if (_dueAt != null) ...[const SizedBox(height: 18), Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: scheme.primary.withValues(alpha: .07), borderRadius: BorderRadius.circular(18)), child: Row(children: [Icon(Icons.auto_awesome_rounded, color: scheme.primary), const SizedBox(width: 10), Expanded(child: Text('Scheduled for ${_scheduleLabel(context)}', style: const TextStyle(fontWeight: FontWeight.w700)))]))],
        ],
      ),
      bottomNavigationBar: SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(20, 8, 20, 12), child: FilledButton.icon(onPressed: _saving ? null : _save, icon: _saving ? const SizedBox(width: 19, height: 19, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.check_rounded), label: Text(widget.isEditing ? 'Save changes' : 'Create task')))),
    );
  }
}

class _Card extends StatelessWidget { const _Card({required this.child}); final Widget child; @override Widget build(BuildContext context) { final scheme = Theme.of(context).colorScheme; return Container(padding: const EdgeInsets.all(17), decoration: BoxDecoration(color: scheme.surfaceContainerHigh, borderRadius: BorderRadius.circular(24), border: Border.all(color: scheme.outlineVariant.withValues(alpha: .7))), child: child); } }
class _Heading extends StatelessWidget { const _Heading({required this.icon, required this.title, required this.subtitle}); final IconData icon; final String title, subtitle; @override Widget build(BuildContext context) { final scheme = Theme.of(context).colorScheme; return Row(children: [Icon(icon, size: 20, color: scheme.primary), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)), Text(subtitle, style: Theme.of(context).textTheme.bodySmall)]))]); } }
class _Chip extends StatelessWidget { const _Chip({required this.label, required this.onTap}); final String label; final VoidCallback onTap; @override Widget build(BuildContext context) => ActionChip(label: Text(label), onPressed: onTap); }
class _Choice extends StatelessWidget { const _Choice({required this.title, required this.selected, required this.onTap}); final String title; final bool selected; final VoidCallback onTap; @override Widget build(BuildContext context) { final scheme = Theme.of(context).colorScheme; return ListTile(contentPadding: EdgeInsets.zero, onTap: onTap, leading: Icon(selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded, color: selected ? scheme.primary : scheme.onSurfaceVariant), title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700))); } }
