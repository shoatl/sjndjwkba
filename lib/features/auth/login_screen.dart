// lib/features/auth/login_screen.dart
// Redesigned glass login screen. Authentication and session behavior are unchanged.

import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/auth/session.dart';
import '../../core/data/auth_repository.dart';
import '../../core/theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.repository, required this.session, required this.onRequestAccess});

  final AuthRepository repository;
  final Session session;
  final VoidCallback onRequestAccess;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocus = FocusNode();
  bool _busy = false;
  bool _hidePassword = true;
  String? _error;

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() { _busy = true; _error = null; });

    try {
      final result = await widget.repository.signIn(
        loginId: _idController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      final ok = widget.session.signIn(result.user, consentAccepted: result.consentAccepted);
      if (!ok) setState(() => _error = 'This account is not active. Please contact your Admin.');
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.failure == AuthFailure.invalidCredentials
          ? 'Wrong phone number, username, or password. Please try again.'
          : e.failure == AuthFailure.network
              ? 'No connection. Check your internet and try again.'
              : 'Something went wrong. Please try again.');
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: Stack(
        children: [
          Positioned.fill(child: _TechnicalBackground(scheme: scheme)),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight - 42),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 440),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 58,
                                  height: 58,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(colors: [scheme.primary, scheme.primary.withAlpha(70)]),
                                    boxShadow: [BoxShadow(color: scheme.primary.withAlpha(55), blurRadius: 24)],
                                  ),
                                  child: Icon(Icons.water_drop_rounded, color: scheme.onPrimary, size: 34),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text('LORA', textAlign: TextAlign.center, style: text.titleLarge?.copyWith(color: scheme.primary, fontWeight: FontWeight.w900, letterSpacing: 2)),
                            Text('DRAINAGE MONITOR', textAlign: TextAlign.center, style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: 0.7)),
                            const SizedBox(height: 6),
                            Text('Smart monitoring. Safer communities.', textAlign: TextAlign.center, style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                            const SizedBox(height: 28),
                            _GlassLoginCard(
                              formKey: _formKey,
                              idController: _idController,
                              passwordController: _passwordController,
                              passwordFocus: _passwordFocus,
                              busy: _busy,
                              hidePassword: _hidePassword,
                              error: _error,
                              onTogglePassword: () => setState(() => _hidePassword = !_hidePassword),
                              onSubmit: _submit,
                            ),
                            const SizedBox(height: 14),
                            OutlinedButton.icon(
                              onPressed: _busy ? null : widget.onRequestAccess,
                              icon: const Icon(Icons.person_add_alt_1_outlined),
                              label: const Text('Request access'),
                              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(54)),
                            ),
                            const SizedBox(height: 16),
                            Text('An Admin verifies every request and assigns your role.', textAlign: TextAlign.center, style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                            const SizedBox(height: 24),
                            Text('LORA Drainage Monitor v1.0', textAlign: TextAlign.center, style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant.withAlpha(170))),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassLoginCard extends StatelessWidget {
  const _GlassLoginCard({required this.formKey, required this.idController, required this.passwordController, required this.passwordFocus, required this.busy, required this.hidePassword, required this.error, required this.onTogglePassword, required this.onSubmit});

  final GlobalKey<FormState> formKey;
  final TextEditingController idController;
  final TextEditingController passwordController;
  final FocusNode passwordFocus;
  final bool busy;
  final bool hidePassword;
  final String? error;
  final VoidCallback onTogglePassword;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final text = Theme.of(context).textTheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withAlpha(226),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: scheme.primary.withAlpha(90)),
            boxShadow: [BoxShadow(color: Colors.black.withAlpha(50), blurRadius: 28, offset: const Offset(0, 14))],
          ),
          child: AutofillGroup(
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Welcome back', textAlign: TextAlign.center, style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 5),
                  Text('Sign in to continue monitoring the drainage system.', textAlign: TextAlign.center, style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                  const SizedBox(height: 18),
                  if (error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: scheme.error.withAlpha(24), borderRadius: BorderRadius.circular(12), border: Border.all(color: scheme.error.withAlpha(130))),
                      child: Row(children: [Icon(Icons.error_outline, color: scheme.error, size: 20), const SizedBox(width: 9), Expanded(child: Text(error!, style: text.bodySmall))]),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextFormField(
                    controller: idController,
                    enabled: !busy,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.username],
                    onFieldSubmitted: (_) => passwordFocus.requestFocus(),
                    decoration: const InputDecoration(prefixIcon: Icon(Icons.person_outline), labelText: 'Phone number or username'),
                    validator: (value) => value == null || value.trim().isEmpty ? 'Enter your phone number or username.' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: passwordController,
                    focusNode: passwordFocus,
                    enabled: !busy,
                    obscureText: hidePassword,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
                    onFieldSubmitted: (_) => onSubmit(),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.lock_outline),
                      labelText: 'Password',
                      suffixIcon: IconButton(tooltip: hidePassword ? 'Show password' : 'Hide password', onPressed: onTogglePassword, icon: Icon(hidePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined)),
                    ),
                    validator: (value) => value == null || value.isEmpty ? 'Enter your password.' : null,
                  ),
                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: busy ? null : onSubmit,
                    child: busy
                        ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: scheme.onPrimary))
                        : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text('Sign in'), SizedBox(width: 8), Icon(Icons.arrow_forward_rounded, size: 20)]),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TechnicalBackground extends StatelessWidget {
  const _TechnicalBackground({required this.scheme});
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [scheme.surface, Color.alphaBlend(scheme.primary.withAlpha(28), scheme.surface), scheme.surface]),
      ),
      child: CustomPaint(painter: _GridPainter(scheme.primary)),
    );
  }
}

class _GridPainter extends CustomPainter {
  _GridPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withAlpha(13)..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 32) canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    for (double y = 0; y < size.height; y += 32) canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) => oldDelegate.color != color;
}
