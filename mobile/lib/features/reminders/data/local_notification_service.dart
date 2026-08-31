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

  Future<void> initialize() async {
    if (_initialized || kIsWeb) return;
    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      settings: InitializationSettings(android: android, iOS: darwin, macOS: darwin),
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

  Future<void> openNotificationSettings() async {
    if (kIsWeb) return;
    await initialize();
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await android?.openNotificationSettings();
  }

  Future<void> scheduleOneTime({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledAt,
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
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'todo_reminders',
          'Task reminders',
          channelDescription: 'Reminders for scheduled tasks',
          importance: Importance.max,
          priority: Priority.max,
          playSound: true,
          enableVibration: true,
          category: AndroidNotificationCategory.alarm,
          visibility: NotificationVisibility.public,
        ),
        iOS: DarwinNotificationDetails(),
      ),
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
