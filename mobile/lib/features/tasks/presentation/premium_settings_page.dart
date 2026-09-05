import 'package:flutter/material.dart';

import '../../auth/application/auth_store.dart';
import '../../reminders/data/local_notification_service.dart';
import '../application/task_store.dart';

class SettingsScope extends InheritedWidget {
  const SettingsScope({super.key, required this.store, required this.authStore, required this.notifications, required this.themeMode, required this.onThemeModeChanged, required super.child});
  final TaskStore store;
  final AuthStore authStore;
  final LocalNotificationService notifications;
  final ThemeMode themeMode;
  final Future<void> Function(ThemeMode mode) onThemeModeChanged;

  static SettingsScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<SettingsScope>();
    assert(scope != null, 'SettingsScope is missing above this widget.');
    return scope!;
  }

  @override
  bool updateShouldNotify(SettingsScope oldWidget) => store != oldWidget.store || authStore != oldWidget.authStore || notifications != oldWidget.notifications || themeMode != oldWidget.themeMode;
}

class PremiumSettingsPage extends StatefulWidget {
  const PremiumSettingsPage({super.key, required this.onLogout});
  final Future<void> Function() onLogout;
  @override State<PremiumSettingsPage> createState() => _PremiumSettingsPageState();
}

class _PremiumSettingsPageState extends State<PremiumSettingsPage> {
  bool _busy = false;
  bool? _notificationsEnabled;
  bool? _exactAlarmsEnabled;

  @override
  void initState() {
    super.initState();
    _refreshDeviceStatus();
  }

