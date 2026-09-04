import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// OS-level notification adapter for task reminders.
class LocalNotificationService {
  LocalNotificationService({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  /// Set by the app so tapping a notification can open its task.
  static void Function(String taskId)? onNotificationTap;

  /// Set by the reminder scheduler so notification actions can snooze a task.
  static void Function(String taskId, int minutes)? onSnoozeRequested;

  static const String snooze5Action = 'snooze_5';
  static const String snooze10Action = 'snooze_10';
  static const String snooze30Action = 'snooze_30';

  Future<void> initialize() async {
    if (_initialized || kIsWeb) return;
    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      notificationCategories: <DarwinNotificationCategory>[
        DarwinNotificationCategory(
          'todo_reminder',
          actions: <DarwinNotificationAction>[
            DarwinNotificationAction.plain(snooze5Action, '5 min'),
            DarwinNotificationAction.plain(snooze10Action, '10 min'),
            DarwinNotificationAction.plain(snooze30Action, '30 min'),
          ],
        ),
      ],
    );

    await _plugin.initialize(
      settings: InitializationSettings(android: android, iOS: darwin, macOS: darwin),
      onDidReceiveNotificationResponse: (response) {
        final taskId = response.payload;
        if (taskId == null || taskId.isEmpty) return;

        switch (response.actionId) {
          case snooze5Action:
            onSnoozeRequested?.call(taskId, 5);
            return;
          case snooze10Action:
            onSnoozeRequested?.call(taskId, 10);
            return;
          case snooze30Action:
            onSnoozeRequested?.call(taskId, 30);
            return;
          default:
            onNotificationTap?.call(taskId);
        }
      },
    );

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        'todo_reminders',
        'Task reminders',
        description: 'Reminders for scheduled tasks',
        importance: Importance.high,
      ),
    );
    _initialized = true;
  }

  Future<bool> requestPermissions() async {
    if (kIsWeb) return false;
    await initialize();

    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    final androidGranted = await android?.requestNotificationsPermission();
    await android?.requestExactAlarmsPermission();

    final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    final iosGranted = await ios?.requestPermissions(alert: true, badge: true, sound: true);

    return (androidGranted ?? false) || (iosGranted ?? false);
  }

  Future<void> scheduleOneTime({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledAt,
    String? payload,
    bool includeSnoozeActions = true,
  }) async {
    await initialize();
    if (kIsWeb) return;

    final minute = DateTime(scheduledAt.year, scheduledAt.month, scheduledAt.day, scheduledAt.hour, scheduledAt.minute);
    final scheduled = tz.TZDateTime.from(minute, tz.local);
    if (!scheduled.isAfter(tz.TZDateTime.now(tz.local))) return;

    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduled,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'todo_reminders',
          'Task reminders',
          channelDescription: 'Reminders for scheduled tasks',
          importance: Importance.max,
          priority: Priority.max,
          playSound: true,
          enableVibration: true,
          category: AndroidNotificationCategory.reminder,
          visibility: NotificationVisibility.public,
          actions: includeSnoozeActions
              ? <AndroidNotificationAction>[
                  const AndroidNotificationAction(snooze5Action, '5 min', showsUserInterface: true),
                  const AndroidNotificationAction(snooze10Action, '10 min', showsUserInterface: true),
                  const AndroidNotificationAction(snooze30Action, '30 min', showsUserInterface: true),
                ]
              : const <AndroidNotificationAction>[],
        ),
        iOS: const DarwinNotificationDetails(categoryIdentifier: 'todo_reminder'),
      ),
      payload: payload,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> cancel(int id) async {
    if (kIsWeb) return;
    await initialize();
    await _plugin.cancel(id: id);
  }

  Future<void> cancelAll() async {
    if (kIsWeb) return;
    await initialize();
    await _plugin.cancelAll();
  }
}
