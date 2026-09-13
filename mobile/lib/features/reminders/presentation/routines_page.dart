import 'package:flutter/material.dart';

import '../application/routine_store.dart';
import '../domain/routine.dart';

class RoutinesPage extends StatefulWidget {
  const RoutinesPage({super.key, required this.store});
  final RoutineStore store;

  @override
  State<RoutinesPage> createState() => _RoutinesPageState();
}

class _RoutinesPageState extends State<RoutinesPage> {
  @override
  void initState() {
    super.initState();
    widget.store.load();
  }

  Future<void> _openEditor([Routine? routine]) async {
    final result = await showModalBottomSheet<_RoutineDraft>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => _RoutineEditor(initial: routine),
    );
    if (result == null || !mounted) return;

    try {
      if (routine == null) {
        await widget.store.add(
          title: result.title,
          body: result.body,
          startMinutes: result.startMinutes,
          endMinutes: result.endMinutes,
          intervalMinutes: result.intervalMinutes,
          days: result.days,
        );
      } else {
        await widget.store.update(routine.copyWith(
          title: result.title,
          body: result.body,
          startMinutes: result.startMinutes,
          endMinutes: result.endMinutes,
          intervalMinutes: result.intervalMinutes,
          days: result.days,
        ));
      }
      if (mounted) _message(routine == null ? 'Routine created.' : 'Routine updated.');
    } catch (_) {
      if (mounted) _message('The routine could not be saved.');
    }
  }

  Future<void> _delete(Routine routine) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete routine?'),
        content: Text('Remove “${routine.title}” and its scheduled reminders?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true) await widget.store.remove(routine);
  }

  void _message(String text) {
    ScaffoldMessenger.of(context)..hideCurrentSnackBar()..showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return AnimatedBuilder(
      animation: widget.store,
      builder: (context, _) => Scaffold(
        appBar: AppBar(title: const Text('Routines', style: TextStyle(fontWeight: FontWeight.w900))),
        floatingActionButton: FloatingActionButton.extended(onPressed: () => _openEditor(), icon: const Icon(Icons.add_rounded), label: const Text('New routine')),
        body: widget.store.routines.isEmpty
            ? _EmptyRoutines(scheme: scheme, onCreate: () => _openEditor())
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [scheme.primary, scheme.tertiary]),
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: Row(children: [
                      Container(width: 52, height: 52, decoration: BoxDecoration(color: scheme.onPrimary.withValues(alpha: .16), shape: BoxShape.circle), child: Icon(Icons.schedule_rounded, color: scheme.onPrimary)),
                      const SizedBox(width: 14),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('${widget.store.enabledCount} active routine${widget.store.enabledCount == 1 ? '' : 's'}', style: TextStyle(color: scheme.onPrimary, fontSize: 18, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 4),
                        Text('Build your day around what matters to you.', style: TextStyle(color: scheme.onPrimary.withValues(alpha: .78))),
                      ])),
                    ]),
                  ),
                  const SizedBox(height: 24),
                  Text('Your routines', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 10),
                  for (final routine in widget.store.routines) ...[
                    _RoutineCard(routine: routine, onEdit: () => _openEditor(routine), onDelete: () => _delete(routine), onToggle: (value) => widget.store.toggle(routine, value)),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
      ),
    );
  }
}

class _RoutineCard extends StatelessWidget {
  const _RoutineCard({required this.routine, required this.onEdit, required this.onDelete, required this.onToggle});
  final Routine routine;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
        child: Row(children: [
          Container(width: 46, height: 46, decoration: BoxDecoration(color: routine.enabled ? scheme.primaryContainer : scheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(14)), child: Icon(Icons.notifications_active_outlined, color: routine.enabled ? scheme.primary : scheme.onSurfaceVariant)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(routine.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text('${routine.intervalLabel} · ${routine.timeWindowLabel}', style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12.5, fontWeight: FontWeight.w600)),
            const SizedBox(height: 3),
            Text(_daysLabel(routine.days), style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 11.5)),
          ])),
          Switch(value: routine.enabled, onChanged: onToggle),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
                onEdit();
              }
              if (value == 'delete') {
                onDelete();
              }
            },
            itemBuilder: (_) => const [PopupMenuItem(value: 'edit', child: Text('Edit')), PopupMenuItem(value: 'delete', child: Text('Delete'))],
          ),
        ]),
      ),
    );
  }
}

