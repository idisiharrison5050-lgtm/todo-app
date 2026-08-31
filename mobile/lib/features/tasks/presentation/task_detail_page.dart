import 'package:flutter/material.dart';
import '../application/task_store.dart';
import '../domain/task.dart';
import 'add_task_page.dart';

class TaskDetailPage extends StatefulWidget {
  const TaskDetailPage({super.key, required this.store, required this.task});
  final TaskStore store;
  final Task task;
  @override State<TaskDetailPage> createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends State<TaskDetailPage> {
  final _subtaskController = TextEditingController();

  @override
  void dispose() { _subtaskController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: widget.store,
        builder: (context, _) {
          final task = widget.store.tasks.firstWhere((value) => value.id == widget.task.id, orElse: () => widget.task);
          final scheme = Theme.of(context).colorScheme;
          final completed = task.subtasks.where((item) => item.isCompleted).length;
          final progress = task.subtasks.isEmpty ? 0.0 : completed / task.subtasks.length;
          return Scaffold(
            appBar: AppBar(title: const Text('Task details'), actions: [
              IconButton(tooltip: task.isFavorite ? 'Remove favorite' : 'Add favorite', icon: Icon(task.isFavorite ? Icons.star_rounded : Icons.star_border_rounded), onPressed: () => widget.store.toggleFavorite(task.id)),
              IconButton(tooltip: 'Edit task', icon: const Icon(Icons.edit_outlined), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddTaskPage(store: widget.store, task: task)))),
              IconButton(tooltip: 'Delete task', icon: const Icon(Icons.delete_outline), onPressed: () => _delete(context, task)),
            ]),
            body: ListView(padding: const EdgeInsets.fromLTRB(20, 12, 20, 40), children: [
              Card(elevation: 0, child: Padding(padding: const EdgeInsets.all(20), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Checkbox(value: task.isCompleted, onChanged: (_) => widget.store.toggleCompleted(task.id)), const SizedBox(width: 8), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(task.title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, decoration: task.isCompleted ? TextDecoration.lineThrough : null)),
                  if (task.isFavorite) ...[const SizedBox(height: 8), Row(children: [Icon(Icons.star_rounded, size: 17, color: scheme.primary), const SizedBox(width: 5), Text('Favorite', style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w700))])],
                ])),
              ]))),
              if (task.notes.isNotEmpty) ...[const SizedBox(height: 12), _InfoCard(icon: Icons.notes_outlined, title: 'Notes', child: Text(task.notes, style: Theme.of(context).textTheme.bodyLarge))],
              const SizedBox(height: 12), _InfoCard(icon: Icons.schedule_outlined, title: 'Schedule', child: Text(task.dueAt == null ? 'No due date' : _formatDateTime(context, task.dueAt!))),
              const SizedBox(height: 12), _InfoCard(icon: Icons.notifications_outlined, title: 'Reminder', child: Text(task.reminderType == TaskReminderType.none ? 'No reminder' : task.reminderType == TaskReminderType.once ? 'Remind once' : 'Every ${_formatDuration(task.reminderInterval)}')),
              const SizedBox(height: 12), _InfoCard(icon: Icons.repeat, title: 'Repeat', child: Text(_repeatLabel(task))),
              const SizedBox(height: 12), _InfoCard(icon: Icons.flag_outlined, title: 'Priority', child: Text(_priorityLabel(task.priority), style: TextStyle(fontWeight: FontWeight.w700, color: task.priority == TaskPriority.high ? scheme.error : null))),
              if (task.category.isNotEmpty) ...[const SizedBox(height: 12), _InfoCard(icon: Icons.folder_outlined, title: 'Category', child: Text(task.category))],
              if (task.tags.isNotEmpty) ...[const SizedBox(height: 12), _InfoCard(icon: Icons.tag, title: 'Tags', child: Wrap(spacing: 6, runSpacing: 6, children: task.tags.map((tag) => Chip(label: Text(tag))).toList()))],
              const SizedBox(height: 20),
              _SectionCard(title: 'Checklist', icon: Icons.checklist_rounded, trailing: task.subtasks.isEmpty ? null : Text('$completed/${task.subtasks.length}', style: const TextStyle(fontWeight: FontWeight.w800)), child: Column(children: [
                if (task.subtasks.isNotEmpty) ...[
                  LinearProgressIndicator(value: progress, minHeight: 6, borderRadius: BorderRadius.circular(6)), const SizedBox(height: 10),
                  ...task.subtasks.map((item) => _SubtaskRow(taskId: task.id, item: item, store: widget.store)),
                  const Divider(height: 20),
                ],
                Row(children: [Expanded(child: TextField(controller: _subtaskController, textInputAction: TextInputAction.done, onSubmitted: (_) => _addSubtask(task.id), decoration: const InputDecoration(hintText: 'Add a checklist item', prefixIcon: Icon(Icons.add_task)))), const SizedBox(width: 8), IconButton.filled(tooltip: 'Add subtask', onPressed: () => _addSubtask(task.id), icon: const Icon(Icons.add))]),
              ])),
              const SizedBox(height: 20),
              _SectionCard(title: 'Activity', icon: Icons.history_rounded, trailing: Text('${task.history.length}', style: const TextStyle(fontWeight: FontWeight.w800)), child: task.history.isEmpty ? const Text('No activity recorded yet.') : Column(children: task.history.reversed.take(12).map((entry) => _HistoryRow(entry: entry)).toList())),
              const SizedBox(height: 24),
              FilledButton.icon(onPressed: () => widget.store.toggleCompleted(task.id), icon: Icon(task.isCompleted ? Icons.undo : Icons.check_rounded), label: Text(task.isCompleted ? 'Mark active' : 'Mark completed')),
            ]),
          );
        },
      );

  void _addSubtask(String taskId) { final value = _subtaskController.text.trim(); if (value.isEmpty) return; widget.store.addSubtask(taskId, value); _subtaskController.clear(); FocusManager.instance.primaryFocus?.unfocus(); }
  Future<void> _delete(BuildContext context, Task task) async { final ok = await showDialog<bool>(context: context, builder: (c) => AlertDialog(title: const Text('Delete task?'), content: Text('Delete “${task.title}”?'), actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')), FilledButton.tonal(onPressed: () => Navigator.pop(c, true), child: const Text('Delete'))])); if (ok == true && context.mounted) { await widget.store.deleteTask(task.id); if (context.mounted) Navigator.pop(context); } }
  String _formatDateTime(BuildContext context, DateTime value) => '${value.day}/${value.month}/${value.year} at ${TimeOfDay.fromDateTime(value).format(context)}';
  String _formatDuration(Duration? value) { if (value == null) return 'Not configured'; if (value.inHours >= 1 && value.inMinutes % 60 == 0) return '${value.inHours} hour${value.inHours == 1 ? '' : 's'}'; return '${value.inMinutes} minutes'; }
  String _repeatLabel(Task task) => switch (task.repeat) { TaskRepeat.none => 'Does not repeat', TaskRepeat.daily => 'Daily', TaskRepeat.weekdays => 'Weekdays', TaskRepeat.weekly => 'Weekly', TaskRepeat.monthly => 'Monthly', TaskRepeat.custom => 'Every ${task.repeatIntervalDays ?? 1} days' };
  String _priorityLabel(TaskPriority value) => switch (value) { TaskPriority.low => 'Low', TaskPriority.normal => 'Normal', TaskPriority.high => 'High' };
}

class _SubtaskRow extends StatelessWidget {
  const _SubtaskRow({required this.taskId, required this.item, required this.store});
  final String taskId; final TaskSubtask item; final TaskStore store;
  @override Widget build(BuildContext context) => ListTile(contentPadding: EdgeInsets.zero, leading: Checkbox(value: item.isCompleted, onChanged: (value) => store.updateSubtask(taskId, item.id, isCompleted: value ?? false)), title: Text(item.title, style: TextStyle(decoration: item.isCompleted ? TextDecoration.lineThrough : null, fontWeight: FontWeight.w600)), trailing: IconButton(tooltip: 'Delete checklist item', icon: const Icon(Icons.close_rounded), onPressed: () => store.deleteSubtask(taskId, item.id)));
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.entry}); final TaskHistoryEntry entry;
  @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.circle, size: 8), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(entry.action, style: const TextStyle(fontWeight: FontWeight.w700)), if (entry.detail.isNotEmpty) Text(entry.detail), Text(_format(entry.timestamp), style: Theme.of(context).textTheme.bodySmall)]))]));
  String _format(DateTime value) => '${value.day}/${value.month}/${value.year} • ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.icon, required this.child, this.trailing});
  final String title; final IconData icon; final Widget child; final Widget? trailing;
  @override Widget build(BuildContext context) => Card(elevation: 0, child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Icon(icon), const SizedBox(width: 10), Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16))), if (trailing != null) trailing!]), const SizedBox(height: 14), child]));
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.icon, required this.title, required this.child}); final IconData icon; final String title; final Widget child;
  @override Widget build(BuildContext context) => Card(elevation: 0, child: Padding(padding: const EdgeInsets.all(18), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 6), child]))])));
}
