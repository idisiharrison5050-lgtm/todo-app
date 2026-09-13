import 'dart:async';
import 'package:flutter/material.dart';
import '../domain/task.dart';
import '../data/task_store.dart';
import '../../settings/presentation/settings_page.dart';
import '../../reminders/data/reminder_scheduler.dart';

class AddTaskPage extends StatefulWidget {
  const AddTaskPage({super.key});
  @override
  State<AddTaskPage> createState() => _AddTaskPageState();
}

class _AddTaskPageState extends State<AddTaskPage> {
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  final _tagsController = TextEditingController();
  bool _detailed = false;
  DateTime? _dueAt;
  String _reminder = 'none';
  String _repeat = 'none';
  String _priority = 'none';
  String _category = 'General';
  bool _favorite = false;
  bool _repeatTask = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _titleController.dispose();
    _notesController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  void _addTask() {
    var title = _titleController.text.trim();
    if (title.isEmpty) return;
    var task = Task(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
      notes: _notesController.text.trim(),
      dueAt: _dueAt ?? DateTime.now().add(const Duration(minutes: 15)),
      reminder: _reminder,
      repeat: _repeat,
      priority: _priority,
      category: _category,
      tags: _tagsController.text.trim(),
      favorite: _favorite,
    );
    TaskStore.of(context).addTask(task);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add task')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: _detailed ? _buildDetailed() : _buildCreateChoice(),
        ),
      ),
    );
  }

  Widget _buildCreateChoice() {
    return _ModeCard(
      icon: Icons.flash_on_rounded,
      title: 'Quick Capture',
      description: 'Capture the task now and add details when you need them.',
      badge: 'FAST',
      scheme: Theme.of(context).colorScheme,
      autofocus: true,
      controller: _titleController,
      onSave: _addTask,
      onMore: () => setState(() => _detailed = true),
      onTap: _addTask,
    );
  }

  Widget _buildDetailed() {
    var scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          IconButton(onPressed: () => setState(() => _detailed = false), icon: const Icon(Icons.arrow_back_rounded)),
          const SizedBox(width: 4),
          const Text('Task details', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        ]),
        const SizedBox(height: 20),
        _SectionLabel(icon: Icons.edit_note_rounded, title: 'Task'),
        _PremiumField(controller: _titleController, hintText: 'What needs to be done?', prefixIcon: Icons.check_circle_outline_rounded, autofocus: true),
        const SizedBox(height: 22),
        _SectionLabel(icon: Icons.schedule_rounded, title: 'Schedule'),
        _PremiumField(initialValue: _dueAt == null ? 'No due date' : _dueAt.toString(), hintText: 'Due date and time', prefixIcon: Icons.calendar_today_rounded, onSubmitted: (_) {}),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _reminder,
          decoration: const InputDecoration(labelText: 'Reminder'),
          items: const [
            DropdownMenuItem(value: 'none', child: Text('No reminder')),
            DropdownMenuItem(value: '30m', child: Text('30 minutes before')),
            DropdownMenuItem(value: '1h', child: Text('1 hour before')),
            DropdownMenuItem(value: '2h', child: Text('2 hours before')),
            DropdownMenuItem(value: '3h', child: Text('3 hours before')),
            DropdownMenuItem(value: '4h', child: Text('4 hours before')),
            DropdownMenuItem(value: 'custom', child: Text('Custom')),
          ],
          onChanged: (value) => setState(() => _reminder = value ?? 'none'),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _repeat,
          decoration: const InputDecoration(labelText: 'Repeat'),
          items: const [
            DropdownMenuItem(value: 'none', child: Text('Does not repeat')),
            DropdownMenuItem(value: 'daily', child: Text('Daily')),
            DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
            DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
            DropdownMenuItem(value: 'custom', child: Text('Custom')),
          ],
          onChanged: (value) => setState(() => _repeat = value ?? 'none'),
        ),
        const SizedBox(height: 22),
        _SectionLabel(icon: Icons.flag_rounded, title: 'Priority'),
        _PrioritySelector(value: _priority, onChanged: (value) => setState(() => _priority = value)),
        const SizedBox(height: 22),
        _SectionLabel(icon: Icons.folder_rounded, title: 'Organization'),
        DropdownButtonFormField<String>(
          value: _category,
          decoration: const InputDecoration(labelText: 'Category'),
          items: const ['General', 'Work', 'Personal', 'Study', 'Health'].map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
          onChanged: (value) => setState(() => _category = value ?? 'General'),
        ),
        const SizedBox(height: 12),
        _PremiumField(controller: _tagsController, hintText: 'Tags', prefixIcon: Icons.tag_rounded),
        const SizedBox(height: 12),
        _PremiumField(controller: _notesController, hintText: 'Notes', prefixIcon: Icons.notes_rounded, minLines: 3, maxLines: 6),
        const SizedBox(height: 16),
        SwitchListTile.adaptive(value: _repeatTask, onChanged: (value) => setState(() => _repeatTask = value), title: const Text('Repeat task'), contentPadding: EdgeInsets.zero),
        SwitchListTile.adaptive(value: _favorite, onChanged: (value) => setState(() => _favorite = value), title: const Text('Favorite'), contentPadding: EdgeInsets.zero),
        const SizedBox(height: 20),
        SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: _addTask, icon: const Icon(Icons.add_rounded), label: const Text('Add task'))),
        if (scheme.brightness == Brightness.dark) const SizedBox(height: 1),
      ],
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({required this.icon, required this.title, required this.description, required this.badge, required this.onTap, required this.scheme, this.autofocus = false, this.controller, this.onSave, this.onMore});
  final IconData icon;
  final String title;
  final String description;
  final String badge;
  final VoidCallback onTap;
  final ColorScheme scheme;
  final bool autofocus;
  final TextEditingController? controller;
  final VoidCallback? onSave;
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Icon(icon, size: 30, color: scheme.primary), const SizedBox(width: 12), Expanded(child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800))), Chip(label: Text(badge))]),
          const SizedBox(height: 8),
          Text(description),
          const SizedBox(height: 18),
          TextField(controller: controller, autofocus: autofocus, textInputAction: TextInputAction.done, onSubmitted: (_) => onSave?.call(), decoration: const InputDecoration(hintText: 'Type your task...')),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: OutlinedButton(onPressed: onMore, child: const Text('More'))),
            const SizedBox(width: 12),
            Expanded(child: FilledButton(onPressed: onTap, child: const Text('Add task'))),
          ]),
        ]),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.icon, required this.title});
  final IconData icon;
  final String title;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 10, left: 2), child: Row(children: [Icon(icon, size: 19, color: Theme.of(context).colorScheme.primary), const SizedBox(width: 8), Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800))]));
}