String _daysLabel(List<int> days) {
  if (days.length == 7) return 'Every day';
  if (days.length == 5 && days.every((day) => day >= 1 && day <= 5)) return 'Weekdays';
  if (days.length == 2 && days.contains(6) && days.contains(7)) return 'Weekends';
  const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  return days.map((day) => names[day - 1]).join(' · ');
}

class _RoutineDraft {
  const _RoutineDraft({required this.title, required this.body, required this.startMinutes, required this.endMinutes, required this.intervalMinutes, required this.days});
  final String title;
  final String body;
  final int startMinutes;
  final int endMinutes;
  final int intervalMinutes;
  final List<int> days;
}

class _RoutineEditor extends StatefulWidget {
  const _RoutineEditor({this.initial});
  final Routine? initial;

  @override
  State<_RoutineEditor> createState() => _RoutineEditorState();
}

class _RoutineEditorState extends State<_RoutineEditor> {
  late final TextEditingController _title;
  late final TextEditingController _body;
  late int _startMinutes;
  late int _endMinutes;
  late int _intervalMinutes;
  late List<int> _days;
  String? _error;

  @override
  void initState() {
    super.initState();
    final routine = widget.initial;
    _title = TextEditingController(text: routine?.title ?? '');
    _body = TextEditingController(text: routine?.body ?? '');
    _startMinutes = routine?.startMinutes ?? 480;
    _endMinutes = routine?.endMinutes ?? 1320;
    _intervalMinutes = routine?.intervalMinutes ?? 120;
    _days = List<int>.from(routine?.days ?? const [1, 2, 3, 4, 5, 6, 7]);
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _pickTime(bool start) async {
    final selected = await showTimePicker(context: context, initialTime: TimeOfDay(hour: (start ? _startMinutes : _endMinutes) ~/ 60, minute: (start ? _startMinutes : _endMinutes) % 60));
    if (selected == null || !mounted) return;
    setState(() {
      final value = selected.hour * 60 + selected.minute;
      if (start) {
        _startMinutes = value;
      } else {
        _endMinutes = value;
      }
    });
  }

  Future<void> _customInterval() async {
    final controller = TextEditingController(text: _intervalMinutes.toString());
    final value = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Custom interval'),
        content: TextField(controller: controller, autofocus: true, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Minutes', helperText: 'Choose any interval from 1 to 1440 minutes.')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          FilledButton(onPressed: () { final parsed = int.tryParse(controller.text.trim()); if (parsed != null && parsed >= 1 && parsed <= 1440) Navigator.pop(dialogContext, parsed); }, child: const Text('Set')),
        ],
      ),
    );
    controller.dispose();
    if (value != null && mounted) setState(() => _intervalMinutes = value);
  }

  void _save() {
    final title = _title.text.trim();
    if (title.isEmpty) { setState(() => _error = 'Give this routine a name.'); return; }
    if (_days.isEmpty) { setState(() => _error = 'Select at least one day.'); return; }
    if (_endMinutes < _startMinutes) { setState(() => _error = 'The end time must be after the start time.'); return; }
    if (_intervalMinutes < 1) { setState(() => _error = 'Interval must be at least 1 minute.'); return; }
    Navigator.pop(context, _RoutineDraft(title: title, body: _body.text.trim(), startMinutes: _startMinutes, endMinutes: _endMinutes, intervalMinutes: _intervalMinutes, days: _days));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final intervalOptions = <int>[15, 30, 60, 90, 120, 180];
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(22, 8, 22, MediaQuery.viewInsetsOf(context).bottom + 22),
        child: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.initial == null ? 'Create routine' : 'Edit routine', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text('You decide what, when, how often, and on which days.', style: TextStyle(color: scheme.onSurfaceVariant)),
            const SizedBox(height: 20),
            TextField(controller: _title, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(labelText: 'What should we remind you about?', hintText: 'e.g. Drink water, stretch, study, call Mum…', prefixIcon: Icon(Icons.edit_note_rounded))),
            const SizedBox(height: 12),
            TextField(controller: _body, maxLines: 2, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(labelText: 'Notification message (optional)', hintText: 'Add a little context')),
            const SizedBox(height: 22),
            Text('Suggested shortcuts', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: const ['Drink water', 'Take a break', 'Eat', 'Stretch'].map((value) => _SuggestionChip(label: value)).toList()),
            const SizedBox(height: 22),
            Text('Time window', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Row(children: [Expanded(child: _TimeButton(label: 'Starts', minutes: _startMinutes, onTap: () => _pickTime(true))), const SizedBox(width: 10), Expanded(child: _TimeButton(label: 'Ends', minutes: _endMinutes, onTap: () => _pickTime(false)))]),
            const SizedBox(height: 22),
            Text('Remind me', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [...intervalOptions.map((minutes) => ChoiceChip(label: Text(_intervalText(minutes)), selected: _intervalMinutes == minutes, onSelected: (_) => setState(() => _intervalMinutes = minutes))), ChoiceChip(label: Text(_intervalText(_intervalMinutes)), selected: !intervalOptions.contains(_intervalMinutes), onSelected: (_) => _customInterval())]),
            const SizedBox(height: 22),
            Text('Days', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Row(children: List.generate(7, (index) { final day = index + 1; final selected = _days.contains(day); const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S']; return Expanded(child: Padding(padding: EdgeInsets.only(right: index == 6 ? 0 : 6), child: ChoiceChip(label: Text(labels[index]), selected: selected, onSelected: (_) => setState(() { if (selected) _days.remove(day); else _days.add(day); _days.sort(); })))); })),
            if (_error != null) ...[const SizedBox(height: 12), Text(_error!, style: TextStyle(color: scheme.error, fontWeight: FontWeight.w700))],
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, height: 54, child: FilledButton.icon(onPressed: _save, icon: const Icon(Icons.check_rounded), label: Text(widget.initial == null ? 'Create routine' : 'Save changes'))),
          ]),
        ),
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => ActionChip(label: Text(label), avatar: const Icon(Icons.auto_awesome_rounded, size: 16), onPressed: () { final editor = context.findAncestorStateOfType<_RoutineEditorState>(); editor?._title.text = label; });
}

class _TimeButton extends StatelessWidget {
  const _TimeButton({required this.label, required this.minutes, required this.onTap});
  final String label;
  final int minutes;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => OutlinedButton.icon(onPressed: onTap, icon: const Icon(Icons.schedule_rounded), label: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [Text(label, style: const TextStyle(fontSize: 11)), Text(_formatTime(minutes), style: const TextStyle(fontWeight: FontWeight.w900))]));
}

