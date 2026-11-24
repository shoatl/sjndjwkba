// lib/app/app.dart
//
// AuthGate: the one widget that decides which screen to show, based on
// Session.destination. Put it as MaterialApp(home: AuthGate(...)).
//
// It does not import the role Home screens. You pass them in as builders,
// so this file keeps working while those screens are still being written.

import 'package:flutter/material.dart';

import '../core/auth/session.dart';
import '../core/data/auth_repository.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/pending_approval_screen.dart';
import '../features/auth/request_access_screen.dart';
import '../features/privacy/privacy_screens.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({
    super.key,
    required this.session,
    required this.repository,
    required this.fieldHomeBuilder,
    required this.adminHomeBuilder,
    this.onReadFullNotice,
  });

  final Session session;
  final AuthRepository repository;

  /// Level 1 to 3 (Home, History, Profile).
  final WidgetBuilder fieldHomeBuilder;

  /// Admin (Approvals, Directory, Config, Profile).
  final WidgetBuilder adminHomeBuilder;

  /// Open the full privacy notice. Used by Request Access and Consent.
  final VoidCallback? onReadFullNotice;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _ready = false;
  late AuthDestination _last;

  @override
  void initState() {
    super.initState();
    _last = widget.session.destination;
    widget.session.addListener(_onSessionChanged);
    _restore();
  }

  @override
  void dispose() {
    widget.session.removeListener(_onSessionChanged);
    super.dispose();
  }

  /// On app start, pick up a saved session if the server has one.
  Future<void> _restore() async {
    try {
      final saved = await widget.repository.restoreSession();
      if (saved != null) {
        widget.session.signIn(
          saved.user,
          consentAccepted: saved.consentAccepted,
        );
      }
    } catch (_) {
      // Treat any failure as signed out.
    } finally {
      if (mounted) setState(() => _ready = true);
    }
  }

  /// When the destination changes (for example after logout), close any
  /// screens still open on top, such as Alert Detail or Request Access.
  void _onSessionChanged() {
    final now = widget.session.destination;
    if (now == _last) return;
    _last = now;
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _acceptConsent() async {
    try {
      await widget.repository.acceptConsent();
      if (!mounted) return;
      widget.session.acceptConsent();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Could not save your consent. Please try again.'),
          ),
        );
    }
  }

  void _openRequestAccess() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => RequestAccessScreen(
          repository: widget.repository,
          onBack: () => Navigator.of(context).pop(),
          onReadFullNotice: widget.onReadFullNotice,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return ListenableBuilder(
      listenable: widget.session,
      builder: (context, _) {
        switch (widget.session.destination) {
          case AuthDestination.login:
            return LoginScreen(
              repository: widget.repository,
              session: widget.session,
              onRequestAccess: _openRequestAccess,
            );
          case AuthDestination.pendingApproval:
            return PendingApprovalScreen(
              session: widget.session,
              repository: widget.repository,
            );
          case AuthDestination.consent:
            return ConsentScreen(
              onAccepted: () {
                _acceptConsent();
              },
              onReadFullNotice: widget.onReadFullNotice ?? () {},
            );
          case AuthDestination.fieldHome:
            return widget.fieldHomeBuilder(context);
          case AuthDestination.adminHome:
            return widget.adminHomeBuilder(context);
        }
      },
    );
  }
}
