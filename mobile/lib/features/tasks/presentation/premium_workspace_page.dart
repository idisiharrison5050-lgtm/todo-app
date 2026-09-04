import 'package:flutter/material.dart';

import '../application/task_store.dart';
import '../domain/task.dart';
import 'add_task_page.dart';
import 'calendar_page.dart';
import 'premium_focus_page.dart';
import 'premium_settings_page.dart';
import 'task_detail_page.dart';

class PremiumWorkspacePage extends StatefulWidget {
  const PremiumWorkspacePage({super.key, required this.store, required this.onLogout});
  final TaskStore store;
  final Future<void> Function() onLogout;
  @override State<PremiumWorkspacePage> createState() => _PremiumWorkspacePageState();
}

class _PremiumWorkspacePageState extends State<PremiumWorkspacePage> {
  int _index = 0;
  void _addTask() => Navigator.of(context).push(MaterialPageRoute(builder: (_) => AddTaskPage(store: widget.store)));
  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      _Today(store: widget.store, onAdd: _addTask, onSearch: () => setState(() => _index = 3)),
      CalendarPage(store: widget.store),
      PremiumFocusPage(store: widget.store),
      _Search(store: widget.store),
      PremiumSettingsPage(onLogout: widget.onLogout),
    ];
    return Scaffold(
      body: AnimatedBuilder(animation: widget.store, builder: (_, __) => IndexedStack(index: _index, children: pages)),
      bottomNavigationBar: _Dock(index: _index, onChanged: (v) => setState(() => _index = v)),
      floatingActionButton: _index == 0 ? FloatingActionButton(onPressed: _addTask, child: const Icon(Icons.add_rounded, size: 29)) : null,
    );
  }
}

class _Dock extends StatelessWidget {
  const _Dock({required this.index, required this.onChanged});
  final int index; final ValueChanged<int> onChanged;
  @override Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    return SafeArea(minimum: const EdgeInsets.fromLTRB(14, 7, 14, 10), child: Container(
      height: 70, padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(color: s.surface, borderRadius: BorderRadius.circular(25), border: Border.all(color: s.outlineVariant.withValues(alpha: .45)), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .07), blurRadius: 28, offset: const Offset(0, 8))]),
      child: Row(children: [
        _DockItem(Icons.check_circle_outline_rounded, 'Today', 0, index, onChanged),
        _DockItem(Icons.calendar_month_outlined, 'Calendar', 1, index, onChanged),
        _DockItem(Icons.timer_outlined, 'Focus', 2, index, onChanged),
        _DockItem(Icons.search_rounded, 'Search', 3, index, onChanged),
        _DockItem(Icons.tune_rounded, 'More', 4, index, onChanged),
      ]),
    ));
  }
}

class _DockItem extends StatelessWidget {
  const _DockItem(this.icon, this.label, this.value, this.index, this.onChanged);
  final IconData icon; final String label; final int value, index; final ValueChanged<int> onChanged;
  @override Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme; final selected = value == index;
    return Expanded(child: InkWell(onTap: () => onChanged(value), borderRadius: BorderRadius.circular(19), child: AnimatedContainer(duration: const Duration(milliseconds: 220), margin: const EdgeInsets.symmetric(horizontal: 2), decoration: BoxDecoration(color: selected ? s.primaryContainer : Colors.transparent, borderRadius: BorderRadius.circular(19)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 22, color: selected ? s.primary : s.onSurfaceVariant), const SizedBox(height: 3), Text(label, style: TextStyle(fontSize: 10.5, fontWeight: selected ? FontWeight.w800 : FontWeight.w600, color: selected ? s.primary : s.onSurfaceVariant))]))));
  }
}

