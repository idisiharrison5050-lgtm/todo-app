import 'package:flutter/material.dart';
import '../application/task_store.dart';
import '../domain/task.dart';
import 'add_task_page.dart';
import 'task_detail_page.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key, required this.store});
  final TaskStore store;

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late DateTime _month;
  late DateTime _selected;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
    _selected = DateTime(now.year, now.month, now.day);
  }

  void _shiftMonth(int amount) {
    setState(() {
      _month = DateTime(_month.year, _month.month + amount);
      if (_selected.month != _month.month || _selected.year != _month.year) {
        _selected = DateTime(_month.year, _month.month, 1);
      }
    });
  }

  void _today() {
    final now = DateTime.now();
    setState(() {
      _month = DateTime(now.year, now.month);
      _selected = DateTime(now.year, now.month, now.day);
    });
  }

  List<Task> _tasksFor(DateTime day) {
    return widget.store.tasks.where((task) {
      final due = task.dueAt;
      return due != null &&
          due.year == day.year &&
          due.month == day.month &&
          due.day == day.day;
    }).toList()
      ..sort((a, b) {
        if (a.dueAt == null) return 1;
        if (b.dueAt == null) return -1;
        return a.dueAt!.compareTo(b.dueAt!);
      });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final selectedTasks = _tasksFor(_selected);
    final monthTasks = widget.store.tasks.where((task) {
      final due = task.dueAt;
      return due != null && due.year == _month.year && due.month == _month.month;
    }).toList();
    final completed = selectedTasks.where((task) => task.isCompleted).length;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 0),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PLAN YOUR TIME',
                            style: theme.textTheme.labelSmall?.copyWith(
                              letterSpacing: 1.5,
                              color: scheme.primary,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text('Calendar', style: theme.textTheme.displaySmall),
                        ],
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _today,
                      icon: const Icon(Icons.today_rounded, size: 17),
                      label: const Text('Today'),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 24, 18, 0),
              sliver: SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 17, 16, 18),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: scheme.outlineVariant),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => _shiftMonth(-1),
                            icon: const Icon(Icons.chevron_left_rounded),
                          ),
                          Expanded(
                            child: Text(
                              _monthLabel(_month),
                              textAlign: TextAlign.center,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => _shiftMonth(1),
                            icon: const Icon(Icons.chevron_right_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const _WeekHeader(),
                      const SizedBox(height: 8),
                      _MonthGrid(
                        month: _month,
                        selected: _selected,
                        tasksFor: _tasksFor,
                        onSelected: (day) => setState(() => _selected = day),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(22, 25, 22, 12),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _agendaLabel(_selected),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    if (selectedTasks.isNotEmpty)
                      Text(
                        '$completed/${selectedTasks.length} done',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (selectedTasks.isEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(22, 4, 22, 120),
                sliver: SliverToBoxAdapter(
                  child: _EmptyDay(
                    onAdd: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AddTaskPage(store: widget.store),
                      ),
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 120),
                sliver: SliverList.separated(
                  itemCount: selectedTasks.length,
                  itemBuilder: (_, index) => _AgendaCard(
                    task: selectedTasks[index],
                    store: widget.store,
                  ),
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                ),
              ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 120),
              sliver: SliverToBoxAdapter(
                child: Text(
                  '${monthTasks.length} scheduled ${monthTasks.length == 1 ? 'task' : 'tasks'} this month',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _monthLabel(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  String _agendaLabel(DateTime date) {
    const weekdays = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
    ];
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    final today = DateTime.now();
    if (date.year == today.year && date.month == today.month && date.day == today.day) {
      return 'Today';
    }
    return '${weekdays[date.weekday - 1]}, ${date.day} ${months[date.month - 1]}';
  }
}

class _WeekHeader extends StatelessWidget {
  const _WeekHeader();

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return Row(
      children: labels
          .map<Widget>(
            (label) => Expanded(
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: muted,
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.month,
    required this.selected,
    required this.tasksFor,
    required this.onSelected,
  });

  final DateTime month;
  final DateTime selected;
  final List<Task> Function(DateTime) tasksFor;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    final first = DateTime(month.year, month.month, 1);
    final days = DateTime(month.year, month.month + 1, 0).day;
    final leading = first.weekday - 1;
    final total = ((leading + days + 6) ~/ 7) * 7;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: total,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisExtent: 48,
      ),
      itemBuilder: (context, index) {
        final dayNumber = index - leading + 1;
        if (dayNumber < 1 || dayNumber > days) {
          return const SizedBox.shrink();
        }
        final day = DateTime(month.year, month.month, dayNumber);
        final tasks = tasksFor(day);
        final isSelected = _sameDay(day, selected);
        final isToday = _sameDay(day, DateTime.now());
        final scheme = Theme.of(context).colorScheme;

        return GestureDetector(
          onTap: () => onSelected(day),
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 43,
              height: 43,
              decoration: BoxDecoration(
                color: isSelected
                    ? scheme.primary
                    : (isToday ? scheme.primary.withValues(alpha: .09) : Colors.transparent),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$dayNumber',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: isSelected ? scheme.onPrimary : scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 3),
                  SizedBox(
                    height: 4,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: tasks.take(3).map<Widget>((task) {
                        return Container(
                          width: 3.5,
                          height: 3.5,
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? scheme.onPrimary
                                : _priorityColor(task, scheme),
                            shape: BoxShape.circle,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static Color _priorityColor(Task task, ColorScheme scheme) {
    if (task.priority == TaskPriority.high) return scheme.error;
    if (task.priority == TaskPriority.low) return scheme.secondary;
    return scheme.primary;
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _AgendaCard extends StatelessWidget {
  const _AgendaCard({required this.task, required this.store});

  final Task task;
  final TaskStore store;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = task.priority == TaskPriority.high ? scheme.error : scheme.primary;

    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(23),
      child: InkWell(
        borderRadius: BorderRadius.circular(23),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => TaskDetailPage(store: store, task: task),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(23),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => store.toggleCompleted(task.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: task.isCompleted ? accent : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: task.isCompleted ? accent : scheme.outline,
                      width: 2,
                    ),
                  ),
                  child: task.isCompleted
                      ? Icon(Icons.check_rounded, color: scheme.onPrimary, size: 18)
                      : null,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w900,
                        decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Wrap(
                      spacing: 8,
                      runSpacing: 5,
                      children: [
                        if (task.dueAt != null)
                          _Meta(
                            icon: Icons.schedule_rounded,
                            text: TimeOfDay.fromDateTime(task.dueAt!).format(context),
                            color: accent,
                          ),
                        if (task.category.isNotEmpty)
                          _Meta(
                            icon: Icons.folder_outlined,
                            text: task.category,
                            color: scheme.onSurfaceVariant,
                          ),
                        if (task.repeat != TaskRepeat.none)
                          _Meta(
                            icon: Icons.repeat_rounded,
                            text: _repeatLabel(task.repeat),
                            color: scheme.secondary,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (task.isFavorite)
                Icon(Icons.star_rounded, color: scheme.primary, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  String _repeatLabel(TaskRepeat repeat) {
    return switch (repeat) {
      TaskRepeat.daily => 'Daily',
      TaskRepeat.weekdays => 'Weekdays',
      TaskRepeat.weekly => 'Weekly',
      TaskRepeat.monthly => 'Monthly',
      TaskRepeat.custom => 'Custom',
      TaskRepeat.none => '',
    };
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text, required this.color});

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 3),
        Text(
          text,
          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: color),
        ),
      ],
    );
  }
}

class _EmptyDay extends StatelessWidget {
  const _EmptyDay({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.event_available_rounded, color: scheme.primary, size: 27),
          ),
          const SizedBox(height: 15),
          Text(
            'A clear day',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Nothing is scheduled here yet. Add something you want to remember.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 17),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add task'),
          ),
        ],
      ),
    );
  }
}
