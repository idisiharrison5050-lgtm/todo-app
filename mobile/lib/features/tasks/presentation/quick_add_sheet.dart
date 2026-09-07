import 'package:flutter/material.dart';
import '../application/task_store.dart';
import '../domain/task.dart';

Future<void> showQuickAddTask(BuildContext context, TaskStore store) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _QuickAddSheet(store: store),
  );
}

class _QuickAddSheet extends StatefulWidget {
  const _QuickAddSheet({required this.store});
  final TaskStore store;

  @override
  State<_QuickAddSheet> createState() => _QuickAddSheetState();
}

class _QuickAddSheetState extends State<_QuickAddSheet> {
  late final TextEditingController _controller;
  DateTime? _dueAt;
  TaskPriority _priority = TaskPriority.normal;
  bool _reminder = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _setDue(Duration duration) {
    setState(() => _dueAt = DateTime.now().add(duration));
  }

  void _setTomorrow() {
    final n = DateTime.now().add(const Duration(days: 1));
    setState(() => _dueAt = DateTime(n.year, n.month, n.day, 9));
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final initial = _dueAt ?? now.add(const Duration(hours: 1));
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 5),
      initialDate: initial.isBefore(DateTime(now.year, now.month, now.day))
          ? DateTime(now.year, now.month, now.day)
          : initial,
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !mounted) return;

    final picked = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    if (picked.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose a future time.')),
      );
      return;
    }
    setState(() => _dueAt = picked);
  }

  Future<void> _save() async {
    if (_saving) return;
    final title = _controller.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Give your task a name first.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await widget.store.addTask(
        title: title,
        dueAt: _dueAt,
        reminderType: _reminder ? TaskReminderType.once : TaskReminderType.none,
        priority: _priority,
      );
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is ArgumentError
                ? error.message.toString()
                : 'Could not add this task. Please try again.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final tomorrowAtNine = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 9);
    final tomorrowSelected = _dueAt != null &&
        _dueAt!.difference(tomorrowAtNine).inSeconds.abs() <= 4;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          4,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quick capture',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Capture the task now. Add the fine details later.',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.bolt_rounded, color: scheme.primary),
                ],
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _controller,
                autofocus: true,
                enabled: !_saving,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _save(),
                decoration: const InputDecoration(
                  hintText: 'What needs to get done?',
                  prefixIcon: Icon(Icons.bolt_rounded),
                ),
              ),
              const SizedBox(height: 13),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _QuickChip(
                      label: 'In 15 min',
                      onTap: () => _setDue(const Duration(minutes: 15)),
                      selected: _isApprox(_dueAt, const Duration(minutes: 15)),
                    ),
                    _QuickChip(
                      label: 'In 1 hour',
                      onTap: () => _setDue(const Duration(hours: 1)),
                      selected: _isApprox(_dueAt, const Duration(hours: 1)),
                    ),
                    _QuickChip(
                      label: 'Tomorrow 9 AM',
                      onTap: _setTomorrow,
                      selected: tomorrowSelected,
                    ),
                    _QuickChip(
                      label: 'Pick date & time',
                      onTap: _pickDateTime,
                      selected: _dueAt != null && !tomorrowSelected && !_isApprox(_dueAt, const Duration(minutes: 15)) && !_isApprox(_dueAt, const Duration(hours: 1)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Normal'),
                      selected: _priority == TaskPriority.normal,
                      onSelected: _saving
                          ? null
                          : (_) => setState(() => _priority = TaskPriority.normal),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('High'),
                      selected: _priority == TaskPriority.high,
                      onSelected: _saving
                          ? null
                          : (_) => setState(() => _priority = TaskPriority.high),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    tooltip: _reminder ? 'Disable reminder' : 'Add reminder',
                    onPressed: _saving || _dueAt == null
                        ? null
                        : () => setState(() => _reminder = !_reminder),
                    icon: Icon(
                      _reminder
                          ? Icons.notifications_active_rounded
                          : Icons.notifications_none_rounded,
                    ),
                  ),
                ],
              ),
              if (_dueAt != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: .07),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.schedule_rounded, size: 16, color: scheme.primary),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          'Scheduled · ${MaterialLocalizations.of(context).formatMediumDate(_dueAt!)} · ${TimeOfDay.fromDateTime(_dueAt!).format(context)}',
                          style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Clear date and time',
                        visualDensity: VisualDensity.compact,
                        onPressed: _saving
                            ? null
                            : () => setState(() {
                                  _dueAt = null;
                                  _reminder = false;
                                }),
                        icon: const Icon(Icons.close_rounded, size: 18),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 15),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 19,
                        height: 19,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add_rounded),
                label: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(_saving ? 'Adding…' : 'Add task'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  const _QuickChip({required this.label, required this.onTap, required this.selected});
  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        avatar: selected
            ? Icon(Icons.check_rounded, size: 16, color: scheme.primary)
            : null,
        label: Text(label),
        onPressed: onTap,
      ),
    );
  }
}

bool _isApprox(DateTime? value, Duration target) {
  if (value == null) return false;
  final difference = value.difference(DateTime.now()).inSeconds;
  return (difference - target.inSeconds).abs() <= 4;
}