class _PremiumField extends StatelessWidget {
  const _PremiumField({this.controller, this.initialValue, required this.hintText, required this.prefixIcon, this.minLines = 1, this.maxLines = 1, this.autofocus = false, this.keyboardType, this.textInputAction, this.onChanged, this.onSubmitted});
  final TextEditingController? controller;
  final String? initialValue;
  final String hintText;
  final IconData prefixIcon;
  final int minLines;
  final int maxLines;
  final bool autofocus;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  @override
  Widget build(BuildContext context) => TextField(controller: controller, autofocus: autofocus, minLines: minLines, maxLines: maxLines, keyboardType: keyboardType, textInputAction: textInputAction, onChanged: onChanged, onSubmitted: onSubmitted, decoration: InputDecoration(hintText: hintText, prefixIcon: Icon(prefixIcon)));
}

class _PrioritySelector extends StatelessWidget {
  const _PrioritySelector({required this.value, required this.onChanged});
  final String value;
  final ValueChanged<String> onChanged;
  @override
  Widget build(BuildContext context) => SegmentedButton<String>(segments: const [ButtonSegment(value: 'none', label: Text('None')), ButtonSegment(value: 'low', label: Text('Low')), ButtonSegment(value: 'medium', label: Text('Medium')), ButtonSegment(value: 'high', label: Text('High'))], selected: {value}, onSelectionChanged: (values) => onChanged(values.first));
}