class _Today extends StatelessWidget {
  const _Today({required this.store, required this.onAdd, required this.onSearch});
  final TaskStore store; final VoidCallback onAdd, onSearch;
  @override Widget build(BuildContext context) {
    final now = DateTime.now(); final all = store.tasks; final active = all.where((t) => !t.isCompleted).toList();
    final today = active.where((t) => _sameDay(t.dueAt, now)).toList()..sort(_sortDue);
    final overdue = active.where((t) => t.dueAt != null && t.dueAt!.isBefore(now)).length;
    final completed = all.where((t) => t.isCompleted).length; final progress = all.isEmpty ? 0.0 : completed / all.length; final s = Theme.of(context).colorScheme;
    return SafeArea(child: CustomScrollView(slivers: [
      SliverPadding(padding: const EdgeInsets.fromLTRB(22, 18, 22, 0), sliver: SliverToBoxAdapter(child: Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(_dateLabel(now), style: TextStyle(color: s.onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.w700)), const SizedBox(height: 5), Text('Today', style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -1.4))])), IconButton(onPressed: onSearch, style: IconButton.styleFrom(backgroundColor: s.surfaceContainerHighest), icon: const Icon(Icons.search_rounded))]))),
      SliverPadding(padding: const EdgeInsets.fromLTRB(22, 18, 22, 0), sliver: SliverToBoxAdapter(child: _Progress(progress, completed, all.length))),
      SliverPadding(padding: const EdgeInsets.fromLTRB(22, 25, 22, 10), sliver: SliverToBoxAdapter(child: Row(children: [Expanded(child: Text('My tasks', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900))), if (today.length > 4) Text('${today.length} tasks')]))),
      if (overdue > 0) SliverPadding(padding: const EdgeInsets.fromLTRB(22, 0, 22, 10), sliver: SliverToBoxAdapter(child: _Overdue(overdue))),
      if (today.isEmpty) SliverPadding(padding: const EdgeInsets.fromLTRB(22, 4, 22, 110), sliver: SliverToBoxAdapter(child: _EmptyToday(onAdd))) else SliverPadding(padding: const EdgeInsets.fromLTRB(22, 0, 22, 110), sliver: SliverList.separated(itemCount: today.length, itemBuilder: (_, i) => _TaskTile(task: today[i], store: store), separatorBuilder: (_, __) => const SizedBox(height: 9))),
    ]));
  }
  static bool _sameDay(DateTime? d, DateTime n) => d != null && d.year == n.year && d.month == n.month && d.day == n.day;
  static int _sortDue(Task a, Task b) { if (a.dueAt == null) return 1; if (b.dueAt == null) return -1; return a.dueAt!.compareTo(b.dueAt!); }
  static String _dateLabel(DateTime d) => '${const ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'][d.weekday - 1]}, ${d.day} ${const ['January','February','March','April','May','June','July','August','September','October','November','December'][d.month - 1]}';
}

class _Progress extends StatelessWidget {
  const _Progress(this.progress, this.completed, this.total); final double progress; final int completed, total;
  @override Widget build(BuildContext context) { final s = Theme.of(context).colorScheme; return Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: s.primary, borderRadius: BorderRadius.circular(27)), child: Row(children: [SizedBox(width: 78, height: 78, child: Stack(alignment: Alignment.center, children: [CircularProgressIndicator(value: progress, strokeWidth: 6, backgroundColor: s.onPrimary.withValues(alpha: .18), color: s.onPrimary), Text('${(progress * 100).round()}%', style: TextStyle(color: s.onPrimary, fontWeight: FontWeight.w900))])), const SizedBox(width: 17), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Daily progress', style: TextStyle(color: s.onPrimary.withValues(alpha: .76), fontSize: 12, fontWeight: FontWeight.w700)), const SizedBox(height: 4), Text('$completed of $total completed', style: TextStyle(color: s.onPrimary, fontSize: 19, fontWeight: FontWeight.w900)), const SizedBox(height: 5), Text(progress >= 1 ? 'Everything is done.' : 'Keep going. You are making progress.', style: TextStyle(color: s.onPrimary.withValues(alpha: .8), fontSize: 12.5))]))])); }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({required this.task, required this.store}); final Task task; final TaskStore store;
  @override Widget build(BuildContext context) { final s = Theme.of(context).colorScheme; final accent = task.priority == TaskPriority.high ? s.error : s.primary; return Material(color: s.surface, borderRadius: BorderRadius.circular(21), child: InkWell(onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => TaskDetailPage(store: store, task: task))), borderRadius: BorderRadius.circular(21), child: Container(padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13), decoration: BoxDecoration(borderRadius: BorderRadius.circular(21), border: Border.all(color: s.outlineVariant.withValues(alpha: .42))), child: Row(children: [GestureDetector(onTap: () => store.toggleCompleted(task.id), child: AnimatedContainer(duration: const Duration(milliseconds: 180), width: 27, height: 27, decoration: BoxDecoration(color: task.isCompleted ? accent : Colors.transparent, shape: BoxShape.circle, border: Border.all(color: task.isCompleted ? accent : s.outline, width: 2)), child: task.isCompleted ? const Icon(Icons.check_rounded, size: 17, color: Colors.white) : null)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(task.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, decoration: task.isCompleted ? TextDecoration.lineThrough : null)), const SizedBox(height: 6), Row(children: [if (task.dueAt != null) ...[Icon(Icons.schedule_rounded, size: 14, color: accent), const SizedBox(width: 4), Text(TimeOfDay.fromDateTime(task.dueAt!).format(context), style: TextStyle(fontSize: 11.5, color: s.onSurfaceVariant))], if (task.category.isNotEmpty) ...[const SizedBox(width: 9), Flexible(child: Text(task.category, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11.5, color: s.onSurfaceVariant)))]])), if (task.isFavorite) Icon(Icons.star_rounded, size: 19, color: s.primary), const Icon(Icons.chevron_right_rounded)])))); }
}

