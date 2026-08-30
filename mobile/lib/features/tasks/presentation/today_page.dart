import 'package:flutter/material.dart';

import '../application/task_store.dart';
import '../domain/task.dart';
import 'add_task_page.dart';

class TodayPage extends StatelessWidget {
  const TodayPage({super.key, required this.store});

  final TaskStore store;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) => _TodayContent(store: store),
    );
  }
}

class _TodayContent extends StatelessWidget {
  const _TodayContent({required this.store});

  final TaskStore store;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tasks = store.tasks;
    final completed = tasks.where((task) => task.isCompleted).length;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              sliver: SliverToBoxAdapter(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Today', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.8)),
                          const SizedBox(height: 4),
                          Text('Sunday, August 30', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                        ],
                      ),
                    ),
                    IconButton.filledTonal(tooltip: 'Settings', onPressed: () {}, icon: const Icon(Icons.settings_outlined)),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              sliver: SliverToBoxAdapter(child: _ProgressCard(total: tasks.length, completed: completed)),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              sliver: SliverToBoxAdapter(
                child: Text('Your tasks', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              ),
            ),
            if (tasks.isEmpty)
              const SliverPadding(
                padding: EdgeInsets.fromLTRB(20, 8, 20, 120),
                sliver: SliverToBoxAdapter(child: _EmptyTasks()),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                sliver: SliverList.separated(
                  itemCount: tasks.length,
                  itemBuilder: (context, index) => Dismissible(
                    key: ValueKey(tasks[index].id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 24),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(Icons.delete_outline, color: theme.colorScheme.onErrorContainer),
                    ),
                    confirmDismiss: (_) async => await _confirmDelete(context, tasks[index]),
                    onDismissed: (_) => store.deleteTask(tasks[index].id),
                    child: _TaskTile(
                      task: tasks[index],
                      onToggle: () => store.toggleCompleted(tasks[index].id),
                      onEdit: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AddTaskPage(store: store, task: tasks[index]),
                        ),
                      ),
                    ),
                  ),
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => AddTaskPage(store: store))),
        icon: const Icon(Icons.add),
        label: const Text('Add task'),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context, Task task) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete task?'),
        content: Text('Delete “${task.title}”? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
          FilledButton.tonal(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Delete')),
        ],
      ),
    );
    return result ?? false;
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.total, required this.completed});

  final int total;
  final int completed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final message = total == 0 ? 'Add your first task for today.' : '$completed of $total tasks completed.';
    return Card(
      color: scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(children: [
          Container(width: 52, height: 52, decoration: BoxDecoration(color: scheme.primary, shape: BoxShape.circle), child: Icon(Icons.check_rounded, color: scheme.onPrimary, size: 28)),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(total == 0 ? 'A fresh start' : 'Keep going', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: scheme.onPrimaryContainer)),
            const SizedBox(height: 4),
            Text(message, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onPrimaryContainer)),
          ])),
        ]),
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({required this.task, required this.onToggle, required this.onEdit});

  final Task task;
  final VoidCallback onToggle;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Checkbox(value: task.isCompleted, onChanged: (_) => onToggle()),
        title: Text(task.title, style: TextStyle(decoration: task.isCompleted ? TextDecoration.lineThrough : null, fontWeight: FontWeight.w700)),
        subtitle: _subtitle(context),
        trailing: Wrap(
          spacing: 0,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (task.reminderType != TaskReminderType.none) const Icon(Icons.notifications_active_outlined),
            IconButton(tooltip: 'Edit task', onPressed: onEdit, icon: const Icon(Icons.more_horiz)),
          ],
        ),
        onTap: onEdit,
      ),
    );
  }

  Widget? _subtitle(BuildContext context) {
    final parts = <String>[];
    if (task.dueAt != null) {
      parts.add('Due ${TimeOfDay.fromDateTime(task.dueAt!).format(context)}');
    }
    if (task.priority == TaskPriority.high) parts.add('High priority');
    return parts.isEmpty ? null : Text(parts.join(' • '));
  }
}

class _EmptyTasks extends StatelessWidget {
  const _EmptyTasks();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      decoration: BoxDecoration(border: Border.all(color: theme.colorScheme.outlineVariant), borderRadius: BorderRadius.circular(24)),
      child: Column(children: [
        Icon(Icons.task_alt_rounded, size: 48, color: theme.colorScheme.primary),
        const SizedBox(height: 16),
        Text('Nothing planned yet', textAlign: TextAlign.center, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text('Add a task and choose when you want Todo to remind you.', textAlign: TextAlign.center, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ]),
    );
  }
}
