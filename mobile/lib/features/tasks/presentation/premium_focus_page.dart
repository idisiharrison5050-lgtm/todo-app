import 'dart:async';
import 'package:flutter/material.dart';
import '../application/task_store.dart';

class PremiumFocusPage extends StatefulWidget {
  const PremiumFocusPage({super.key, required this.store, this.initialTaskId});
  final TaskStore store;
  final String? initialTaskId;

  @override
  State<PremiumFocusPage> createState() => _PremiumFocusPageState();
}

class _PremiumFocusPageState extends State<PremiumFocusPage> {
  Timer? _timer;
  Duration _length = const Duration(minutes: 25);
  Duration _remaining = const Duration(minutes: 25);
  bool _running = false;
  String? _taskId;
  int _completed = 0;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialTaskId;
    if (initial != null && widget.store.tasks.any((task) => task.id == initial && !task.isCompleted)) {
      _taskId = initial;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggle() {
    if (_running) {
      _timer?.cancel();
      setState(() => _running = false);
      return;
    }
    setState(() => _running = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remaining.inSeconds <= 1) {
        _timer?.cancel();
        if (!mounted) return;
        setState(() {
          _remaining = Duration.zero;
          _running = false;
          _completed++;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Focus session complete. Nice work.')));
      } else if (mounted) {
        setState(() => _remaining -= const Duration(seconds: 1));
      }
    });
  }

  void _setLength(Duration value) {
    if (_running) return;
    _timer?.cancel();
    setState(() {
      _length = value;
      _remaining = value;
    });
  }

  Future<void> _customLength() async {
    final minutes = await showDialog<int>(
      context: context,
      builder: (dialogContext) => _CustomFocusDialog(initialMinutes: _length.inMinutes),
    );
    if (minutes != null && mounted) {
      _setLength(Duration(minutes: minutes));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final active = widget.store.tasks.where((task) => !task.isCompleted).toList()
      ..sort((a, b) {
        final aOverdue = a.dueAt != null && a.dueAt!.isBefore(DateTime.now());
        final bOverdue = b.dueAt != null && b.dueAt!.isBefore(DateTime.now());
        if (aOverdue != bOverdue) return aOverdue ? -1 : 1;
        if (a.dueAt == null && b.dueAt == null) return 0;
        if (a.dueAt == null) return 1;
        if (b.dueAt == null) return -1;
        return a.dueAt!.compareTo(b.dueAt!);
      });
    final progress = _length.inSeconds == 0 ? 0.0 : 1 - (_remaining.inSeconds / _length.inSeconds).clamp(0.0, 1.0);
    final mm = _remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = _remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
    final selected = _taskId == null ? null : active.where((task) => task.id == _taskId).firstOrNull;

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 0),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Focus', style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -1.5)),
                        const SizedBox(height: 4),
                        Text(_running ? 'Protect this time.' : 'Make space for deep work.', style: TextStyle(color: scheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  CircleAvatar(backgroundColor: scheme.primaryContainer, child: Icon(Icons.self_improvement_rounded, color: scheme.primary)),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 0),
            sliver: SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [scheme.primary, scheme.tertiary]),
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [BoxShadow(color: scheme.primary.withValues(alpha: .22), blurRadius: 30, offset: const Offset(0, 14))],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text(_running ? '● SESSION LIVE' : 'READY WHEN YOU ARE', style: TextStyle(color: scheme.onPrimary, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                        const Spacer(),
                        if (_completed > 0) Text('$_completed completed', style: TextStyle(color: scheme.onPrimary.withValues(alpha: .8), fontSize: 11, fontWeight: FontWeight.w800)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: 224,
                      height: 224,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(value: progress, strokeWidth: 13, backgroundColor: scheme.onPrimary.withValues(alpha: .13), color: scheme.onPrimary),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(_running ? Icons.bolt_rounded : Icons.hourglass_empty_rounded, color: scheme.onPrimary, size: 26),
                              const SizedBox(height: 4),
                              Text('$mm:$ss', style: TextStyle(color: scheme.onPrimary, fontSize: 50, fontWeight: FontWeight.w900, letterSpacing: -2.5)),
                              Text(_taskId == null ? '${_length.inMinutes} MIN SESSION' : 'TASK SELECTED', style: TextStyle(color: scheme.onPrimary.withValues(alpha: .72), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: FilledButton.icon(
                        onPressed: _toggle,
                        style: FilledButton.styleFrom(backgroundColor: scheme.onPrimary, foregroundColor: scheme.primary),
                        icon: Icon(_running ? Icons.pause_rounded : Icons.play_arrow_rounded),
                        label: Text(_running ? 'Pause session' : 'Start session'),
                      ),
                    ),
                    if (selected != null) ...[
                      const SizedBox(height: 10),
                      Text('Working on “${selected.title}”', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: scheme.onPrimary.withValues(alpha: .84), fontWeight: FontWeight.w700)),
                    ],
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(22, 14, 22, 0),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  _Preset(label: '15 min', active: _length.inMinutes == 15, onTap: () => _setLength(const Duration(minutes: 15))),
                  const SizedBox(width: 7),
                  _Preset(label: '25 min', active: _length.inMinutes == 25, onTap: () => _setLength(const Duration(minutes: 25))),
                  const SizedBox(width: 7),
                  _Preset(label: '45 min', active: _length.inMinutes == 45, onTap: () => _setLength(const Duration(minutes: 45))),
                  const SizedBox(width: 7),
                  _Preset(label: '60 min', active: _length.inMinutes == 60, onTap: () => _setLength(const Duration(minutes: 60))),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 0),
            sliver: SliverToBoxAdapter(child: OutlinedButton.icon(onPressed: _running ? null : _customLength, icon: const Icon(Icons.tune_rounded), label: Text('Custom duration · ${_length.inMinutes} min'))),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(22, 28, 22, 10),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Choose your task', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                        const SizedBox(height: 3),
                        Text('Focus mode works best with one clear target.', style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                  if (_taskId != null) TextButton(onPressed: () => setState(() => _taskId = null), child: const Text('Clear')),
                ],
              ),
            ),
          ),
          if (active.isEmpty)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(22, 4, 22, 110),
              sliver: SliverToBoxAdapter(child: _EmptyFocus(scheme: scheme)),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(22, 4, 22, 110),
              sliver: SliverList.separated(
                itemCount: active.length,
                itemBuilder: (context, index) {
                  final task = active[index];
                  final selectedTask = task.id == _taskId;
                  final isOverdue = task.dueAt != null && task.dueAt!.isBefore(DateTime.now());
                  final borderColor = selectedTask ? scheme.primary : (isOverdue ? scheme.error : scheme.outlineVariant);
                  final iconColor = selectedTask ? scheme.onPrimary : (isOverdue ? scheme.error : scheme.onSurfaceVariant);
                  return Material(
                    color: selectedTask ? scheme.primaryContainer.withValues(alpha: .7) : scheme.surface,
                    borderRadius: BorderRadius.circular(22),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(22),
                      onTap: () => setState(() => _taskId = selectedTask ? null : task.id),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), border: Border.all(color: borderColor, width: isOverdue && !selectedTask ? 1.5 : 1)),
                        child: Row(
                          children: [
                            CircleAvatar(backgroundColor: selectedTask ? scheme.primary : (isOverdue ? scheme.errorContainer : scheme.surfaceContainerHighest), child: Icon(selectedTask ? Icons.bolt_rounded : (isOverdue ? Icons.warning_amber_rounded : Icons.radio_button_unchecked_rounded), color: iconColor)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(task.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
                                  if (task.dueAt != null) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        if (isOverdue) ...[
                                          Icon(Icons.warning_amber_rounded, size: 13, color: scheme.error),
                                          const SizedBox(width: 4),
                                          Text('Overdue · ${MaterialLocalizations.of(context).formatMediumDate(task.dueAt!)}', style: TextStyle(fontSize: 11.5, color: scheme.error, fontWeight: FontWeight.w900)),
                                          const SizedBox(width: 5),
                                        ],
                                        Text(
                                          TimeOfDay.fromDateTime(task.dueAt!).format(context),
                                          style: TextStyle(fontSize: 11.5, color: isOverdue ? scheme.error : scheme.onSurfaceVariant, fontWeight: FontWeight.w700),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Icon(selectedTask ? Icons.check_circle_rounded : Icons.chevron_right_rounded, color: selectedTask ? scheme.primary : scheme.onSurfaceVariant),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(height: 9),
              ),
            ),
        ],
      ),
    );
  }
}

class _CustomFocusDialog extends StatefulWidget {
  const _CustomFocusDialog({required this.initialMinutes});
  final int initialMinutes;

