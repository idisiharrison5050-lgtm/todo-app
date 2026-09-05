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
  void dispose() { _timer?.cancel(); super.dispose(); }

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
        setState(() { _remaining = Duration.zero; _running = false; });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(behavior: SnackBarBehavior.floating, content: Text('Focus session complete. Nice work.')));
        return;
      }
      if (mounted) setState(() => _remaining -= const Duration(seconds: 1));
    });
  }

  void _reset(Duration duration) {
    _timer?.cancel();
    setState(() { _running = false; _sessionLength = duration; _remaining = duration; });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final active = widget.store.tasks.where((task) => !task.isCompleted).toList();
    final progress = _sessionLength.inSeconds == 0 ? 0.0 : 1 - (_remaining.inSeconds / _sessionLength.inSeconds).clamp(0.0, 1.0);
    final minutes = _remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = _remaining.inSeconds.remainder(60).toString().padLeft(2, '0');

    return SafeArea(
      child: CustomScrollView(slivers: [
        SliverPadding(padding: const EdgeInsets.fromLTRB(22, 24, 22, 0), sliver: SliverToBoxAdapter(child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Focus', style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -1.5)),
            const SizedBox(height: 4),
            Text(_running ? 'Protect this time.' : 'Make space for deep work.', style: TextStyle(color: scheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
          ])),
          Container(width: 46, height: 46, decoration: BoxDecoration(color: scheme.primaryContainer, shape: BoxShape.circle), child: Icon(Icons.self_improvement_rounded, color: scheme.primary)),
        ]))),
        SliverPadding(padding: const EdgeInsets.fromLTRB(22, 22, 22, 0), sliver: SliverToBoxAdapter(child: Container(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
          decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [scheme.primary, scheme.tertiary]), borderRadius: BorderRadius.circular(32), boxShadow: [BoxShadow(color: scheme.primary.withValues(alpha: .22), blurRadius: 30, offset: const Offset(0, 14))]),
          child: Column(children: [
            Row(children: [
              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: scheme.onPrimary.withValues(alpha: .13), borderRadius: BorderRadius.circular(99)), child: Text(_running ? '●  SESSION LIVE' : 'READY WHEN YOU ARE', style: TextStyle(color: scheme.onPrimary, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1))),
              const Spacer(),
              if (_selectedTaskId != null) Icon(Icons.link_rounded, color: scheme.onPrimary.withValues(alpha: .8), size: 19),
            ]),
            const SizedBox(height: 18),
            Stack(alignment: Alignment.center, children: [
              SizedBox(width: 226, height: 226, child: CircularProgressIndicator(value: progress, strokeWidth: 13, backgroundColor: scheme.onPrimary.withValues(alpha: .13), color: scheme.onPrimary)),
              Column(children: [
                Icon(_running ? Icons.bolt_rounded : Icons.hourglass_empty_rounded, color: scheme.onPrimary, size: 26),
                const SizedBox(height: 4),
                Text('$minutes:$seconds', style: TextStyle(color: scheme.onPrimary, fontSize: 50, fontWeight: FontWeight.w900, letterSpacing: -2.5)),
                Text(_selectedTaskId == null ? (_running ? 'IN FOCUS' : '25 MIN SESSION') : 'TASK SELECTED', style: TextStyle(color: scheme.onPrimary.withValues(alpha: .72), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
              ]),
            ]),
            const SizedBox(height: 18),
            FilledButton.icon(onPressed: _toggleTimer, style: FilledButton.styleFrom(backgroundColor: scheme.onPrimary, foregroundColor: scheme.primary, minimumSize: const Size.fromHeight(54)), icon: Icon(_running ? Icons.pause_rounded : Icons.play_arrow_rounded), label: Text(_running ? 'Pause session' : 'Start session')),
          ]),
        ))),
        SliverPadding(padding: const EdgeInsets.fromLTRB(22, 14, 22, 0), sliver: SliverToBoxAdapter(child: Row(children: [
          _Preset(label: '15 min', active: _sessionLength.inMinutes == 15, onTap: () => _reset(const Duration(minutes: 15))),
          const SizedBox(width: 7), _Preset(label: '25 min', active: _sessionLength.inMinutes == 25, onTap: () => _reset(const Duration(minutes: 25))),
          const SizedBox(width: 7), _Preset(label: '45 min', active: _sessionLength.inMinutes == 45, onTap: () => _reset(const Duration(minutes: 45))),
          const SizedBox(width: 7), _Preset(label: '60 min', active: _sessionLength.inMinutes == 60, onTap: () => _reset(const Duration(minutes: 60))),
        ]))),
        SliverPadding(padding: const EdgeInsets.fromLTRB(22, 28, 22, 10), sliver: SliverToBoxAdapter(child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Choose your task', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)), const SizedBox(height: 3), Text('Focus mode works best with one clear target.', style: theme.textTheme.bodySmall)),),
          if (_selectedTaskId != null) TextButton(onPressed: () => setState(() => _selectedTaskId = null), child: const Text('Clear')),
        ]))),
        if (active.isEmpty)
          SliverPadding(padding: const EdgeInsets.fromLTRB(22, 4, 22, 110), sliver: SliverToBoxAdapter(child: Container(padding: const EdgeInsets.all(22), decoration: BoxDecoration(color: scheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(24)), child: Row(children: [Icon(Icons.inbox_outlined, color: scheme.onSurfaceVariant), const SizedBox(width: 14), Expanded(child: Text('Create an active task and it will appear here.', style: TextStyle(color: scheme.onSurfaceVariant, fontWeight: FontWeight.w600)))]))))
        else
          SliverPadding(padding: const EdgeInsets.fromLTRB(22, 4, 22, 110), sliver: SliverList.separated(
            itemCount: active.length,
            itemBuilder: (_, index) {
              final task = active[index];
              final selected = task.id == _selectedTaskId;
              return AnimatedContainer(duration: const Duration(milliseconds: 220), decoration: BoxDecoration(color: selected ? scheme.primaryContainer.withValues(alpha: .72) : scheme.surface, borderRadius: BorderRadius.circular(23), border: Border.all(color: selected ? scheme.primary.withValues(alpha: .45) : scheme.outlineVariant.withValues(alpha: .55), width: selected ? 1.5 : 1), boxShadow: selected ? [BoxShadow(color: scheme.primary.withValues(alpha: .12), blurRadius: 18, offset: const Offset(0, 7))] : null), child: ListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5), onTap: () => setState(() => _selectedTaskId = selected ? null : task.id), leading: AnimatedContainer(duration: const Duration(milliseconds: 180), width: 44, height: 44, decoration: BoxDecoration(color: selected ? scheme.primary : scheme.surfaceContainerHighest, shape: BoxShape.circle), child: Icon(selected ? Icons.bolt_rounded : Icons.radio_button_unchecked_rounded, color: selected ? scheme.onPrimary : scheme.onSurfaceVariant)), title: Text(task.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)), subtitle: task.dueAt == null ? (task.category.isEmpty ? null : Text(task.category)) : Text(task.category.isEmpty ? TimeOfDay.fromDateTime(task.dueAt!).format(context) : '${task.category} • ${TimeOfDay.fromDateTime(task.dueAt!).format(context)}'), trailing: Icon(selected ? Icons.check_circle_rounded : Icons.chevron_right_rounded, color: selected ? scheme.primary : scheme.onSurfaceVariant));
            },
            separatorBuilder: (_, __) => const SizedBox(height: 9),
          )),
      ]),
    );
  }
}

class _Preset extends StatelessWidget {
  const _Preset({required this.label, required this.active, required this.onTap});
  final String label; final bool active; final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(child: OutlinedButton(onPressed: onTap, style: OutlinedButton.styleFrom(backgroundColor: active ? scheme.primaryContainer : null, foregroundColor: active ? scheme.primary : null, side: BorderSide(color: active ? scheme.primary.withValues(alpha: .35) : scheme.outlineVariant), padding: const EdgeInsets.symmetric(vertical: 13)), child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800))));
  }
}
