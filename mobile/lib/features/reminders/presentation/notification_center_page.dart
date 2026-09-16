import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../data/local_notification_service.dart';
import '../data/notification_history_store.dart';
import '../../tasks/application/task_store.dart';
import '../../tasks/presentation/task_detail_page.dart';

class NotificationCenterPage extends StatefulWidget {
  const NotificationCenterPage({super.key, required this.notifications, required this.taskStore});

  final LocalNotificationService notifications;
  final TaskStore taskStore;

  @override
  State<NotificationCenterPage> createState() => _NotificationCenterPageState();
}

class _NotificationCenterPageState extends State<NotificationCenterPage> {
  final _history = NotificationHistoryStore();
  List<NotificationHistoryEntry> _recent = const [];
  List<PendingNotificationRequest> _upcoming = const [];
  List<ActiveNotification> _active = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    try {
      final now = DateTime.now();
      final entries = await _history.load();
      final pending = await widget.notifications.pendingNotifications();
      final active = await widget.notifications.activeNotifications();
      if (!mounted) return;
      setState(() {
        _recent = entries.where((entry) => !entry.occurredAt.isAfter(now) && now.difference(entry.occurredAt) <= const Duration(days: 7)).take(100).toList();
        _upcoming = pending.toList()..sort((a, b) => a.id.compareTo(b.id));
        _active = active;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _clearHistory() async {
    await _history.clear();
    await _refresh();
  }

  void _openPayload(String? payload) {
    if (payload == null || payload.isEmpty || payload.startsWith('routine:')) return;
    Task? task;
    for (final item in widget.taskStore.tasks) {
      if (item.id == payload) {
        task = item;
        break;
      }
    }
    if (task == null || !mounted) return;
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => TaskDetailPage(store: widget.taskStore, task: task!)));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          IconButton(onPressed: _loading ? null : _refresh, tooltip: 'Refresh', icon: const Icon(Icons.refresh_rounded)),
          PopupMenuButton<String>(
            onSelected: (value) { if (value == 'clear') _clearHistory(); },
            itemBuilder: (_) => const [PopupMenuItem(value: 'clear', child: Text('Clear recent history'))],
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  if (_active.isNotEmpty) ...[
                    _SectionTitle(title: 'Active now', count: _active.length),
                    ..._active.map((item) => _NotificationTile(title: item.title ?? 'Notification', body: item.body ?? '', icon: Icons.notifications_active_rounded, onTap: () => _openPayload(item.payload))),
                    const SizedBox(height: 18),
                  ],
                  _SectionTitle(title: 'Recent reminder activity', count: _recent.length),
                  if (_recent.isEmpty)
                    _EmptyNotice(icon: Icons.notifications_none_rounded, title: 'No recent reminders', body: 'Task and routine reminders will appear here after their scheduled time passes.')
                  else
                    ..._recent.map((entry) => _NotificationTile(title: entry.title, body: entry.body, icon: entry.kind == 'Routine' ? Icons.repeat_rounded : Icons.task_alt_rounded, trailing: _timeLabel(entry.occurredAt), onTap: () => _openPayload(entry.payload))),
                  const SizedBox(height: 18),
                  _SectionTitle(title: 'Upcoming', count: _upcoming.length),
                  if (_upcoming.isEmpty)
                    _EmptyNotice(icon: Icons.event_available_rounded, title: 'Nothing scheduled', body: 'New reminders will appear here when you create them.')
                  else
                    ..._upcoming.take(30).map((item) => _NotificationTile(title: item.title ?? 'Notification', body: item.body ?? '', icon: Icons.schedule_rounded, trailing: 'Scheduled', onTap: () => _openPayload(item.payload))),
                  const SizedBox(height: 14),
                  Text('Recent activity is based on Todo reminders the app has scheduled. Android also keeps its own notification history when that device feature is enabled.', style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12, height: 1.4)),
                ],
              ),
            ),
    );
  }

  String _timeLabel(DateTime value) {
    final difference = DateTime.now().difference(value);
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.count});
  final String title;
  final int count;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 9),
        child: Row(children: [
          Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900))),
          Text('$count', style: Theme.of(context).textTheme.bodySmall),
        ]),
      );
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.title, required this.body, required this.icon, this.trailing, this.onTap});
  final String title;
  final String body;
  final IconData icon;
  final String? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: Container(width: 42, height: 42, decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: BorderRadius.circular(13)), child: Icon(icon, color: scheme.primary)),
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(body, maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: trailing == null ? null : Text(trailing!, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 11, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _EmptyNotice extends StatelessWidget {
  const _EmptyNotice({required this.icon, required this.title, required this.body});
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(children: [
            Icon(icon, size: 34, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 5),
            Text(body, textAlign: TextAlign.center),
          ]),
        ),
      );
}
