import 'package:flutter/material.dart';

class PremiumSettingsPage extends StatelessWidget {
  const PremiumSettingsPage({super.key, required this.onLogout});

  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
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
            decoration: BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [scheme.primary, scheme.tertiary]),
              borderRadius: BorderRadius.circular(26),
            ),
            child: Row(children: [
              Container(width: 52, height: 52, decoration: BoxDecoration(color: scheme.onPrimary.withValues(alpha: .16), shape: BoxShape.circle), child: Icon(Icons.auto_awesome_rounded, color: scheme.onPrimary)),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Your workspace', style: TextStyle(color: scheme.onPrimary, fontSize: 18, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text('Focused, calm, and ready.', style: TextStyle(color: scheme.onPrimary.withValues(alpha: .78))),
              ])),
            ]),
          ),
          const SizedBox(height: 24),
          _Section(title: 'Workspace', children: [
            _SettingTile(icon: Icons.palette_outlined, title: 'Appearance', subtitle: 'Follows your device theme'),
            _SettingTile(icon: Icons.notifications_none_rounded, title: 'Notifications', subtitle: 'Reminders and task alerts'),
            _SettingTile(icon: Icons.sync_rounded, title: 'Sync & offline', subtitle: 'Your changes stay safe offline'),
          ]),
          const SizedBox(height: 18),
          _Section(title: 'Privacy & account', children: [
            _SettingTile(icon: Icons.lock_outline_rounded, title: 'Privacy', subtitle: 'Control what appears in notifications'),
            _SettingTile(icon: Icons.person_outline_rounded, title: 'Account', subtitle: 'Manage your signed-in session'),
          ]),
          const SizedBox(height: 18),
          Card(child: ListTile(
            leading: Icon(Icons.logout_rounded, color: scheme.error),
            title: const Text('Log out', style: TextStyle(fontWeight: FontWeight.w800)),
            subtitle: const Text('Sign out of this device'),
            onTap: () => _confirmLogout(context),
          )),
          const SizedBox(height: 18),
          Center(child: Text('Todo • Built for getting things done', style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12))),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You can sign back in whenever you are ready.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Log out')),
        ],
      ),
    );
    if (confirmed == true) await onLogout();
  }
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
  const _SettingTile({required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
    leading: Container(width: 42, height: 42, decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer, borderRadius: BorderRadius.circular(13)), child: Icon(icon, color: Theme.of(context).colorScheme.primary)),
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
    subtitle: Text(subtitle),
    trailing: const Icon(Icons.chevron_right_rounded),
  );
}