  @override
  State<_CustomFocusDialog> createState() => _CustomFocusDialogState();
}

class _CustomFocusDialogState extends State<_CustomFocusDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialMinutes.toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = int.tryParse(_controller.text.trim());
    if (value != null && value >= 5 && value <= 180) {
      Navigator.of(context).pop(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Custom focus session'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
        decoration: const InputDecoration(
          labelText: 'Minutes',
          suffixText: 'min',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Set session'),
        ),
      ],
    );
  }
}

class _Preset extends StatelessWidget {
  const _Preset({required this.label, required this.active, required this.onTap});
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: active ? scheme.primaryContainer : null,
          foregroundColor: active ? scheme.primary : null,
          side: BorderSide(color: active ? scheme.primary : scheme.outlineVariant),
          padding: const EdgeInsets.symmetric(vertical: 13),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
    );
  }
}

class _EmptyFocus extends StatelessWidget {
  const _EmptyFocus({required this.scheme});
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(color: scheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(24)),
        child: Row(
          children: [
            Icon(Icons.inbox_outlined, color: scheme.onSurfaceVariant),
            const SizedBox(width: 14),
            Expanded(child: Text('Create an active task and it will appear here.', style: TextStyle(color: scheme.onSurfaceVariant, fontWeight: FontWeight.w600))),
          ],
        ),
      );
}