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
  late final TextEditingController _categoryController;
  late final TextEditingController _tagController;
  DateTime? _dueAt;
  TaskPriority _priority = TaskPriority.normal;
  TaskReminderType _reminderType = TaskReminderType.none;
  Duration? _interval = const Duration(hours: 2);
  TaskRepeat _repeat = TaskRepeat.none;
  int _customDays = 1;
  bool _favorite = false;
  bool _saving = false;
  bool _detailed = false;
  final List<String> _tags = <String>[];

  @override
  void initState() {
    super.initState();
    final t = widget.task;
    _titleController = TextEditingController(text: t?.title ?? '');
    _notesController = TextEditingController(text: t?.notes ?? '');
    _categoryController = TextEditingController(text: t?.category ?? '');
    _tagController = TextEditingController();
    _dueAt = t?.dueAt;
    _priority = t?.priority ?? TaskPriority.normal;
    _reminderType = t?.reminderType ?? TaskReminderType.none;
    _interval = t?.reminderInterval ?? const Duration(hours: 2);
    _repeat = t?.repeat ?? TaskRepeat.none;
    _customDays = t?.repeatIntervalDays ?? 1;
    _favorite = t?.isFavorite ?? false;
    _tags.addAll(t?.tags ?? const <String>[]);
    _detailed = widget.isEditing;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _categoryController.dispose();
    _tagController.dispose();
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
    final initial = _dueAt ?? DateTime(date.year, date.month, date.day, 9);
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !mounted) return;
    final value = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    if (value.isBefore(now)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose a future time.')),
      );
      return;
    }
    setState(() {
      _dueAt = value;
      if (_reminderType == TaskReminderType.none) {
        _reminderType = TaskReminderType.once;
      }
    });
  }

  void _quick(Duration duration) {
    final value = DateTime.now().add(duration);
    setState(() {
      _dueAt = DateTime(value.year, value.month, value.day, value.hour, value.minute);
      if (_reminderType == TaskReminderType.none) {
        _reminderType = TaskReminderType.once;
      }
    });
  }

  void _tomorrow() {
    final value = DateTime.now().add(const Duration(days: 1));
    setState(() {
      _dueAt = DateTime(value.year, value.month, value.day, 9);
      if (_reminderType == TaskReminderType.none) {
        _reminderType = TaskReminderType.once;
      }
    });
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isEmpty || _tags.contains(tag)) return;
    setState(() => _tags.add(tag));
    _tagController.clear();
  }

  Future<void> _save() async {
    if (_saving) return;
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Give your task a name first.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final category = _categoryController.text.trim();
      if (widget.task == null) {
        await widget.store.addTask(
          title: title,
          notes: _notesController.text,
          dueAt: _dueAt,
          reminderType: _reminderType,
          reminderInterval: _reminderType == TaskReminderType.interval ? _interval : null,
          priority: _priority,
          repeat: _repeat,
          repeatIntervalDays: _repeat == TaskRepeat.custom ? _customDays : null,
          isFavorite: _favorite,
          category: category,
          tags: _tags,
        );
      } else {
        await widget.store.updateTask(
          widget.task!.id,
          title: title,
          notes: _notesController.text,
          dueAt: _dueAt,
          reminderType: _reminderType,
          reminderInterval: _reminderType == TaskReminderType.interval ? _interval : null,
          priority: _priority,
          repeat: _repeat,
          repeatIntervalDays: _repeat == TaskRepeat.custom ? _customDays : null,
          isFavorite: _favorite,
          category: category,
          tags: _tags,
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save the task. Try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_detailed && !widget.isEditing) return _buildCreateChoice(context);
    return _buildDetailed(context);
  }

  Widget _buildCreateChoice(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create task'),
        centerTitle: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 36),
          children: [
            Text(
              'How do you want to add it?',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'Capture something instantly, or give it the full treatment.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 28),
            _ModeCard(
              icon: Icons.bolt_rounded,
              title: 'Quick Capture',
              description: 'Type one thing and get it out of your head.',
              badge: 'FASTEST',
              onTap: () => setState(() => _detailed = false),
              autofocus: true,
              controller: _titleController,
              onSave: _save,
              scheme: scheme,
            ),
            const SizedBox(height: 14),
            _ModeCard(
              icon: Icons.auto_awesome_rounded,
              title: 'Detailed Task',
              description: 'Notes, schedule, reminders, repeats, priority, tags and more.',
              badge: 'POWERFUL',
              onTap: () => setState(() => _detailed = true),
              scheme: scheme,
            ),
            const SizedBox(height: 26),
            Center(
              child: TextButton.icon(
                onPressed: () => setState(() => _detailed = true),
                icon: const Icon(Icons.tune_rounded),
                label: const Text('Open full task editor'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailed(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final children = <Widget>[
      _SectionLabel(icon: Icons.edit_note_rounded, title: 'Task'),
      _PremiumField(
        controller: _titleController,
        autofocus: !widget.isEditing,
        hintText: 'What needs to be done?',
        prefixIcon: Icons.check_circle_outline_rounded,
      ),
      const SizedBox(height: 12),
      _PremiumField(
        controller: _notesController,
        hintText: 'Add notes or context…',
        prefixIcon: Icons.notes_rounded,
        minLines: 3,
        maxLines: 6,
      ),
      const SizedBox(height: 26),
      _SectionLabel(icon: Icons.schedule_rounded, title: 'Schedule'),
      _QuickScheduleRow(on15: () => _quick(const Duration(minutes: 15)), onHour: () => _quick(const Duration(hours: 1)), onTomorrow: _tomorrow),
      const SizedBox(height: 10),
      _SettingTile(
        icon: Icons.event_rounded,
        title: _dueAt == null ? 'Set date & time' : '${_dueAt!.day}/${_dueAt!.month}/${_dueAt!.year} at ${TimeOfDay.fromDateTime(_dueAt!).format(context)}',
        subtitle: _dueAt == null ? 'Choose when this task is due' : 'Scheduled',
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: _pickDateTime,
      ),
      const SizedBox(height: 22),
      _SectionLabel(icon: Icons.notifications_active_rounded, title: 'Reminders'),
      _PremiumDropdown<TaskReminderType>(
        value: _reminderType,
        items: const [
          DropdownMenuItem(value: TaskReminderType.none, child: Text('No reminder')),
          DropdownMenuItem(value: TaskReminderType.once, child: Text('Remind once')),
          DropdownMenuItem(value: TaskReminderType.interval, child: Text('Repeat reminder')),
        ],
        onChanged: (v) => setState(() => _reminderType = v ?? TaskReminderType.none),
      ),
    ];

    if (_reminderType == TaskReminderType.interval) {
      children.addAll([
        const SizedBox(height: 10),
        _PremiumDropdown<Duration>(
          value: _interval,
          items: const [
            DropdownMenuItem(value: Duration(minutes: 30), child: Text('Every 30 minutes')),
            DropdownMenuItem(value: Duration(hours: 1), child: Text('Every hour')),
            DropdownMenuItem(value: Duration(hours: 2), child: Text('Every 2 hours')),
            DropdownMenuItem(value: Duration(hours: 4), child: Text('Every 4 hours')),
          ],
          onChanged: (v) => setState(() => _interval = v),
        ),
      ]);
    }

    children.addAll([
      const SizedBox(height: 22),
      _SectionLabel(icon: Icons.repeat_rounded, title: 'Repeat'),
      _PremiumDropdown<TaskRepeat>(
        value: _repeat,
        items: const [
          DropdownMenuItem(value: TaskRepeat.none, child: Text('Does not repeat')),
          DropdownMenuItem(value: TaskRepeat.daily, child: Text('Daily')),
          DropdownMenuItem(value: TaskRepeat.weekdays, child: Text('Weekdays')),
          DropdownMenuItem(value: TaskRepeat.weekly, child: Text('Weekly')),
          DropdownMenuItem(value: TaskRepeat.monthly, child: Text('Monthly')),
          DropdownMenuItem(value: TaskRepeat.custom, child: Text('Custom')),
        ],
        onChanged: (v) => setState(() => _repeat = v ?? TaskRepeat.none),
      ),
    ]);

    if (_repeat == TaskRepeat.custom) {
      children.addAll([
        const SizedBox(height: 10),
        _PremiumField(
          initialValue: '$_customDays',
          keyboardType: TextInputType.number,
          hintText: 'Repeat every N days',
          prefixIcon: Icons.calendar_view_day_rounded,
          onChanged: (v) => _customDays = int.tryParse(v) ?? 1,
        ),
      ]);
    }

    children.addAll([
      const SizedBox(height: 22),
      _SectionLabel(icon: Icons.flag_rounded, title: 'Priority'),
      _PrioritySelector(value: _priority, onChanged: (v) => setState(() => _priority = v)),
      const SizedBox(height: 10),
      Card(
        elevation: 0,
        child: SwitchListTile.adaptive(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          title: const Text('Favorite', style: TextStyle(fontWeight: FontWeight.w700)),
          subtitle: const Text('Keep this task easy to find'),
          secondary: Icon(_favorite ? Icons.star_rounded : Icons.star_border_rounded, color: _favorite ? scheme.primary : null),
          value: _favorite,
          onChanged: (v) => setState(() => _favorite = v),
        ),
      ),
      const SizedBox(height: 22),
      _SectionLabel(icon: Icons.folder_rounded, title: 'Organization'),
      _PremiumField(
        controller: _categoryController,
        hintText: 'Category or list',
        prefixIcon: Icons.folder_open_rounded,
      ),
      const SizedBox(height: 10),
      _PremiumField(
        controller: _tagController,
        hintText: 'Add a tag and press enter',
        prefixIcon: Icons.sell_rounded,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _addTag(),
      ),
    ]);

    if (_tags.isNotEmpty) {
      children.add(Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _tags.map((tag) => InputChip(
            avatar: const Icon(Icons.tag_rounded, size: 16),
            label: Text(tag),
            onDeleted: () => setState(() => _tags.remove(tag)),
          )).toList(),
        ),
      ));
    }

    children.addAll([
      const SizedBox(height: 28),
      FilledButton.icon(
        onPressed: _saving ? null : _save,
        icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.check_rounded),
        label: Padding(
          padding: const EdgeInsets.symmetric(vertical: 15),
          child: Text(_saving ? 'Saving…' : widget.isEditing ? 'Save changes' : 'Create task'),
        ),
      ),
    ]);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit task' : 'Detailed task'),
        actions: [
          if (!widget.isEditing)
            TextButton(onPressed: () => setState(() => _detailed = false), child: const Text('Quick Capture')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 42),
        children: children,
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({required this.icon, required this.title, required this.description, required this.badge, required this.onTap, required this.scheme, this.autofocus = false, this.controller, this.onSave});
  final IconData icon;
  final String title;
  final String description;
  final String badge;
  final VoidCallback onTap;
  final ColorScheme scheme;
  final bool autofocus;
  final TextEditingController? controller;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: BorderRadius.circular(14)),
                  child: Icon(icon, color: scheme.primary),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 3),
                  Text(description, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
                ])),
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5), decoration: BoxDecoration(color: scheme.secondaryContainer, borderRadius: BorderRadius.circular(99)), child: Text(badge, style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w800, color: scheme.onSecondaryContainer))),
              ]),
              if (controller != null) ...[
                const SizedBox(height: 18),
                TextField(
                  controller: controller,
                  autofocus: autofocus,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => onSave?.call(),
                  decoration: InputDecoration(hintText: 'What needs to be done?', suffixIcon: IconButton(onPressed: onSave, icon: const Icon(Icons.arrow_forward_rounded))),
                ),
              ] else ...[
                const SizedBox(height: 16),
                Align(alignment: Alignment.centerRight, child: FilledButton.tonalIcon(onPressed: onTap, icon: const Icon(Icons.arrow_forward_rounded), label: const Text('Use detailed'))),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.icon, required this.title});
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 2),
      child: Row(children: [
        Icon(icon, size: 19, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
      ]),
    );
  }
}

