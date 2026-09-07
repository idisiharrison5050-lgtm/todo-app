import 'package:flutter/material.dart';
import '../../reminders/data/local_notification_service.dart';

class FirstRunOnboardingPage extends StatefulWidget {
  const FirstRunOnboardingPage({super.key, required this.notifications, required this.onComplete});
  final LocalNotificationService notifications;
  final VoidCallback onComplete;

  @override
  State<FirstRunOnboardingPage> createState() => _FirstRunOnboardingPageState();
}

class _FirstRunOnboardingPageState extends State<FirstRunOnboardingPage> {
  final _controller = PageController();
  int _page = 0;
  bool _requesting = false;
  bool? _notificationEnabled;
  bool? _exactAlarmEnabled;

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  Future<void> _next() async {
    if (_page < 2) {
      await _controller.animateToPage(_page + 1, duration: const Duration(milliseconds: 420), curve: Curves.easeOutCubic);
    } else {
      widget.onComplete();
    }
  }

  Future<void> _enableNotifications() async {
    if (_requesting) return;
    setState(() => _requesting = true);
    try {
      final granted = await widget.notifications.requestPermissions();
      var exact = _exactAlarmEnabled;
      if (granted) exact = await widget.notifications.canScheduleExactNotifications();
      if (mounted) setState(() { _notificationEnabled = granted; _exactAlarmEnabled = exact; });
    } finally {
      if (mounted) setState(() => _requesting = false);
    }
  }

  Future<void> _enableExactAlarms() async {
    if (_requesting) return;
    setState(() => _requesting = true);
    try {
      final granted = await widget.notifications.requestExactAlarmPermission();
      if (mounted) setState(() => _exactAlarmEnabled = granted);
    } catch (_) {
      if (mounted) setState(() => _exactAlarmEnabled = false);
    } finally {
      if (mounted) setState(() => _requesting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 14, 8),
              child: Row(children: [
                Container(width: 43, height: 43, decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [scheme.primary, scheme.tertiary]), borderRadius: BorderRadius.circular(14)), child: Icon(Icons.check_rounded, color: scheme.onPrimary, size: 25)),
                const SizedBox(width: 11),
                Text('Todo', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                const Spacer(),
                Text('${_page + 1} / 3', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800, color: scheme.onSurfaceVariant)),
                if (_page < 2) ...[const SizedBox(width: 8), TextButton(onPressed: widget.onComplete, child: const Text('Skip'))],
              ]),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (value) => setState(() => _page = value),
                children: [
                  _Slide(icon: Icons.auto_awesome_rounded, eyebrow: 'A calmer way to plan', title: 'Turn a busy day into a clear plan.', body: 'Capture tasks, give them a moment, and let Todo keep the details organized for you.', scheme: scheme, features: const ['Fast task capture', 'Today and upcoming views', 'Priorities, categories and favorites']),
                  _Slide(icon: Icons.sync_rounded, eyebrow: 'Your workspace follows you', title: 'Stay productive, even when life goes offline.', body: 'Work locally when your connection disappears. Changes are queued safely and synced when you are back online.', scheme: scheme, features: const ['Offline-first task capture', 'Automatic sync when connected', 'Account-scoped workspace']),
                  _Slide(icon: Icons.notifications_active_rounded, eyebrow: 'Never miss the important stuff', title: 'Set up reminders before you start.', body: 'Allow notifications so scheduled tasks can reach you at the right time. Precise alarm access can improve timing on supported Android devices.', scheme: scheme, action: Column(children: [SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: _requesting ? null : _enableNotifications, icon: _requesting ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : Icon(_notificationEnabled == true ? Icons.check_rounded : Icons.notifications_active_outlined), label: Text(_requesting ? 'Requesting permission…' : _notificationEnabled == true ? 'Notifications enabled' : 'Enable notifications'))), if (_notificationEnabled == true) ...[const SizedBox(height: 9), SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: _requesting || _exactAlarmEnabled == true ? null : _enableExactAlarms, icon: Icon(_exactAlarmEnabled == true ? Icons.verified_rounded : Icons.alarm_on_outlined), label: Text(_exactAlarmEnabled == true ? 'Precise alarms enabled' : 'Enable precise alarms'))), const SizedBox(height: 8), Text(_exactAlarmEnabled == true ? 'Reminder timing is configured for precision.' : 'Optional: Android may use less precise timing without this access.', textAlign: TextAlign.center, style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant))]])),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 10, 24, 28),
              child: Row(children: [
                Row(children: List.generate(3, (index) { final active = index == _page; return AnimatedContainer(duration: const Duration(milliseconds: 240), margin: const EdgeInsets.only(right: 6), width: active ? 25 : 7, height: 7, decoration: BoxDecoration(color: active ? scheme.primary : scheme.outlineVariant, borderRadius: BorderRadius.circular(10))); })),
                const Spacer(),
                FilledButton.icon(onPressed: _next, icon: Icon(_page == 2 ? Icons.check_rounded : Icons.arrow_forward_rounded), label: Text(_page == 2 ? 'Start planning' : 'Continue')),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _Slide extends StatelessWidget {
  const _Slide({required this.icon, required this.eyebrow, required this.title, required this.body, required this.scheme, this.features = const [], this.action});
  final IconData icon;
  final String eyebrow;
  final String title;
  final String body;
  final ColorScheme scheme;
  final List<String> features;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(25, 18, 25, 18),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 390),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(width: 112, height: 112, decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [scheme.primary, scheme.tertiary]), borderRadius: BorderRadius.circular(36), boxShadow: [BoxShadow(color: scheme.primary.withValues(alpha: .20), blurRadius: 38, offset: const Offset(0, 17))]), child: Icon(icon, color: scheme.onPrimary, size: 50)),
            const SizedBox(height: 24),
            Text(eyebrow.toUpperCase(), textAlign: TextAlign.center, style: theme.textTheme.labelMedium?.copyWith(letterSpacing: 1.5, fontWeight: FontWeight.w900, color: scheme.primary)),
            const SizedBox(height: 10),
            Text(title, textAlign: TextAlign.center, style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -1.5, height: 1.06)),
            const SizedBox(height: 12),
            ConstrainedBox(constraints: const BoxConstraints(maxWidth: 480), child: Text(body, textAlign: TextAlign.center, style: theme.textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant, height: 1.45))),
            if (features.isNotEmpty) ...[
              const SizedBox(height: 17),
              ConstrainedBox(constraints: const BoxConstraints(maxWidth: 420), child: Container(padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10), decoration: BoxDecoration(color: scheme.surfaceContainerLow, borderRadius: BorderRadius.circular(18), border: Border.all(color: scheme.outlineVariant.withValues(alpha: .7))), child: Column(children: features.map((feature) => Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Row(children: [Icon(Icons.check_circle_rounded, size: 17, color: scheme.primary), const SizedBox(width: 9), Expanded(child: Text(feature, style: const TextStyle(fontWeight: FontWeight.w700)))]))).toList()))),
            ],
            if (action != null) ...[const SizedBox(height: 18), action!],
          ],
        ),
      ),
    );
  }
}
