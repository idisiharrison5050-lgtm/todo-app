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

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  Future<void> _next() async {
    if (_page < 2) {
      await _controller.animateToPage(_page + 1, duration: const Duration(milliseconds: 360), curve: Curves.easeOutCubic);
      return;
    }
    widget.onComplete();
  }

  Future<void> _enableNotifications() async {
    if (_requesting) return;
    setState(() => _requesting = true);
    try { await widget.notifications.requestPermissions(); }
    finally { if (mounted) setState(() => _requesting = false); }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 18, 14, 8),
            child: Row(children: [
              Container(width: 42, height: 42, decoration: BoxDecoration(color: scheme.primary, borderRadius: BorderRadius.circular(14)), child: Icon(Icons.check_rounded, color: scheme.onPrimary, size: 24)),
              const SizedBox(width: 11),
              Text('Todo', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
              const Spacer(),
              if (_page < 2) TextButton(onPressed: widget.onComplete, child: const Text('Skip')),
            ]),
          ),
          Expanded(
            child: PageView(
              controller: _controller,
              onPageChanged: (value) => setState(() => _page = value),
              children: [
                _Slide(icon: Icons.auto_awesome_rounded, eyebrow: 'A calmer way to plan', title: 'Turn a busy day into a clear plan.', body: 'Capture tasks, give them a moment, and let Todo keep the details organized for you.', scheme: scheme),
                _Slide(icon: Icons.sync_rounded, eyebrow: 'Your workspace follows you', title: 'Stay in sync, even when life goes offline.', body: 'Work locally when your connection disappears. Changes are queued safely and synced when you are back online.', scheme: scheme),
                _Slide(
                  icon: Icons.notifications_active_rounded,
                  eyebrow: 'Never miss the important stuff',
                  title: 'Reminders that actually show up.',
                  body: 'Allow notifications so scheduled tasks can reach you at the right time. You can change this later in Settings.',
                  scheme: scheme,
                  action: OutlinedButton.icon(
                    onPressed: _requesting ? null : _enableNotifications,
                    icon: _requesting ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.notifications_active_outlined),
                    label: Text(_requesting ? 'Requesting permission…' : 'Enable notifications'),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 10, 24, 28),
            child: Row(children: [
              Row(children: List.generate(3, (index) {
                final active = index == _page;
                return AnimatedContainer(duration: const Duration(milliseconds: 220), margin: const EdgeInsets.only(right: 6), width: active ? 24 : 7, height: 7, decoration: BoxDecoration(color: active ? scheme.primary : scheme.outlineVariant, borderRadius: BorderRadius.circular(10)));
              })),
              const Spacer(),
              FilledButton.icon(onPressed: _next, icon: Icon(_page == 2 ? Icons.check_rounded : Icons.arrow_forward_rounded), label: Text(_page == 2 ? 'Let’s go' : 'Continue')),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _Slide extends StatelessWidget {
  const _Slide({required this.icon, required this.eyebrow, required this.title, required this.body, required this.scheme, this.action});
  final IconData icon;
  final String eyebrow;
  final String title;
  final String body;
  final ColorScheme scheme;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 18, 28, 10),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(width: 116, height: 116, decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [scheme.primary, scheme.tertiary]), borderRadius: BorderRadius.circular(38), boxShadow: [BoxShadow(color: scheme.primary.withValues(alpha: .2), blurRadius: 35, offset: const Offset(0, 16))]), child: Icon(icon, color: scheme.onPrimary, size: 52)),
        const SizedBox(height: 34),
        Text(eyebrow.toUpperCase(), textAlign: TextAlign.center, style: theme.textTheme.labelMedium?.copyWith(letterSpacing: 1.4, fontWeight: FontWeight.w900, color: scheme.primary)),
        const SizedBox(height: 12),
        Text(title, textAlign: TextAlign.center, style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -1.4, height: 1.05)),
        const SizedBox(height: 14),
        ConstrainedBox(constraints: const BoxConstraints(maxWidth: 460), child: Text(body, textAlign: TextAlign.center, style: theme.textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant, height: 1.55))),
        if (action != null) ...[const SizedBox(height: 24), action!],
      ]),
    );
  }
}
