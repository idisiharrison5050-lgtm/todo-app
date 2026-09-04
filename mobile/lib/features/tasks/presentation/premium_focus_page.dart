import 'dart:async';

import 'package:flutter/material.dart';

import '../application/task_store.dart';

class PremiumFocusPage extends StatefulWidget {
  const PremiumFocusPage({super.key, required this.store});

  final TaskStore store;

  @override
  State<PremiumFocusPage> createState() => _PremiumFocusPageState();
}

class _PremiumFocusPageState extends State<PremiumFocusPage> {
  Timer? _timer;
  Duration _remaining = const Duration(minutes: 25);
  Duration _sessionLength = const Duration(minutes: 25);
  bool _running = false;
  String? _selectedTaskId;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleTimer() {
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
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('Focus session complete. Nice work.'),
          ),
        );
        return;
      }
      if (mounted) setState(() => _remaining -= const Duration(seconds: 1));
    });
  }

  void _reset(Duration duration) {
    _timer?.cancel();
    setState(() {
      _running = false;
      _sessionLength = duration;
      _remaining = duration;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final active = widget.store.tasks.where((task) => !task.isCompleted).toList();
    final progress = _sessionLength.inSeconds == 0
        ? 0.0
        : 1 - (_remaining.inSeconds / _sessionLength.inSeconds).clamp(0.0, 1.0);
    final minutes = _remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = _remaining.inSeconds.remainder(60).toString().padLeft(2, '0');

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 0),
            sliver: SliverToBoxAdapter(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Focus', style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -1.4)),
                const SizedBox(height: 5),
                Text('One thing at a time.', style: TextStyle(color: scheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 0),
            sliver: SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [scheme.primary, scheme.tertiary]),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Column(children: [
                  Stack(alignment: Alignment.center, children: [
                    SizedBox(width: 218, height: 218, child: CircularProgressIndicator(value: progress, strokeWidth: 12, backgroundColor: scheme.onPrimary.withValues(alpha: .14), color: scheme.onPrimary)),
                    Column(children: [
                      Icon(Icons.bolt_rounded, color: scheme.onPrimary, size: 25),
                      const SizedBox(height: 5),
                      Text('$minutes:$seconds', style: TextStyle(color: scheme.onPrimary, fontSize: 48, fontWeight: FontWeight.w900, letterSpacing: -2)),
                      Text(_running ? 'IN FOCUS' : 'READY', style: TextStyle(color: scheme.onPrimary.withValues(alpha: .72), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 2)),
                    ]),
                  ]),
                  const SizedBox(height: 22),
                  FilledButton.icon(
                    onPressed: _toggleTimer,
                    style: FilledButton.styleFrom(backgroundColor: scheme.onPrimary, foregroundColor: scheme.primary, minimumSize: const Size.fromHeight(54)),
                    icon: Icon(_running ? Icons.pause_rounded : Icons.play_arrow_rounded),
                    label: Text(_running ? 'Pause focus' : 'Start focus'),
                  ),
                ]),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(22, 14, 22, 0),
            sliver: SliverToBoxAdapter(
              child: Row(children: [
                _Preset(label: '15m', onTap: () => _reset(const Duration(minutes: 15))),
                const SizedBox(width: 8),
                _Preset(label: '25m', onTap: () => _reset(const Duration(minutes: 25))),
                const SizedBox(width: 8),
                _Preset(label: '45m', onTap: () => _reset(const Duration(minutes: 45))),
                const SizedBox(width: 8),
                _Preset(label: '60m', onTap: () => _reset(const Duration(minutes: 60))),
              ]),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(22, 26, 22, 10),
            sliver: SliverToBoxAdapter(child: Text('Focus on a task', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900))),
          ),
          if (active.isEmpty)
            const SliverPadding(padding: EdgeInsets.fromLTRB(22, 0, 22, 110), sliver: SliverToBoxAdapter(child: Text('Create an active task and it will appear here.')))
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 110),
              sliver: SliverList.separated(
                itemCount: active.length,
                itemBuilder: (_, index) {
                  final task = active[index];
                  final selected = task.id == _selectedTaskId;
                  return Card(
                    child: ListTile(
                      onTap: () => setState(() => _selectedTaskId = selected ? null : task.id),
                      leading: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(color: selected ? scheme.primaryContainer : scheme.surfaceContainerHighest, shape: BoxShape.circle),
                        child: Icon(selected ? Icons.bolt_rounded : Icons.radio_button_unchecked_rounded, color: selected ? scheme.primary : scheme.onSurfaceVariant),
                      ),
                      title: Text(task.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
                      subtitle: task.dueAt == null ? null : Text(TimeOfDay.fromDateTime(task.dueAt!).format(context)),
                      trailing: selected ? Icon(Icons.check_circle_rounded, color: scheme.primary) : const Icon(Icons.chevron_right_rounded),
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

class _Preset extends StatelessWidget {
  const _Preset({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(child: OutlinedButton(onPressed: onTap, child: Text(label)));
  }
}
