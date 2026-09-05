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
  @override void dispose() { _subtaskController.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(animation: widget.store, builder: (context, _) {
      final task = widget.store.tasks.firstWhere((value) => value.id == widget.task.id, orElse: () => widget.task);
      final completed = task.subtasks.where((item) => item.isCompleted).length;
      final progress = task.subtasks.isEmpty ? 0.0 : completed / task.subtasks.length;
      final due = task.dueAt;
      final overdue = !task.isCompleted && due != null && due.isBefore(DateTime.now());
      return Scaffold(
        appBar: AppBar(title: const Text('Task'), actions: [
          IconButton(tooltip: task.isFavorite ? 'Remove favorite' : 'Add favorite', icon: Icon(task.isFavorite ? Icons.star_rounded : Icons.star_border_rounded), onPressed: () => widget.store.toggleFavorite(task.id)),
          PopupMenuButton<String>(tooltip: 'More actions', onSelected: (value) { if (value == 'edit') { Navigator.push(context, MaterialPageRoute(builder: (_) => AddTaskPage(store: widget.store, task: task))); } else if (value == 'delete') { _delete(context, task); } }, itemBuilder: (_) => const [PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit_outlined), title: Text('Edit task'))), PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete_outline), title: Text('Delete task')))]),
        ]),
        body: ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 40), children: [
          _TaskHero(task: task, overdue: overdue, onToggle: () => widget.store.toggleCompleted(task.id)),
          const SizedBox(height: 12),
          _ScheduleBanner(task: task, overdue: overdue),
          const SizedBox(height: 12),
          OutlinedButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddTaskPage(store: widget.store, task: task))), icon: const Icon(Icons.edit_outlined), label: const Text('Edit task details')),
          if (task.notes.isNotEmpty) ...[const SizedBox(height: 16), _SectionCard(title: 'Notes', icon: Icons.notes_outlined, child: Text(task.notes, style: Theme.of(context).textTheme.bodyLarge))],
          const SizedBox(height: 16), _DetailsGrid(task: task, overdue: overdue), const SizedBox(height: 16),
          _SectionCard(title: 'Checklist', icon: Icons.checklist_rounded, trailing: task.subtasks.isEmpty ? null : Text('$completed/${task.subtasks.length}', style: const TextStyle(fontWeight: FontWeight.w800)), child: Column(children: [
            if (task.subtasks.isNotEmpty) ...[ClipRRect(borderRadius: BorderRadius.circular(10), child: LinearProgressIndicator(value: progress, minHeight: 7)), const SizedBox(height: 12)],
            ...task.subtasks.map<Widget>((item) => _SubtaskRow(taskId: task.id, item: item, store: widget.store)),
            if (task.subtasks.isNotEmpty) const Divider(height: 24),
            Row(children: [Expanded(child: TextField(controller: _subtaskController, textInputAction: TextInputAction.done, onSubmitted: (_) => _addSubtask(task.id), decoration: const InputDecoration(hintText: 'Add checklist item', prefixIcon: Icon(Icons.add_task)))), const SizedBox(width: 8), IconButton.filled(tooltip: 'Add checklist item', onPressed: () => _addSubtask(task.id), icon: const Icon(Icons.add_rounded))]),
          ])),
          const SizedBox(height: 16),
          _SectionCard(title: 'Activity', icon: Icons.history_rounded, trailing: Text('${task.history.length}', style: const TextStyle(fontWeight: FontWeight.w800)), child: task.history.isEmpty ? Text('Activity will appear here as you work.', style: Theme.of(context).textTheme.bodyMedium) : Column(children: task.history.reversed.take(12).map<Widget>((entry) => _HistoryRow(entry: entry)).toList())),
          const SizedBox(height: 24),
          FilledButton.icon(onPressed: () => widget.store.toggleCompleted(task.id), icon: Icon(task.isCompleted ? Icons.replay_rounded : Icons.check_rounded), label: Text(task.isCompleted ? 'Mark active' : 'Complete task')),
        ]),
      );
    });
  }
  void _addSubtask(String taskId) { final value = _subtaskController.text.trim(); if (value.isEmpty) return; widget.store.addSubtask(taskId, value); _subtaskController.clear(); FocusManager.instance.primaryFocus?.unfocus(); }
  Future<void> _delete(BuildContext context, Task task) async { final ok = await showDialog<bool>(context: context, builder: (c) => AlertDialog(title: const Text('Delete task?'), content: Text('Delete “${task.title}”? This cannot be undone.'), actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')), FilledButton.tonal(onPressed: () => Navigator.pop(c, true), child: const Text('Delete'))])); if (ok == true && context.mounted) { await widget.store.deleteTask(task.id); if (context.mounted) Navigator.pop(context); } }
}

class _TaskHero extends StatelessWidget {
  const _TaskHero({required this.task, required this.overdue, required this.onToggle});
  final Task task; final bool overdue; final VoidCallback onToggle;
  @override
  Widget build(BuildContext context) { final scheme = Theme.of(context).colorScheme; return Container(padding: const EdgeInsets.fromLTRB(18, 20, 18, 18), decoration: BoxDecoration(color: scheme.surfaceContainerHigh, borderRadius: BorderRadius.circular(28), border: Border.all(color: scheme.outlineVariant.withValues(alpha: .75))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(crossAxisAlignment: CrossAxisAlignment.start, children: [GestureDetector(onTap: onToggle, child: AnimatedContainer(duration: const Duration(milliseconds: 220), width: 34, height: 34, decoration: BoxDecoration(color: task.isCompleted ? scheme.primary : Colors.transparent, borderRadius: BorderRadius.circular(11), border: Border.all(color: task.isCompleted ? scheme.primary : scheme.outline, width: 1.6)), child: task.isCompleted ? Icon(Icons.check_rounded, size: 22, color: scheme.onPrimary) : null)), const SizedBox(width: 14), Expanded(child: Text(task.title, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800, decoration: task.isCompleted ? TextDecoration.lineThrough : null, decorationThickness: 2)))]), if (overdue || task.isFavorite || task.priority == TaskPriority.high) ...[const SizedBox(height: 18), Wrap(spacing: 7, runSpacing: 7, children: [if (overdue) _StatusPill(icon: Icons.warning_amber_rounded, label: 'Overdue', color: scheme.error), if (task.isFavorite) _StatusPill(icon: Icons.star_rounded, label: 'Favorite', color: scheme.primary), if (task.priority == TaskPriority.high) _StatusPill(icon: Icons.bolt_rounded, label: 'High priority', color: scheme.error)])]])); }
}

