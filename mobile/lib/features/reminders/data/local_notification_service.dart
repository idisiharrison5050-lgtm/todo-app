import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  if (response.actionId == LocalNotificationService.snooze5Action || response.actionId == LocalNotificationService.snooze10Action || response.actionId == LocalNotificationService.snooze30Action) {
    unawaited(LocalNotificationService.scheduleSnoozeFromBackground(response));
  }
}

class LocalNotificationService {
  LocalNotificationService({FlutterLocalNotificationsPlugin? plugin}) : _plugin = plugin ?? FlutterLocalNotificationsPlugin();
  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;
  static void Function(String taskId)? onNotificationTap;
  static void Function(String taskId, int minutes)? onSnoozeRequested;
  static const String snooze5Action = 'snooze_5';
  static const String snooze10Action = 'snooze_10';
  static const String snooze30Action = 'snooze_30';

  static int _snoozeNotificationId(String taskId) {
    var hash = 0x811c9dc5;
    final value = '$taskId:99';
    for (final codeUnit in value.codeUnits) { hash ^= codeUnit; hash = (hash * 0x01000193) & 0x7fffffff; }
    return hash == 0 ? 1 : hash;
  }

  static int _minutesForAction(String actionId) {
    switch (actionId) {
      case snooze5Action: return 5;
      case snooze10Action: return 10;
      case snooze30Action: return 30;
      default: return 0;
    }
  }

