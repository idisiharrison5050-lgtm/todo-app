import 'package:flutter/material.dart';
import '../application/auth_store.dart';
import '../data/auth_api.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key, required this.store, required this.onAuthenticated});
  final AuthStore store;
  final VoidCallback onAuthenticated;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _register = false;
  bool _busy = false;
  bool _obscure = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _busy = true);
    try {
      if (_register) {
        await widget.store.register(name: _name.text.trim(), email: _email.text.trim(), password: _password.text, deviceName: 'mobile');
      } else {
        await widget.store.login(email: _email.text.trim(), password: _password.text, deviceName: 'mobile');
      }
      if (mounted) {
        widget.onAuthenticated();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error is AuthApiException ? error.message : 'We could not complete that request. Please try again.')));
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _forgotPassword() async {
    final controller = TextEditingController(text: _email.text.trim());
    final formKey = GlobalKey<FormState>();
    try {
      final email = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Reset your password'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              keyboardType: TextInputType.emailAddress,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Email address'),
              validator: (value) => value == null || !value.contains('@') ? 'Enter a valid email' : null,
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(context, controller.text.trim());
                }
              },
              child: const Text('Send link'),
            ),
          ],
        ),
      );
      if (email == null || email.isEmpty || !mounted) {
        return;
      }
      setState(() => _busy = true);
      final message = await widget.store.requestPasswordReset(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error is AuthApiException ? error.message : 'We could not send the reset link. Please try again.')));
      }
    } finally {
      controller.dispose();
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      body: Stack(
        children: [
          Positioned(top: -150, right: -100, child: _Glow(color: scheme.primary.withValues(alpha: .13), size: 330)),
          Positioned(bottom: -180, left: -120, child: _Glow(color: scheme.tertiary.withValues(alpha: .10), size: 360)),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 30, 22, 28),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Column(
                    children: [
                      _BrandHeader(scheme: scheme, theme: theme),
                      const SizedBox(height: 34),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 260),
                        transitionBuilder: (child, animation) => FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween(begin: const Offset(0, .035), end: Offset.zero).animate(animation),
                            child: child,
                          ),
                        ),
                        child: _Header(key: ValueKey(_register), register: _register, theme: theme, scheme: scheme),
                      ),
                      const SizedBox(height: 22),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                if (_register) ...[
                                  TextFormField(
                                    controller: _name,
                                    textInputAction: TextInputAction.next,
                                    decoration: const InputDecoration(labelText: 'Full name', prefixIcon: Icon(Icons.person_outline_rounded)),
                                    validator: (value) => value == null || value.trim().isEmpty ? 'Enter your name' : null,
                                  ),
                                  const SizedBox(height: 13),
                                ],
                                TextFormField(
                                  controller: _email,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  decoration: const InputDecoration(labelText: 'Email address', prefixIcon: Icon(Icons.mail_outline_rounded)),
                                  validator: (value) => value == null || !value.contains('@') ? 'Enter a valid email' : null,
                                ),
                                const SizedBox(height: 13),
                                TextFormField(
                                  controller: _password,
                                  obscureText: _obscure,
                                  onChanged: (_) => setState(() {}),
                                  onFieldSubmitted: (_) => _submit(),
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                                    suffixIcon: IconButton(
                                      onPressed: () => setState(() => _obscure = !_obscure),
                                      icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                                    ),
                                  ),
                                  validator: (value) => value == null || value.length < 8 ? 'Use at least 8 characters' : null,
                                ),
                                if (_register) ...[
                                  const SizedBox(height: 12),
                                  _PasswordStrength(password: _password.text, scheme: scheme),
                                ],
                                const SizedBox(height: 19),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton.icon(
                                    onPressed: _busy ? null : _submit,
                                    icon: _busy ? const SizedBox(width: 19, height: 19, child: CircularProgressIndicator(strokeWidth: 2)) : Icon(_register ? Icons.arrow_forward_rounded : Icons.login_rounded),
                                    label: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4),
                                      child: Text(_busy ? 'Working…' : _register ? 'Create account' : 'Sign in'),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (!_register) ...[
                        const SizedBox(height: 7),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(onPressed: _busy ? null : _forgotPassword, child: const Text('Forgot your password?')),
                        ),
                      ],
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: _busy ? null : () => setState(() => _register = !_register),
                        child: Text(_register ? 'Already have an account?  Sign in' : 'New here?  Create an account'),
                      ),
                      const SizedBox(height: 21),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: scheme.outlineVariant.withValues(alpha: .65)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.shield_outlined, size: 19, color: scheme.primary),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Private by design · Your workspace is tied to your account.',
                                style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader({required this.scheme, required this.theme});
  final ColorScheme scheme;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [scheme.primary, scheme.tertiary]),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [BoxShadow(color: scheme.primary.withValues(alpha: .22), blurRadius: 24, offset: const Offset(0, 10))],
            ),
            child: Icon(Icons.check_rounded, color: scheme.onPrimary, size: 30),
          ),
          const SizedBox(width: 13),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Todo', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
              Text('Plan. Focus. Finish.', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600, color: scheme.onSurfaceVariant)),
            ],
          ),
        ],
      );
}

class _Header extends StatelessWidget {
  const _Header({super.key, required this.register, required this.theme, required this.scheme});
  final bool register;
  final ThemeData theme;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(register ? 'Build your workspace.' : 'Welcome back.', textAlign: TextAlign.center, style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -1.8)),
          const SizedBox(height: 9),
          Text(register ? 'Everything you need to turn intentions into completed work.' : 'Your tasks, reminders, and focus sessions are waiting.', textAlign: TextAlign.center, style: theme.textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant, height: 1.45)),
        ],
      );
}

class _PasswordStrength extends StatelessWidget {
  const _PasswordStrength({required this.password, required this.scheme});
  final String password;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final length = password.length >= 8 ? 1 : 0;
    final upper = password.contains(RegExp(r'[A-Z]')) ? 1 : 0;
    final number = password.contains(RegExp(r'[0-9]')) ? 1 : 0;
    final symbol = password.contains(RegExp(r'[^A-Za-z0-9]')) ? 1 : 0;
    final score = length + upper + number + symbol;
    final label = score <= 1 ? 'Use a stronger password' : score == 2 ? 'Good start' : score == 3 ? 'Strong password' : 'Excellent password';
    return Row(
      children: [
        Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: score / 4, minHeight: 5))),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: scheme.onSurfaceVariant)),
      ],
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color, required this.size});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color, boxShadow: [BoxShadow(color: color, blurRadius: 100, spreadRadius: 25)]),
        ),
      );
}