class _ScheduleBanner extends StatelessWidget {
  const _ScheduleBanner({required this.task, required this.overdue});
  final Task task; final bool overdue;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final due = task.dueAt;
    final accent = overdue ? scheme.error : scheme.primary;
    String headline; String detail;
    if (task.isCompleted) {
      headline = 'Completed';
      detail = due == null ? 'This task is finished.' : 'Completed task · due ${TimeOfDay.fromDateTime(due).format(context)}';
    } else if (due == null) {
      headline = 'No deadline';
      detail = task.reminderType == TaskReminderType.none ? 'Add a due date or reminder when you are ready.' : 'Reminder is configured for this task.';
    } else {
      final difference = due.difference(DateTime.now());
      final absolute = difference.abs();
      final hours = absolute.inHours;
      final minutes = absolute.inMinutes.remainder(60);
      final relative = hours > 0 ? '$hours h ${minutes} min' : '${minutes.clamp(1, 59)} min';
      headline = overdue ? 'Needs attention' : 'Scheduled';
      detail = overdue ? 'Overdue by $relative' : 'Due in $relative · ${TimeOfDay.fromDateTime(due).format(context)}';
    }
    return Container(padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13), decoration: BoxDecoration(color: accent.withValues(alpha: .09), borderRadius: BorderRadius.circular(19), border: Border.all(color: accent.withValues(alpha: .22))), child: Row(children: [Container(width: 38, height: 38, decoration: BoxDecoration(color: accent.withValues(alpha: .13), shape: BoxShape.circle), child: Icon(task.isCompleted ? Icons.check_circle_outline_rounded : overdue ? Icons.warning_amber_rounded : Icons.schedule_rounded, color: accent, size: 20)), const SizedBox(width: 11), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(headline, style: TextStyle(fontWeight: FontWeight.w900, color: accent)), const SizedBox(height: 2), Text(detail, style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant))]))]));
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.icon, required this.label, required this.color});
  final IconData icon; final String label; final Color color;
  @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7), decoration: BoxDecoration(color: color.withValues(alpha: .11), borderRadius: BorderRadius.circular(12)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 15, color: color), const SizedBox(width: 5), Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color))]));
}

