import 'package:flutter/material.dart';

import '../application/task_store.dart';
import '../domain/task.dart';
import 'add_task_page.dart';

class TaskDetailPage extends StatelessWidget {
  const TaskDetailPage({super.key, required this.store, required this.task});

  final TaskStore store;
  final Task task;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final current = store.tasks.where((value) => value.id == task.id).firstWhere((_) => true, orElse: () => task);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task details'),
        actions: [
          IconButton(
            tooltip: 'Edit task',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => AddTaskPage(store: store, task: current))),
          ),
          IconButton(tooltip: 'Delete task', icon: const Icon(Icons.delete_outline), onPressed: () => _delete(context, current)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(value: current.isCompleted, onChanged: (_) => store.toggleCompleted(current.id)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(current.title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, decoration: current.isCompleted ? TextDecoration.lineThrough : null))),
                ],
              ),
            ),
          ),
          if (current.notes.isNotEmpty) ...[
            const SizedBox(height: 12),
            _InfoCard(icon: Icons.notes_outlined, title: 'Notes', child: Text(current.notes, style: Theme.of(context).textTheme.bodyLarge)),
          ],
          const SizedBox(height: 12),
          _InfoCard(icon: Icons.schedule_outlined, title: 'Schedule', child: Text(current.dueAt == null ? 'No due date' : _formatDateTime(context, current.dueAt!), style: Theme.of(context).textTheme.bodyLarge)),
          const SizedBox(height: 12),
          _InfoCard(icon: Icons.notifications_outlined, title: 'Reminder', child: Text(
            current.reminderType == TaskReminderType.none ? 'No reminder' : current.reminderType == TaskReminderType.once ? 'Remind once' : 'Every ${_formatDuration(current.reminderInterval)}',
            style: Theme.of(context).textTheme.bodyLarge,
          )),
          const SizedBox(height: 12),
          _InfoCard(icon: Icons.flag_outlined, title: 'Priority', child: Text(_priorityLabel(current.priority), style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700, color: current.priority == TaskPriority.high ? scheme.error : null))),
          const SizedBox(height: 28),
          FilledButton.icon(onPressed: () => store.toggleCompleted(current.id), icon: Icon(current.isCompleted ? Icons.undo : Icons.check), label: Text(current.isCompleted ? 'Mark active' : 'Mark completed')),
        ],
      ),
    );
  }

  Future<void> _delete(BuildContext context, Task current) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete task?'),
        content: Text('Delete “${current.title}”? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          FilledButton.tonal(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await store.deleteTask(current.id);
      if (context.mounted) Navigator.pop(context);
    }
  }

  String _formatDateTime(BuildContext context, DateTime value) => '${value.day}/${value.month}/${value.year} at ${TimeOfDay.fromDateTime(value).format(context)}';

  String _formatDuration(Duration? value) {
    if (value == null) return 'Not configured';
    if (value.inHours >= 1 && value.inMinutes % 60 == 0) return '${value.inHours} hour${value.inHours == 1 ? '' : 's'}';
    return '${value.inMinutes} minutes';
  }

  String _priorityLabel(TaskPriority value) => switch (value) {
        TaskPriority.low => 'Low',
        TaskPriority.normal => 'Normal',
        TaskPriority.high => 'High',
      };
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.icon, required this.title, required this.child});

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(child: Padding(padding: const EdgeInsets.all(18), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 6), child])),
    ])));
  }
}
