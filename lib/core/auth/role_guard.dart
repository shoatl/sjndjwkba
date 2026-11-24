// lib/core/auth/role_guard.dart
//
// Shows [child] only when the signed-in role passes [allowed]. Otherwise it
// shows a short "no access" message. This is for usability only. The server
// enforces every permission.
//
// Example:
//   RoleGuard(
//     session: session,
//     allowed: (role) => role.canManageUsers,
//     child: ApprovalsScreen(...),
//   )

import 'package:flutter/material.dart';

import '../../shared/widgets/empty_state.dart';
import '../models/drainage_models.dart';
import 'session.dart';

class RoleGuard extends StatelessWidget {
  const RoleGuard({
    super.key,
    required this.session,
    required this.allowed,
    required this.child,
  });

  final Session session;
  final bool Function(UserRole role) allowed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: session,
      builder: (context, _) {
        final role = session.role;
        if (role != null && allowed(role)) return child;
        return const Scaffold(
          body: EmptyState(
            icon: Icons.lock_outline,
            title: 'No access',
            message: 'Your account cannot open this screen.',
          ),
        );
      },
    );
  }
}