String _formatTime(int minutes) {
  final hour = minutes ~/ 60;
  final minute = minutes % 60;
  final period = hour >= 12 ? 'PM' : 'AM';
  final displayHour = hour % 12 == 0 ? 12 : hour % 12;
  return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
}

String _intervalText(int minutes) {
  if (minutes % 60 == 0) return '${minutes ~/ 60} hr';
  return '$minutes min';
}

class _EmptyRoutines extends StatelessWidget {
  const _EmptyRoutines({required this.scheme, required this.onCreate});
  final ColorScheme scheme;
  final VoidCallback onCreate;
  @override
  Widget build(BuildContext context) => Center(child: SingleChildScrollView(padding: const EdgeInsets.all(28), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Container(width: 82, height: 82, decoration: BoxDecoration(color: scheme.primaryContainer, shape: BoxShape.circle), child: Icon(Icons.schedule_rounded, size: 42, color: scheme.primary)), const SizedBox(height: 20), Text('Build your own routine', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900), textAlign: TextAlign.center), const SizedBox(height: 8), Text('Create reminders for anything you want to happen throughout your day. Nothing is hard-coded.', textAlign: TextAlign.center, style: TextStyle(color: scheme.onSurfaceVariant)), const SizedBox(height: 20), FilledButton.icon(onPressed: onCreate, icon: const Icon(Icons.add_rounded), label: const Text('Create your first routine'))])));
}
