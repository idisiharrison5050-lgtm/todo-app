import 'package:flutter/material.dart';
import '../application/auth_store.dart';
import '../data/auth_api.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key, required this.store, required this.onAuthenticated});
  final AuthStore store;
  final VoidCallback onAuthenticated;
  @override State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _register = false;
  bool _busy = false;
  bool _obscure = true;

  @override void dispose() { _name.dispose(); _email.dispose(); _password.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      if (_register) {
        await widget.store.register(name: _name.text.trim(), email: _email.text.trim(), password: _password.text, deviceName: 'mobile');
      } else {
        await widget.store.login(email: _email.text.trim(), password: _password.text, deviceName: 'mobile');
      }
      if (mounted) widget.onAuthenticated();
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error is AuthApiException ? error.message : 'We could not complete that request. Please try again.')));
    } finally { if (mounted) setState(() => _busy = false); }
  }

  Future<void> _forgotPassword() async {
    final controller = TextEditingController(text: _email.text.trim());
    final formKey = GlobalKey<FormState>();
    try {
      final email = await showDialog<String>(context: context, builder: (context) => AlertDialog(
        title: const Text('Reset your password'),
        content: Form(key: formKey, child: TextFormField(controller: controller, keyboardType: TextInputType.emailAddress, autofocus: true, decoration: const InputDecoration(labelText: 'Email address'), validator: (value) => value == null || !value.contains('@') ? 'Enter a valid email' : null)),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), FilledButton(onPressed: () { if (formKey.currentState!.validate()) Navigator.pop(context, controller.text.trim()); }, child: const Text('Send link'))],
      ));
      if (email == null || email.isEmpty || !mounted) return;
      setState(() => _busy = true);
      final message = await widget.store.requestPasswordReset(email: email);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error is AuthApiException ? error.message : 'We could not send the reset link. Please try again.')));
    } finally { controller.dispose(); if (mounted) setState(() => _busy = false); }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); final scheme = theme.colorScheme;
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [scheme.primary.withValues(alpha: .08), scheme.surface, scheme.tertiary.withValues(alpha: .06)])),
        child: SafeArea(child: Center(child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(24, 42, 24, 32), child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 480), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 56, height: 56, decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [scheme.primary, scheme.tertiary]), borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: scheme.primary.withValues(alpha: .2), blurRadius: 22, offset: const Offset(0, 9))]), child: Icon(Icons.check_rounded, color: scheme.onPrimary, size: 31)),
            const SizedBox(width: 13),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Todo', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)), Text('Plan. Focus. Finish.', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600))]),
          ]),
          const SizedBox(height: 38),
          Text(_register ? 'Build your workspace.' : 'Welcome back.', style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -1.8)),
          const SizedBox(height: 9),
          Text(_register ? 'Everything you need to turn intentions into completed work.' : 'Your tasks, reminders, and focus sessions are waiting.', style: theme.textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant, height: 1.45)),
          const SizedBox(height: 26),
          Card(child: Padding(padding: const EdgeInsets.fromLTRB(18, 20, 18, 18), child: Form(key: _formKey, child: Column(children: [
            if (_register) ...[TextFormField(controller: _name, textInputAction: TextInputAction.next, decoration: const InputDecoration(labelText: 'Full name', prefixIcon: Icon(Icons.person_outline_rounded)), validator: (value) => value == null || value.trim().isEmpty ? 'Enter your name' : null), const SizedBox(height: 13)],
            TextFormField(controller: _email, keyboardType: TextInputType.emailAddress, textInputAction: TextInputAction.next, decoration: const InputDecoration(labelText: 'Email address', prefixIcon: Icon(Icons.mail_outline_rounded)), validator: (value) => value == null || !value.contains('@') ? 'Enter a valid email' : null),
            const SizedBox(height: 13),
            TextFormField(controller: _password, obscureText: _obscure, onFieldSubmitted: (_) => _submit(), decoration: InputDecoration(labelText: 'Password', prefixIcon: const Icon(Icons.lock_outline_rounded), suffixIcon: IconButton(onPressed: () => setState(() => _obscure = !_obscure), icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined))), validator: (value) => value == null || value.length < 8 ? 'Use at least 8 characters' : null),
            const SizedBox(height: 19),
            SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: _busy ? null : _submit, icon: _busy ? const SizedBox(width: 19, height: 19, child: CircularProgressIndicator(strokeWidth: 2)) : Icon(_register ? Icons.arrow_forward_rounded : Icons.login_rounded), label: Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Text(_busy ? 'Working…' : _register ? 'Create account' : 'Sign in')))),
          ]))),
          if (!_register) ...[const SizedBox(height: 8), Center(child: TextButton(onPressed: _busy ? null : _forgotPassword, child: const Text('Forgot your password?')))],
          const SizedBox(height: 12),
          Center(child: TextButton(onPressed: _busy ? null : () => setState(() => _register = !_register), child: Text(_register ? 'Already have an account?  Sign in' : 'New here?  Create an account'))),
          const SizedBox(height: 20),
          Row(children: [Expanded(child: Divider(color: scheme.outlineVariant)), Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text('PRIVATE BY DESIGN', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.2, color: scheme.onSurfaceVariant))), Expanded(child: Divider(color: scheme.outlineVariant))]),
          const SizedBox(height: 14),
          Center(child: Text('Your workspace stays tied to your account.', textAlign: TextAlign.center, style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant))),
        ])))));
  }
}
