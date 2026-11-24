// lib/features/auth/pending_approval_screen.dart
//
// The only screen a Pending account can see. No telemetry, no alerts,
// no personnel directory.
//
// "Check status" asks the server for the latest user. If the Admin approved
// the account, Session.refreshUser updates it and the app moves on by itself
// (Session.destination changes). No timers here: when your backend can push
// approvals, call session.refreshUser from there too.

import 'package:flutter/material.dart';

import '../../core/auth/session.dart';
import '../../core/data/auth_repository.dart';
import '../../core/theme/app_theme.dart';

class PendingApprovalScreen extends StatefulWidget {
  const PendingApprovalScreen({
    super.key,
    required this.session,
    required this.repository,
  });

  final Session session;
  final AuthRepository repository;

  @override
  State<PendingApprovalScreen> createState() => _PendingApprovalScreenState();
}

class _PendingApprovalScreenState extends State<PendingApprovalScreen> {
  bool _checking = false;

  Future<void> _check() async {
    if (_checking) return;
    setState(() => _checking = true);

    try {
      final updated = await widget.repository.fetchCurrentUser();
      if (!mounted) return;
      if (updated == null) {
        // The server no longer has this session.
        widget.session.signOut();
        return;
      }
      widget.session.refreshUser(updated);
      if (widget.session.destination == AuthDestination.pendingApproval) {
        _toast('Still waiting for Admin approval.');
      }
    } catch (_) {
      if (!mounted) return;
      _toast('Could not check. Check your internet and try again.');
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _logOut() async {
    try {
      await widget.repository.signOut();
    } catch (_) {
      // Sign out locally even if the server could not be reached.
    }
    widget.session.signOut();
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final text = Theme.of(context).textTheme;
    final amber = context.status.stage1;
    final name = widget.session.user?.name ?? '';

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: const Text('Account'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _check,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
            children: [
              Center(
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color.alphaBlend(
                      amber.withAlpha(36),
                      scheme.surface,
                    ),
                    border: Border.all(color: amber.withAlpha(120)),
                  ),
                  child: Icon(
                    Icons.hourglass_top_rounded,
                    color: amber,
                    size: 36,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Waiting for approval',
                textAlign: TextAlign.center,
                style: text.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                name.isEmpty
                    ? 'An Admin is verifying your details and will assign '
                        'your role.'
                    : 'Hi, $name. An Admin is verifying your details and will '
                        'assign your role.',
                textAlign: TextAlign.center,
                style: text.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'You will not see alerts or sensor data until you are approved.',
                textAlign: TextAlign.center,
                style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 22),
              _StepsCard(),
              const SizedBox(height: 22),
              FilledButton.icon(
                onPressed: _checking ? null : _check,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: _checking
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: scheme.onPrimary,
                        ),
                      )
                    : const Icon(Icons.refresh_rounded),
                label: Text(_checking ? 'Checking...' : 'Check status'),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: _checking ? null : _logOut,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Log out'),
              ),
              const SizedBox(height: 12),
              Text(
                'Tip: pull down to refresh.',
                textAlign: TextAlign.center,
                style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Three steps. Words and icons carry the meaning, not color alone.
class _StepsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline.withAlpha(90)),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withAlpha(22),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Column(
        children: [
          _StepRow(
            state: _StepState.done,
            title: 'Request sent',
            detail: 'Your details reached the Admin.',
          ),
          SizedBox(height: 14),
          _StepRow(
            state: _StepState.current,
            title: 'Admin verifies you',
            detail: 'Name, phone number, and role are checked.',
          ),
          SizedBox(height: 14),
          _StepRow(
            state: _StepState.upcoming,
            title: 'You accept privacy consent',
            detail: 'Then your account is ready to use.',
          ),
        ],
      ),
    );
  }
}

enum _StepState { done, current, upcoming }

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.state,
    required this.title,
    required this.detail,
  });

  final _StepState state;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final text = Theme.of(context).textTheme;

    final IconData icon;
    final Color color;
    final String status;
    switch (state) {
      case _StepState.done:
        icon = Icons.check_circle;
        color = context.status.normal;
        status = 'Done';
      case _StepState.current:
        icon = Icons.timelapse_rounded;
        color = context.status.stage1;
        status = 'In progress';
      case _StepState.upcoming:
        icon = Icons.radio_button_unchecked;
        color = scheme.outline;
        status = 'Next';
    }

    return Semantics(
      label: '$title, $status',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: text.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: state == _StepState.upcoming
                        ? scheme.onSurfaceVariant
                        : scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: text.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
