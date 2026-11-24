// lib/features/auth/login_screen.dart
//
// Sign in. After a successful sign in this screen only updates the Session.
// The app shell watches Session.destination and moves the person to the
// right screen (Pending Approval, Consent, Home...), so no navigation
// happens here.
//
// Colors: only context.colors, context.status, and the app bar theme.
// No logos. The brand mark is a plain icon.

import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/auth/session.dart';
import '../../core/data/auth_repository.dart';
import '../../core/theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.repository,
    required this.session,
    required this.onRequestAccess,
  });

  final AuthRepository repository;
  final Session session;

  /// Open the Request Access screen.
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

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final result = await widget.repository.signIn(
        loginId: _idController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      final ok = widget.session.signIn(
        result.user,
        consentAccepted: result.consentAccepted,
      );
      if (!ok) {
        setState(() => _error = _messageFor(AuthFailure.accountArchived));
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _error = _messageFor(e.failure));
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = _messageFor(AuthFailure.unknown));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _messageFor(AuthFailure failure) {
    switch (failure) {
      case AuthFailure.invalidCredentials:
        return 'Wrong phone number, username, or password. Please try again.';
      case AuthFailure.accountArchived:
        return 'This account is not active. Please contact your Admin.';
      case AuthFailure.network:
        return 'No connection. Check your internet and try again.';
      case AuthFailure.phoneAlreadyRequested:
      case AuthFailure.unknown:
        return 'Something went wrong. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          children: [
            // Header and the form card overlap by design.
            Stack(
              children: [
                const _Header(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 236, 16, 0),
                  child: _EntranceFade(child: _buildCard(context)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildFooter(context),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context) {
    final scheme = context.colors;
    final text = Theme.of(context).textTheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withAlpha(224),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: scheme.primary.withAlpha(75)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(35),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: AutofillGroup(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Log in',
                style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'Use the account approved by your Admin.',
                style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 18),
              if (_error != null) ...[
                _ErrorBanner(message: _error!),
                const SizedBox(height: 14),
              ],
              TextFormField(
                controller: _idController,
                enabled: !_busy,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.username],
                onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
                decoration: _decoration(
                  context,
                  label: 'Phone number or username',
                  icon: Icons.person_outline,
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Enter your phone number or username.'
                    : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _passwordController,
                focusNode: _passwordFocus,
                enabled: !_busy,
                obscureText: _hidePassword,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                onFieldSubmitted: (_) => _submit(),
                decoration: _decoration(
                  context,
                  label: 'Password',
                  icon: Icons.lock_outline,
                ).copyWith(
                  suffixIcon: IconButton(
                    tooltip: _hidePassword ? 'Show password' : 'Hide password',
                    onPressed: () =>
                        setState(() => _hidePassword = !_hidePassword),
                    icon: Icon(
                      _hidePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Enter your password.' : null,
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _busy ? null : _submit,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _busy
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: scheme.onPrimary,
                        ),
                      )
                    : const Text('Log in'),
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    final scheme = context.colors;
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'No account yet?',
                style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
              ),
              TextButton(
                onPressed: _busy ? null : widget.onRequestAccess,
                style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                child: const Text('Request access'),
              ),
            ],
          ),
          Text(
            'An Admin verifies every request and assigns your role.',
            textAlign: TextAlign.center,
            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  InputDecoration _decoration(
    BuildContext context, {
    required String label,
    required IconData icon,
  }) {
    final scheme = context.colors;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: scheme.outline.withAlpha(140)),
    );
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: scheme.surfaceContainerHighest.withAlpha(120),
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: BorderSide(color: scheme.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
    );
  }
}

/// Top block. Uses the app bar colors from the theme, so it always matches
/// the palette without any color literal here.
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final bar = Theme.of(context).appBarTheme;
    final base = bar.backgroundColor ?? scheme.primary;
    final onBase = bar.foregroundColor ?? scheme.onPrimary;
    final text = Theme.of(context).textTheme;
    final top = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      height: 280,
      padding: EdgeInsets.fromLTRB(20, top + 18, 20, 0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [scheme.surfaceContainerHighest, scheme.surface],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: onBase.withAlpha(30),
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: onBase.withAlpha(50)),
                ),
                child: Icon(Icons.water_drop_outlined, color: onBase, size: 22),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Drainage Monitor',
                    style: text.titleMedium?.copyWith(
                      color: onBase,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Field Operations',
                    style: text.bodySmall?.copyWith(
                      color: onBase.withAlpha(190),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 26),
          Text(
            'Welcome back',
            style: text.headlineSmall?.copyWith(
              color: onBase,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Watch the drain and respond to alerts.',
            style: text.bodyMedium?.copyWith(color: onBase.withAlpha(200)),
          ),
        ],
      ),
    );
  }
}

/// Error shown in words and an icon, not by color alone.
class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final accent = context.status.stage3;
    final text = Theme.of(context).textTheme;

    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Color.alphaBlend(accent.withAlpha(30), scheme.surface),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: accent.withAlpha(120)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline, color: accent, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: text.bodySmall?.copyWith(color: scheme.onSurface),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Soft fade and rise when the card first appears.
class _EntranceFade extends StatelessWidget {
  const _EntranceFade({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 16 * (1 - value)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}
