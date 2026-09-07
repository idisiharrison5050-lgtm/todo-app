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
          bool saving = false;

          Future<void> save() async {
            if (saving) return;
            final title = controller.text.trim();
            if (title.isEmpty) return;
            setState(() => saving = true);
            try {
              await store.addTask(title: title, dueAt: dueAt, reminderType: reminder ? TaskReminderType.once : TaskReminderType.none, priority: priority);
              if (context.mounted) Navigator.pop(context);
            } catch (error) {
              if (context.mounted) {
                setState(() => saving = false);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error is ArgumentError ? error.message.toString() : 'Could not add this task. Please try again.')));
              }
            }
          }

          void setDue(Duration duration) => setState(() => dueAt = DateTime.now().add(duration));

          void setTomorrow() {
            final n = DateTime.now().add(const Duration(days: 1));
            setState(() => dueAt = DateTime(n.year, n.month, n.day, 9));
          }

          final tomorrow = DateTime.now().add(const Duration(days: 1));
          final tomorrowAtNine = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 9);
          final tomorrowSelected = dueAt != null && dueAt!.difference(tomorrowAtNine).inSeconds.abs() <= 4;

          return SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 4, 20, MediaQuery.viewInsetsOf(context).bottom + 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Quick capture', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)), const SizedBox(height: 5), Text('Capture the task now. Add the fine details later.', style: Theme.of(context).textTheme.bodyMedium)])),
                    Icon(Icons.bolt_rounded, color: Theme.of(context).colorScheme.primary),
                  ]),
                  const SizedBox(height: 18),
                  TextField(controller: controller, autofocus: true, enabled: !saving, textCapitalization: TextCapitalization.sentences, textInputAction: TextInputAction.done, onSubmitted: (_) => save(), decoration: const InputDecoration(hintText: 'What needs to get done?', prefixIcon: Icon(Icons.bolt_rounded))),
                  const SizedBox(height: 13),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(children: [
                      _QuickChip(label: 'In 15 min', onTap: () => setDue(const Duration(minutes: 15)), selected: _isApprox(dueAt, const Duration(minutes: 15))),
                      _QuickChip(label: 'In 1 hour', onTap: () => setDue(const Duration(hours: 1)), selected: _isApprox(dueAt, const Duration(hours: 1))),
                      _QuickChip(label: 'Tomorrow 9 AM', onTap: setTomorrow, selected: tomorrowSelected),
                    ]),
                  ),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: ChoiceChip(label: const Text('Normal'), selected: priority == TaskPriority.normal, onSelected: saving ? null : (_) => setState(() => priority = TaskPriority.normal))),
                    const SizedBox(width: 8),
                    Expanded(child: ChoiceChip(label: const Text('High'), selected: priority == TaskPriority.high, onSelected: saving ? null : (_) => setState(() => priority = TaskPriority.high))),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(tooltip: reminder ? 'Disable reminder' : 'Add reminder', onPressed: saving || dueAt == null ? null : () => setState(() => reminder = !reminder), icon: Icon(reminder ? Icons.notifications_active_rounded : Icons.notifications_none_rounded)),
                  ]),
                  if (dueAt != null) ...[
                    const SizedBox(height: 8),
                    Row(children: [Icon(Icons.schedule_rounded, size: 15, color: Theme.of(context).colorScheme.primary), const SizedBox(width: 6), Expanded(child: Text('Scheduled · ${MaterialLocalizations.of(context).formatMediumDate(dueAt!)} · ${TimeOfDay.fromDateTime(dueAt!).format(context)}', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700)))])
                  ],
                  const SizedBox(height: 15),
                  FilledButton.icon(onPressed: saving ? null : save, icon: saving ? const SizedBox(width: 19, height: 19, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.add_rounded), label: Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Text(saving ? 'Adding…' : 'Add task'))),
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
  final difference = value.difference(DateTime.now()).inSeconds;
  return (difference - target.inSeconds).abs() <= 4;
}