class _DetailsGrid extends StatelessWidget {
  const _DetailsGrid({required this.task, required this.overdue});
  final Task task; final bool overdue;
  @override
  Widget build(BuildContext context) { final items = <Widget>[_DetailTile(icon: Icons.schedule_rounded, title: 'Due', value: task.dueAt == null ? 'No due date' : _formatDateTime(context, task.dueAt!), emphasis: overdue), _DetailTile(icon: Icons.notifications_none_rounded, title: 'Reminder', value: task.reminderType == TaskReminderType.none ? 'Off' : task.reminderType == TaskReminderType.once ? 'Once' : 'Every ${_formatDuration(task.reminderInterval)}'), _DetailTile(icon: Icons.repeat_rounded, title: 'Repeat', value: _repeatLabel(task)), _DetailTile(icon: Icons.flag_outlined, title: 'Priority', value: _priorityLabel(task.priority), emphasis: task.priority == TaskPriority.high)]; if (task.category.isNotEmpty) items.add(_DetailTile(icon: Icons.folder_outlined, title: 'Category', value: task.category)); if (task.tags.isNotEmpty) items.add(_DetailTile(icon: Icons.tag_rounded, title: 'Tags', value: task.tags.join('  ·  '))); return GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: items.length, gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.55), itemBuilder: (_, index) => items[index]); }
  String _formatDateTime(BuildContext context, DateTime value) => '${MaterialLocalizations.of(context).formatMediumDate(value)} · ${TimeOfDay.fromDateTime(value).format(context)}';
  String _formatDuration(Duration? value) { if (value == null) return 'Not configured'; if (value.inHours >= 1 && value.inMinutes % 60 == 0) return '${value.inHours}h'; return '${value.inMinutes}m'; }
  String _repeatLabel(Task task) => switch (task.repeat) { TaskRepeat.none => 'Does not repeat', TaskRepeat.daily => 'Daily', TaskRepeat.weekdays => 'Weekdays', TaskRepeat.weekly => 'Weekly', TaskRepeat.monthly => 'Monthly', TaskRepeat.custom => 'Every ${task.repeatIntervalDays ?? 1} days' };
  String _priorityLabel(TaskPriority value) => switch (value) { TaskPriority.low => 'Low', TaskPriority.normal => 'Normal', TaskPriority.high => 'High' };
}

class _DetailTile extends StatelessWidget {
  const _DetailTile({required this.icon, required this.title, required this.value, this.emphasis = false});
  final IconData icon; final String title; final String value; final bool emphasis;
  @override Widget build(BuildContext context) { final scheme = Theme.of(context).colorScheme; final color = emphasis ? scheme.error : scheme.primary; return Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: scheme.surfaceContainerHighest.withValues(alpha: .55), borderRadius: BorderRadius.circular(20)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, size: 19, color: color), const Spacer(), Text(title, style: Theme.of(context).textTheme.bodySmall), const SizedBox(height: 3), Text(value, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w800, color: emphasis ? color : null))])); }
}

class _SubtaskRow extends StatelessWidget {
  const _SubtaskRow({required this.taskId, required this.item, required this.store});
  final String taskId; final TaskSubtask item; final TaskStore store;
  @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Row(children: [Checkbox(value: item.isCompleted, onChanged: (value) => store.updateSubtask(taskId, item.id, isCompleted: value ?? false)), Expanded(child: Text(item.title, style: TextStyle(fontWeight: FontWeight.w600, decoration: item.isCompleted ? TextDecoration.lineThrough : null))), IconButton(tooltip: 'Delete checklist item', icon: const Icon(Icons.close_rounded), onPressed: () => store.deleteSubtask(taskId, item.id))]));
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.entry});
  final TaskHistoryEntry entry;
  @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 14), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(width: 9, height: 9, margin: const EdgeInsets.only(top: 5), decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, shape: BoxShape.circle)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(entry.action, style: const TextStyle(fontWeight: FontWeight.w700)), if (entry.detail.isNotEmpty) ...[const SizedBox(height: 2), Text(entry.detail)], const SizedBox(height: 2), Text('${entry.timestamp.day}/${entry.timestamp.month}/${entry.timestamp.year} · ${entry.timestamp.hour.toString().padLeft(2, '0')}:${entry.timestamp.minute.toString().padLeft(2, '0')}', style: Theme.of(context).textTheme.bodySmall)]))]));
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.icon, required this.child, this.trailing});
  final String title; final IconData icon; final Widget child; final Widget? trailing;
  @override Widget build(BuildContext context) { final scheme = Theme.of(context).colorScheme; return Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: scheme.surfaceContainerHigh, borderRadius: BorderRadius.circular(24), border: Border.all(color: scheme.outlineVariant.withValues(alpha: .7))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Icon(icon, size: 20, color: scheme.primary), const SizedBox(width: 10), Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16))), if (trailing != null) trailing!]), const SizedBox(height: 15), child])); }
}