  Future<void> _refreshDeviceStatus() async {
    try {
      final notifications = SettingsScope.of(context).notifications;
      final enabled = await notifications.areNotificationsEnabled();
      final exact = await notifications.canScheduleExactNotifications();
      if (mounted) setState(() { _notificationsEnabled = enabled; _exactAlarmsEnabled = exact; });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final scope = SettingsScope.of(context);
    final scheme = Theme.of(context).colorScheme;
    final user = scope.authStore.user;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 120),
        children: [
          Text('More', style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -1.4)),
          const SizedBox(height: 5),
          Text('Make the workspace yours.', style: TextStyle(color: scheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [scheme.primary, scheme.tertiary]), borderRadius: BorderRadius.circular(26)),
            child: Row(children: [
              Container(width: 52, height: 52, decoration: BoxDecoration(color: scheme.onPrimary.withValues(alpha: .16), shape: BoxShape.circle), child: Icon(Icons.auto_awesome_rounded, color: scheme.onPrimary)),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(user?.name.isNotEmpty == true ? 'Welcome, ${user!.name}' : 'Your workspace', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: scheme.onPrimary, fontSize: 18, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text('Focused, calm, and ready.', style: TextStyle(color: scheme.onPrimary.withValues(alpha: .78))),
              ])),
            ]),
          ),
          const SizedBox(height: 24),
          _Section(title: 'Workspace', children: [
            _SettingTile(icon: Icons.palette_outlined, title: 'Appearance', subtitle: _themeLabel(scope.themeMode), onTap: () => _showAppearance(context, scope)),
            _SettingTile(icon: Icons.notifications_none_rounded, title: 'Notifications', subtitle: _notificationSummary, onTap: () => _showNotifications(context, scope.notifications)),
            _SettingTile(icon: Icons.alarm_on_outlined, title: 'Exact reminders', subtitle: _exactAlarmSummary, onTap: () => _configureExactAlarms(context, scope.notifications)),
            _SettingTile(icon: Icons.sync_rounded, title: 'Sync & offline', subtitle: 'Refresh your workspace now', onTap: () => _syncNow(context, scope.store)),
            _SettingTile(icon: Icons.cleaning_services_outlined, title: 'Clear completed', subtitle: 'Remove completed tasks from this workspace', onTap: () => _clearCompleted(context, scope.store)),
          ]),
          const SizedBox(height: 18),
          _Section(title: 'Privacy & account', children: [
            _SettingTile(icon: Icons.lock_outline_rounded, title: 'Privacy', subtitle: 'Your task data is isolated to your account', onTap: () => _showPrivacy(context)),
            _SettingTile(icon: Icons.person_outline_rounded, title: 'Account', subtitle: user?.email.isNotEmpty == true ? user!.email : 'Signed-in account', onTap: () => _showAccount(context, scope.authStore)),
          ]),
          const SizedBox(height: 18),
          Card(child: ListTile(leading: Icon(Icons.logout_rounded, color: scheme.error), title: const Text('Log out', style: TextStyle(fontWeight: FontWeight.w800)), subtitle: const Text('Sign out of this device'), trailing: const Icon(Icons.chevron_right_rounded), onTap: _busy ? null : () => _confirmLogout(context))),
          const SizedBox(height: 18),
          Center(child: Text('Todo • Built for getting things done', style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12))),
        ],
      ),
    );
  }

  String get _notificationSummary {
    if (_notificationsEnabled == null) return 'Checking device permission…';
    return _notificationsEnabled! ? 'Enabled on this device' : 'Permission required';
  }

  String get _exactAlarmSummary {
    if (_exactAlarmsEnabled == null) return 'Checking alarm access…';
    return _exactAlarmsEnabled! ? 'Precise alarms enabled' : 'Android may deliver reminders less precisely';
  }

  String _themeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light: return 'Light theme';
      case ThemeMode.dark: return 'Dark theme';
      case ThemeMode.system: return 'Follow device theme';
    }
  }

  Future<void> _showAppearance(BuildContext context, SettingsScope scope) async {
    final selected = await showModalBottomSheet<ThemeMode>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const ListTile(title: Text('Appearance', style: TextStyle(fontWeight: FontWeight.w900))),
        _ThemeOption(mode: ThemeMode.system, label: 'System default', selected: scope.themeMode, onTap: () => Navigator.pop(sheetContext, ThemeMode.system)),
        _ThemeOption(mode: ThemeMode.light, label: 'Light', selected: scope.themeMode, onTap: () => Navigator.pop(sheetContext, ThemeMode.light)),
        _ThemeOption(mode: ThemeMode.dark, label: 'Dark', selected: scope.themeMode, onTap: () => Navigator.pop(sheetContext, ThemeMode.dark)),
        const SizedBox(height: 12),
      ])),
    );
    if (selected != null) await scope.onThemeModeChanged(selected);
  }

  Future<void> _showNotifications(BuildContext context, LocalNotificationService notifications) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const ListTile(leading: Icon(Icons.notifications_active_outlined), title: Text('Notifications', style: TextStyle(fontWeight: FontWeight.w900)), subtitle: Text('Control and test task alerts on this device.')),
        ListTile(leading: const Icon(Icons.verified_outlined), title: const Text('Request notification permission'), subtitle: const Text('Ask Android or iOS to allow Todo alerts'), onTap: () => Navigator.pop(sheetContext, 'permission')),
        ListTile(leading: const Icon(Icons.notification_add_outlined), title: const Text('Send test notification'), subtitle: const Text('Schedules a test alert about 5 seconds from now'), onTap: () => Navigator.pop(sheetContext, 'test')),
        const SizedBox(height: 12),
      ])),
    );
    if (!context.mounted || action == null) return;
    try {
      final granted = await notifications.requestPermissions();
      await _refreshDeviceStatus();
      if (!granted) {
        if (context.mounted) _showMessage(context, 'Notifications are not permitted on this device.');
        return;
      }
      if (action == 'test') {
        await notifications.scheduleOneTime(id: 987654321, title: 'Todo test notification', body: 'Notifications are working on this device.', scheduledAt: DateTime.now().add(const Duration(seconds: 5)), includeSnoozeActions: false);
        if (context.mounted) _showMessage(context, 'Test notification scheduled for about 5 seconds.');
      } else if (context.mounted) {
        _showMessage(context, 'Notifications are enabled.');
      }
    } catch (_) {
      if (context.mounted) _showMessage(context, 'Todo could not configure notifications on this device.');
    }
  }

  Future<void> _configureExactAlarms(BuildContext context, LocalNotificationService notifications) async {
    try {
      if (await notifications.canScheduleExactNotifications()) {
        if (context.mounted) _showMessage(context, 'Exact alarms are already enabled.');
        return;
      }
      final granted = await notifications.requestExactAlarmPermission();
      await _refreshDeviceStatus();
      if (context.mounted) _showMessage(context, granted ? 'Exact alarms are enabled.' : 'Exact alarm access was not granted. Reminders still use a safe fallback.');
    } catch (_) {
      if (context.mounted) _showMessage(context, 'Exact alarm access is unavailable on this device.');
    }
  }

  Future<void> _syncNow(BuildContext context, TaskStore store) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await store.reloadForAccount();
      if (context.mounted) _showMessage(context, 'Workspace refreshed. Pending changes will sync automatically.');
    } catch (_) {
      if (context.mounted) _showMessage(context, 'Sync could not complete. Your local tasks are still available.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _clearCompleted(BuildContext context, TaskStore store) async {
    final completed = store.tasks.where((task) => task.isCompleted).length;
    if (completed == 0) { _showMessage(context, 'There are no completed tasks to clear.'); return; }
    final confirmed = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(title: const Text('Clear completed tasks?'), content: Text('Remove $completed completed task${completed == 1 ? '' : 's'} from this workspace?'), actions: [TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Clear completed'))]));
    if (confirmed == true) { await store.clearCompleted(); if (context.mounted) _showMessage(context, 'Completed tasks cleared.'); }
  }

  Future<void> _showAccount(BuildContext context, AuthStore authStore) async {
    final user = authStore.user;
    await showDialog<void>(context: context, builder: (dialogContext) => AlertDialog(title: const Text('Account'), content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [Text(user?.name.isNotEmpty == true ? user!.name : 'Signed-in user', style: const TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 6), Text(user?.email.isNotEmpty == true ? user!.email : 'Account email unavailable'), const SizedBox(height: 14), const Text('Your tasks are stored against your authenticated account and are protected by server-side ownership checks.')]), actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Done'))]));
  }

  Future<void> _showPrivacy(BuildContext context) async {
    await showDialog<void>(context: context, builder: (dialogContext) => AlertDialog(title: const Text('Privacy'), content: const Text('Todo keeps task data scoped to the signed-in account. Local offline data is kept on the device so you can continue working without a connection. Notification actions only carry the task identifier needed to open or snooze the task.'), actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Done'))]));
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(title: const Text('Log out?'), content: const Text('You can sign back in whenever you are ready.'), actions: [TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Log out'))]));
    if (confirmed == true) await widget.onLogout();
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)..hideCurrentSnackBar()..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({required this.mode, required this.label, required this.selected, required this.onTap});
  final ThemeMode mode;
  final String label;
  final ThemeMode selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(switch (mode) { ThemeMode.system => Icons.brightness_auto_outlined, ThemeMode.light => Icons.light_mode_outlined, ThemeMode.dark => Icons.dark_mode_outlined }),
    title: Text(label), trailing: mode == selected ? const Icon(Icons.check_rounded) : null, onTap: onTap,
  );
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});
  final String title;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Padding(padding: const EdgeInsets.only(left: 4, bottom: 8), child: Text(title, style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900))),
    Card(child: Column(children: [for (var i = 0; i < children.length; i++) ...[children[i], if (i != children.length - 1) const Divider(height: 1, indent: 64)]])),
  ]);
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({required this.icon, required this.title, required this.subtitle, required this.onTap});
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
    leading: Container(width: 42, height: 42, decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer, borderRadius: BorderRadius.circular(13)), child: Icon(icon, color: Theme.of(context).colorScheme.primary)),
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)), subtitle: Text(subtitle), trailing: const Icon(Icons.chevron_right_rounded), onTap: onTap,
  );
}
