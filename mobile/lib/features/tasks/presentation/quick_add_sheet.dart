import 'package:flutter/material.dart';
import '../application/task_store.dart';
import '../domain/task.dart';

Future<void> showQuickAddTask(BuildContext context, TaskStore store) async {
  final controller = TextEditingController();
  DateTime? dueAt;
  TaskPriority priority = TaskPriority.normal;
  bool reminder = false;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          Future<void> save() async {
            final title = controller.text.trim();
            if (title.isEmpty) return;
            await store.addTask(
              title: title,
              dueAt: dueAt,
              reminderType: reminder ? TaskReminderType.once : TaskReminderType.none,
              priority: priority,
            );
            if (context.mounted) Navigator.pop(context);
          }

          void setDue(Duration duration) {
            setState(() => dueAt = DateTime.now().add(duration));
          }

          return SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 4, 20, MediaQuery.viewInsetsOf(context).bottom + 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Quick capture', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 5),
                  Text('Capture the task now. Add the fine details later.', style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 18),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => save(),
                    decoration: const InputDecoration(hintText: 'What needs to get done?', prefixIcon: Icon(Icons.bolt_rounded)),
                  ),
                  const SizedBox(height: 13),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(children: [
                      _QuickChip(label: 'In 15 min', onTap: () => setDue(const Duration(minutes: 15)), selected: _isApprox(dueAt, const Duration(minutes: 15))),
                      _QuickChip(label: 'In 1 hour', onTap: () => setDue(const Duration(hours: 1)), selected: _isApprox(dueAt, const Duration(hours: 1))),
                      _QuickChip(label: 'Tomorrow 9 AM', onTap: () { final n = DateTime.now().add(const Duration(days: 1)); setState(() => dueAt = DateTime(n.year, n.month, n.day, 9)); }, selected: false),
                    ]),
                  ),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: ChoiceChip(label: const Text('Normal'), selected: priority == TaskPriority.normal, onSelected: (_) => setState(() => priority = TaskPriority.normal))),
                    const SizedBox(width: 8),
                    Expanded(child: ChoiceChip(label: const Text('High'), selected: priority == TaskPriority.high, onSelected: (_) => setState(() => priority = TaskPriority.high))),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(tooltip: reminder ? 'Disable reminder' : 'Add reminder', onPressed: dueAt == null ? null : () => setState(() => reminder = !reminder), icon: Icon(reminder ? Icons.notifications_active_rounded : Icons.notifications_none_rounded)),
                  ]),
                  if (dueAt != null) ...[
                    const SizedBox(height: 8),
                    Text('Scheduled · ${MaterialLocalizations.of(context).formatMediumDate(dueAt!)} · ${TimeOfDay.fromDateTime(dueAt!).format(context)}', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700)),
                  ],
                  const SizedBox(height: 15),
                  FilledButton.icon(onPressed: save, icon: const Icon(Icons.add_rounded), label: const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Text('Add task'))),
                ],
              ),
            ),
          );
        },
      );
    },
  );
  controller.dispose();
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
        avatar: selected ? Icon(Icons.check_rounded, size: 16, color: scheme.primary) : null,
        label: Text(label),
        onPressed: onTap,
      ),
    );
  }
}

bool _isApprox(DateTime? value, Duration target) {
  if (value == null) return false;
  return value.difference(DateTime.now()).inSeconds.abs() <= 4 &&
      (value.difference(DateTime.now()).inSeconds - target.inSeconds).abs() <= 4;
}
