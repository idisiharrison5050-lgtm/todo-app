import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class NotificationHistoryEntry {
  const NotificationHistoryEntry({required this.key, required this.title, required this.body, required this.kind, required this.occurredAt, this.payload});

  final String key;
  final String title;
  final String body;
  final String kind;
  final DateTime occurredAt;
  final String? payload;

  Map<String, dynamic> toJson() => {
        'key': key,
        'title': title,
        'body': body,
        'kind': kind,
        'occurredAt': occurredAt.toIso8601String(),
        'payload': payload,
      };

  factory NotificationHistoryEntry.fromJson(Map<String, dynamic> json) => NotificationHistoryEntry(
        key: json['key'] as String? ?? '',
        title: json['title'] as String? ?? 'Notification',
        body: json['body'] as String? ?? '',
        kind: json['kind'] as String? ?? 'Reminder',
        occurredAt: DateTime.tryParse(json['occurredAt'] as String? ?? '') ?? DateTime.now(),
        payload: json['payload'] as String?,
      );
}

class NotificationHistoryStore {
  static const _storageKey = 'todo_notification_history_v1';
  static const _maxEntries = 200;

  Future<List<NotificationHistoryEntry>> load() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getStringList(_storageKey) ?? const <String>[];
    return raw
        .map((item) {
          try {
            return NotificationHistoryEntry.fromJson(jsonDecode(item) as Map<String, dynamic>);
          } catch (_) {
            return null;
          }
        })
        .whereType<NotificationHistoryEntry>()
        .toList()
      ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
  }

  Future<void> record({required int notificationId, required String title, required String body, required DateTime scheduledAt, String? payload}) async {
    final preferences = await SharedPreferences.getInstance();
    final entries = await load();
    final kind = payload?.startsWith('routine:') == true ? 'Routine' : 'Task reminder';
    final key = '$notificationId|${scheduledAt.toIso8601String()}|$kind';
    if (entries.any((entry) => entry.key == key)) return;
    entries.insert(0, NotificationHistoryEntry(key: key, title: title, body: body, kind: kind, occurredAt: scheduledAt, payload: payload));
    final trimmed = entries.take(_maxEntries).map((entry) => jsonEncode(entry.toJson())).toList();
    await preferences.setStringList(_storageKey, trimmed);
  }

  Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_storageKey);
  }
}