class _Overdue extends StatelessWidget { const _Overdue(this.count); final int count; @override Widget build(BuildContext context) { final s = Theme.of(context).colorScheme; return Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: s.errorContainer, borderRadius: BorderRadius.circular(16)), child: Row(children: [Icon(Icons.priority_high_rounded, color: s.error), const SizedBox(width: 9), Text('$count overdue ${count == 1 ? 'task' : 'tasks'}', style: TextStyle(color: s.onErrorContainer, fontWeight: FontWeight.w800)), const Spacer(), Icon(Icons.arrow_forward_rounded, color: s.error)])); } }
class _EmptyToday extends StatelessWidget { const _EmptyToday(this.onAdd); final VoidCallback onAdd; @override Widget build(BuildContext context) { final s = Theme.of(context).colorScheme; return Container(padding: const EdgeInsets.all(26), decoration: BoxDecoration(color: s.surfaceContainerHighest.withValues(alpha: .55), borderRadius: BorderRadius.circular(24)), child: Column(children: [Container(width: 58, height: 58, decoration: BoxDecoration(color: s.primaryContainer, shape: BoxShape.circle), child: Icon(Icons.done_all_rounded, color: s.primary, size: 29)), const SizedBox(height: 14), Text('Nothing on your schedule', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)), const SizedBox(height: 5), const Text('Your day is clear. Add something you want to accomplish.', textAlign: TextAlign.center), const SizedBox(height: 16), OutlinedButton.icon(onPressed: onAdd, icon: const Icon(Icons.add_rounded), label: const Text('Add task'))])); } }

class _Search extends StatefulWidget { const _Search({required this.store}); final TaskStore store; @override State<_Search> createState() => _SearchState(); }
class _SearchState extends State<_Search> { final _controller = TextEditingController(); String _query = ''; String _filter = 'All'; @override void dispose() { _controller.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) { final q = _query.trim().toLowerCase(); var results = widget.store.tasks.where((t) { final text = '${t.title} ${t.notes} ${t.category} ${t.tags.join(' ')}'.toLowerCase(); if (q.isNotEmpty && !text.contains(q)) return false; if (_filter == 'Active' && t.isCompleted) return false; if (_filter == 'Completed' && !t.isCompleted) return false; if (_filter == 'Favorites' && !t.isFavorite) return false; return true; }).toList(); results.sort((a,b) { if (a.isCompleted != b.isCompleted) return a.isCompleted ? 1 : -1; if (a.dueAt == null) return 1; if (b.dueAt == null) return -1; return a.dueAt!.compareTo(b.dueAt!); }); final s = Theme.of(context).colorScheme; return SafeArea(child: CustomScrollView(slivers: [SliverPadding(padding: const EdgeInsets.fromLTRB(22,22,22,14), sliver: SliverToBoxAdapter(child: Row(children: [Expanded(child: Text('Find anything', style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -1.4))), IconButton(onPressed: () => setState(() { _query=''; _controller.clear(); }), icon: const Icon(Icons.close_rounded))]))), SliverPadding(padding: const EdgeInsets.symmetric(horizontal:22), sliver: SliverToBoxAdapter(child: TextField(controller:_controller, onChanged:(v)=>setState(()=>_query=v), decoration: const InputDecoration(hintText:'Tasks, notes, tags…', prefixIcon:Icon(Icons.search_rounded))))), SliverPadding(padding: const EdgeInsets.fromLTRB(22,13,22,12), sliver: SliverToBoxAdapter(child: SingleChildScrollView(scrollDirection:Axis.horizontal, child: Row(children: ['All','Active','Completed','Favorites'].map((v)=>Padding(padding:const EdgeInsets.only(right:8), child:ChoiceChip(label:Text(v), selected:_filter==v, onSelected:(_)=>setState(()=>_filter=v))).toList())))), if(results.isEmpty) SliverFillRemaining(hasScrollBody:false, child:Center(child:Column(mainAxisSize:MainAxisSize.min, children:[Icon(Icons.search_off_rounded,size:42,color:s.onSurfaceVariant), const SizedBox(height:10), Text(q.isEmpty ? 'No tasks yet.' : 'No matching tasks.', style: const TextStyle(fontWeight:FontWeight.w700)), const SizedBox(height:5), const Text('Try another search or filter.')])) ) else SliverPadding(padding:const EdgeInsets.fromLTRB(22,4,22,100), sliver:SliverList.separated(itemCount:results.length,itemBuilder:(_,i)=>_TaskTile(task:results[i],store:widget.store),separatorBuilder:(_,__)=>const SizedBox(height:9))) ])); }
}
