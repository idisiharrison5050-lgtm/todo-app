class Routine {
  const Routine({
    required this.id,
    required this.title,
    this.body = '',
    required this.startMinutes,
    required this.endMinutes,
    required this.intervalMinutes,
    this.days = const <int>[1, 2, 3, 4, 5, 6, 7],
    this.enabled = true,
    this.createdAt,
  });

  final String id;
  final String title;
  final String body;
  final int startMinutes;
  final int endMinutes;
  final int intervalMinutes;
  final List<int> days;
  final bool enabled;
  final DateTime? createdAt;

  Routine copyWith({
    String? title,
    String? body,
    int? startMinutes,
    int? endMinutes,
    int? intervalMinutes,
    List<int>? days,
    bool? enabled,
  }) => Routine(
        id: id,
        title: title ?? this.title,
        body: body ?? this.body,
        startMinutes: startMinutes ?? this.startMinutes,
        endMinutes: endMinutes ?? this.endMinutes,
        intervalMinutes: intervalMinutes ?? this.intervalMinutes,
        days: days ?? this.days,
        enabled: enabled ?? this.enabled,
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'startMinutes': startMinutes,
        'endMinutes': endMinutes,
        'intervalMinutes': intervalMinutes,
        'days': days,
        'enabled': enabled,
        'createdAt': createdAt?.toIso8601String(),
      };

  factory Routine.fromJson(Map<String, dynamic> json) => Routine(
        id: json['id'] as String,
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        startMinutes: json['startMinutes'] as int? ?? 480,
        endMinutes: json['endMinutes'] as int? ?? 1320,
        intervalMinutes: json['intervalMinutes'] as int? ?? 120,
        days: json['days'] is List ? (json['days'] as List).whereType<int>().toList() : const <int>[1, 2, 3, 4, 5, 6, 7],
        enabled: json['enabled'] as bool? ?? true,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
      );

  String get intervalLabel {
    if (intervalMinutes % 60 == 0) {
      final hours = intervalMinutes ~/ 60;
      return 'Every $hours hour${hours == 1 ? '' : 's'}';
    }
    return 'Every $intervalMinutes minutes';
  }

  String get timeWindowLabel => '${_formatMinutes(startMinutes)} – ${_formatMinutes(endMinutes)}';
}

String _formatMinutes(int minutes) {
  final hour = (minutes ~/ 60).clamp(0, 23);
  final minute = minutes.remainder(60).clamp(0, 59);
  final period = hour >= 12 ? 'PM' : 'AM';
  final displayHour = hour % 12 == 0 ? 12 : hour % 12;
  return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
}
