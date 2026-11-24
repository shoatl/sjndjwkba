// lib/features/auth/request_access_screen.dart
//
// People request an account here. No role is chosen. The Admin verifies the
// identity, corrects the name and phone number, and assigns the role.
// The account starts as Pending.
//
// The privacy notice below is DRAFT wording. It must be reviewed by your
// adviser or the barangay data protection officer before release.

import 'package:flutter/material.dart';

import '../../core/data/auth_repository.dart';
import '../../core/theme/app_theme.dart';

class RequestAccessScreen extends StatefulWidget {
  const RequestAccessScreen({
    super.key,
    required this.repository,
    required this.onBack,
    this.onReadFullNotice,
  });

  final AuthRepository repository;

  /// Go back to Log in (also used by the success screen).
  final VoidCallback onBack;

  /// Open the full privacy notice. Hidden when null.
  final VoidCallback? onReadFullNotice;

  @override
  State<RequestAccessScreen> createState() => _RequestAccessScreenState();
}

class _RequestAccessScreenState extends State<RequestAccessScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _phoneFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();

  bool _busy = false;
  bool _sent = false;
  bool _hidePassword = true;
  String? _error;

  // Philippine mobile numbers: 09XXXXXXXXX, 639XXXXXXXXX, or +639XXXXXXXXX.
  static final _phoneRule = RegExp(r'^(\+63|63|0)9\d{9}$');

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _password.dispose();
    _confirm.dispose();
    _phoneFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  String _cleanPhone(String s) => s.replaceAll(RegExp(r'[\s\-()]'), '');

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await widget.repository.requestAccess(
        AccessRequest(
          name: _name.text.trim(),
          phone: _cleanPhone(_phone.text),
          password: _password.text,
        ),
      );
      if (!mounted) return;
      setState(() => _sent = true);
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
      case AuthFailure.phoneAlreadyRequested:
        return 'This phone number already has a request or an account. '
            'Please contact your Admin.';
      case AuthFailure.network:
        return 'No connection. Check your internet and try again.';
      case AuthFailure.invalidCredentials:
      case AuthFailure.accountArchived:
      case AuthFailure.unknown:
        return 'Something went wrong. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.surface,
      appBar: AppBar(title: const Text('Request access')),
      body: SafeArea(
        child: _sent ? _buildSuccess(context) : _buildForm(context),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    final scheme = context.colors;
    final text = Theme.of(context).textTheme;

    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: AutofillGroup(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Tell us who you are',
                style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'Use the name and number your barangay knows you by. '
                'An Admin will verify them and assign your role.',
                style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 18),
              if (_error != null) ...[
                _ErrorBanner(message: _error!),
                const SizedBox(height: 14),
              ],
              TextFormField(
                controller: _name,
                enabled: !_busy,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
                onFieldSubmitted: (_) => _phoneFocus.requestFocus(),
                decoration: _decoration(
                  context,
                  label: 'Full name',
                  icon: Icons.badge_outlined,
                ),
                validator: (v) => (v == null || v.trim().length < 2)
                    ? 'Enter your full name.'
                    : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _phone,
                focusNode: _phoneFocus,
                enabled: !_busy,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.telephoneNumber],
                onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
                decoration: _decoration(
                  context,
                  label: 'Mobile number',
                  icon: Icons.phone_outlined,
                ).copyWith(helperText: 'Example: 09171234567'),
                validator: (v) {
                  final value = _cleanPhone(v ?? '');
                  if (value.isEmpty) return 'Enter your mobile number.';
                  if (!_phoneRule.hasMatch(value)) {
                    return 'Enter a valid Philippine mobile number.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _password,
                focusNode: _passwordFocus,
                enabled: !_busy,
                obscureText: _hidePassword,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newPassword],
                onFieldSubmitted: (_) => _confirmFocus.requestFocus(),
                decoration: _decoration(
                  context,
                  label: 'Password',
                  icon: Icons.lock_outline,
                ).copyWith(
                  helperText: 'At least 8 characters',
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
                validator: (v) => (v == null || v.length < 8)
                    ? 'Use at least 8 characters.'
                    : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _confirm,
                focusNode: _confirmFocus,
                enabled: !_busy,
                obscureText: _hidePassword,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.newPassword],
                onFieldSubmitted: (_) => _submit(),
                decoration: _decoration(
                  context,
                  label: 'Confirm password',
                  icon: Icons.lock_outline,
                ),
                validator: (v) =>
                    v != _password.text ? 'Passwords do not match.' : null,
              ),
              const SizedBox(height: 18),
              _PrivacyNotice(onReadFull: widget.onReadFullNotice),
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
                    : const Text('Send request'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccess(BuildContext context) {
    final scheme = context.colors;
    final text = Theme.of(context).textTheme;
    final ok = context.status.normal;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color.alphaBlend(ok.withAlpha(36), scheme.surface),
                border: Border.all(color: ok.withAlpha(120)),
              ),
              child: Icon(Icons.check_rounded, color: ok, size: 40),
            ),
            const SizedBox(height: 18),
            Text(
              'Request sent',
              style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'An Admin will verify your details and assign your role. '
              'You can log in anytime to check the status.',
              textAlign: TextAlign.center,
              style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: widget.onBack,
              style: FilledButton.styleFrom(
                minimumSize: const Size(220, 54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Back to log in'),
            ),
          ],
        ),
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

/// Short privacy notice. DRAFT wording, needs review before release.
class _PrivacyNotice extends StatelessWidget {
  const _PrivacyNotice({this.onReadFull});

  final VoidCallback? onReadFull;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final text = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withAlpha(120),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outline.withAlpha(90)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, color: scheme.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your data',
                  style: text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  'We collect your name and mobile number only to verify '
                  'who you are, send you alerts, and record your response '
                  'work. Under the Data Privacy Act (RA 10173), you will be '
                  'asked for your consent after your account is approved.',
                  style: text.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                if (onReadFull != null)
                  TextButton(
                    onPressed: onReadFull,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(48, 40),
                      alignment: Alignment.centerLeft,
                    ),
                    child: const Text('Read the full notice'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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