  @pragma('vm:entry-point')
  static Future<void> scheduleSnoozeFromBackground(NotificationResponse response) async {
    final taskId = response.payload;
    final minutes = _minutesForAction(response.actionId ?? '');
    if (taskId == null || taskId.isEmpty || minutes <= 0) return;
    tz.initializeTimeZones();
    try {
      final timezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezone.identifier));
    } catch (_) {}
    final plugin = FlutterLocalNotificationsPlugin();
    await plugin.initialize(settings: const InitializationSettings(android: AndroidInitializationSettings('@mipmap/ic_launcher')));
    final android = plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(const AndroidNotificationChannel('todo_reminders', 'Task reminders', description: 'Reminders for scheduled tasks', importance: Importance.high));
    final scheduled = tz.TZDateTime.now(tz.local).add(Duration(minutes: minutes));
    await plugin.cancel(id: _snoozeNotificationId(taskId));
    final details = NotificationDetails(android: AndroidNotificationDetails('todo_reminders', 'Task reminders', channelDescription: 'Reminders for scheduled tasks', importance: Importance.max, priority: Priority.max, playSound: true, enableVibration: true, category: AndroidNotificationCategory.reminder, visibility: NotificationVisibility.public, actions: <AndroidNotificationAction>[AndroidNotificationAction(snooze5Action, '5 min'), AndroidNotificationAction(snooze10Action, '10 min'), AndroidNotificationAction(snooze30Action, '30 min')]), iOS: const DarwinNotificationDetails(categoryIdentifier: 'todo_reminder'));
    final exactAllowed = await android?.canScheduleExactNotifications() ?? false;
    try {
      await plugin.zonedSchedule(id: _snoozeNotificationId(taskId), title: 'Task reminder', body: 'Snoozed reminder.', scheduledDate: scheduled, notificationDetails: details, payload: taskId, androidScheduleMode: exactAllowed ? AndroidScheduleMode.exactAllowWhileIdle : AndroidScheduleMode.inexactAllowWhileIdle);
    } on PlatformException {
      await plugin.zonedSchedule(id: _snoozeNotificationId(taskId), title: 'Task reminder', body: 'Snoozed reminder.', scheduledDate: scheduled, notificationDetails: details, payload: taskId, androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle);
    }
  }

  Future<void> initialize() async {
    if (_initialized || kIsWeb) return;
    tz.initializeTimeZones();
    try {
      final timezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezone.identifier));
    } catch (_) {}
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    final darwin = DarwinInitializationSettings(requestAlertPermission: false, requestBadgePermission: false, requestSoundPermission: false, notificationCategories: <DarwinNotificationCategory>[DarwinNotificationCategory('todo_reminder', actions: <DarwinNotificationAction>[DarwinNotificationAction.plain(snooze5Action, '5 min'), DarwinNotificationAction.plain(snooze10Action, '10 min'), DarwinNotificationAction.plain(snooze30Action, '30 min')])]);
    await _plugin.initialize(settings: InitializationSettings(android: android, iOS: darwin, macOS: darwin), onDidReceiveNotificationResponse: (response) {
      final taskId = response.payload;
      if (taskId == null || taskId.isEmpty) return;
      switch (response.actionId) {
        case snooze5Action: onSnoozeRequested?.call(taskId, 5); return;
        case snooze10Action: onSnoozeRequested?.call(taskId, 10); return;
        case snooze30Action: onSnoozeRequested?.call(taskId, 30); return;
        default: onNotificationTap?.call(taskId);
      }
    }, onDidReceiveBackgroundNotificationResponse: notificationTapBackground);
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(const AndroidNotificationChannel('todo_reminders', 'Task reminders', description: 'Reminders for scheduled tasks', importance: Importance.high));
    _initialized = true;
  }

  Future<String?> getLaunchTaskId() async {
    if (kIsWeb) return null;
    await initialize();
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp != true) return null;
    final payload = details?.notificationResponse?.payload;
    return payload == null || payload.isEmpty ? null : payload;
  }

  Future<bool> requestPermissions() async {
    if (kIsWeb) return false;
    await initialize();
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    final androidGranted = await android?.requestNotificationsPermission();
    final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    final iosGranted = await ios?.requestPermissions(alert: true, badge: true, sound: true);
    final androidEnabled = await android?.areNotificationsEnabled();
    return (androidGranted ?? androidEnabled ?? false) || (iosGranted ?? false);
  }

  Future<bool> canScheduleExactNotifications() async {
    if (kIsWeb) return false;
    await initialize();
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    return await android?.canScheduleExactNotifications() ?? false;
  }

  Future<bool> requestExactAlarmPermission() async {
    if (kIsWeb) return false;
    await initialize();
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (await android?.canScheduleExactNotifications() ?? false) return true;
    return await android?.requestExactAlarmsPermission() ?? false;
  }

  Future<void> scheduleOneTime({required int id, required String title, required String body, required DateTime scheduledAt, String? timeZone, String? payload, bool includeSnoozeActions = true}) async {
    await initialize();
    if (kIsWeb) return;
    final scheduled = _preserveDelay(scheduledAt);
    if (!scheduled.isAfter(tz.TZDateTime.now(tz.local))) return;
    final details = NotificationDetails(android: AndroidNotificationDetails('todo_reminders', 'Task reminders', channelDescription: 'Reminders for scheduled tasks', importance: Importance.max, priority: Priority.max, playSound: true, enableVibration: true, category: AndroidNotificationCategory.reminder, visibility: NotificationVisibility.public, actions: includeSnoozeActions ? <AndroidNotificationAction>[const AndroidNotificationAction(snooze5Action, '5 min'), const AndroidNotificationAction(snooze10Action, '10 min'), const AndroidNotificationAction(snooze30Action, '30 min')] : const <AndroidNotificationAction>[]), iOS: const DarwinNotificationDetails(categoryIdentifier: 'todo_reminder'));
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    final exactAllowed = await android?.canScheduleExactNotifications() ?? false;
    try {
      await _plugin.zonedSchedule(id: id, title: title, body: body, scheduledDate: scheduled, notificationDetails: details, payload: payload, androidScheduleMode: exactAllowed ? AndroidScheduleMode.exactAllowWhileIdle : AndroidScheduleMode.inexactAllowWhileIdle);
    } on PlatformException {
      await _plugin.zonedSchedule(id: id, title: title, body: body, scheduledDate: scheduled, notificationDetails: details, payload: payload, androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle);
    }
  }

  Future<void> cancel(int id) async { if (kIsWeb) return; await initialize(); await _plugin.cancel(id: id); }
  Future<void> cancelAll() async { if (kIsWeb) return; await initialize(); await _plugin.cancelAll(); }
  tz.TZDateTime _preserveDelay(DateTime scheduledAt) => tz.TZDateTime.now(tz.local).add(scheduledAt.difference(DateTime.now()));
}