class _PremiumField extends StatelessWidget {
  const _PremiumField({this.controller, this.initialValue, required this.hintText, required this.prefixIcon, this.minLines = 1, this.maxLines = 1, this.autofocus = false, this.keyboardType, this.textInputAction, this.onChanged, this.onSubmitted});
  final TextEditingController? controller;
  final String? initialValue;
  final String hintText;
  final IconData prefixIcon;
  final int minLines;
  final int maxLines;
  final bool autofocus;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      minLines: minLines,
      maxLines: maxLines,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(hintText: hintText, prefixIcon: Icon(prefixIcon)),
    );
  }
}

class _PremiumDropdown<T> extends StatelessWidget {
  const _PremiumDropdown({required this.value, required this.items, required this.onChanged});
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      items: items,
      onChanged: onChanged,
      decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
    );
  }
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({required this.icon, required this.title, required this.subtitle, required this.trailing, required this.onTap});
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        trailing: trailing,
      ),
    );
  }
}

class _QuickScheduleRow extends StatelessWidget {
  const _QuickScheduleRow({required this.on15, required this.onHour, required this.onTomorrow});
  final VoidCallback on15;
  final VoidCallback onHour;
  final VoidCallback onTomorrow;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(child: OutlinedButton.icon(onPressed: on15, icon: const Icon(Icons.timer_outlined, size: 18), label: const Text('15 min'))),
      const SizedBox(width: 8),
      Expanded(child: OutlinedButton.icon(onPressed: onHour, icon: const Icon(Icons.schedule_outlined, size: 18), label: const Text('1 hour'))),
      const SizedBox(width: 8),
      Expanded(child: OutlinedButton.icon(onPressed: onTomorrow, icon: const Icon(Icons.wb_sunny_outlined, size: 18), label: const Text('Tomorrow'))),
    ]);
  }
}

class _PrioritySelector extends StatelessWidget {
  const _PrioritySelector({required this.value, required this.onChanged});
  final TaskPriority value;
  final ValueChanged<TaskPriority> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<TaskPriority>(
      segments: const [
        ButtonSegment(value: TaskPriority.low, label: Text('Low'), icon: Icon(Icons.arrow_downward_rounded, size: 17)),
        ButtonSegment(value: TaskPriority.normal, label: Text('Normal')),
        ButtonSegment(value: TaskPriority.high, label: Text('High'), icon: Icon(Icons.priority_high_rounded, size: 17)),
      ],
      selected: {value},
      onSelectionChanged: (selection) => onChanged(selection.first),
    );
  }
}
