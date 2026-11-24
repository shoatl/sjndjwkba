// lib/app/admin_shell.dart
//
// The signed-in area for Admin: bottom tabs Approvals, Directory, Config,
// Profile. Admin does account and system governance, not field response.
// The Archived Users Vault opens from the Directory, and the audit log from
// Config. Put it in AuthGate like this:
//
//   adminHomeBuilder: (context) => AdminShell(
//     session: session,
//     auth: authRepository,
//     users: userRepository,
//     configs: configRepository,
//     onReadFullNotice: openPrivacyNotice,
//   ),

import 'package:flutter/material.dart';

import '../core/auth/role_guard.dart';
import '../core/auth/session.dart';
import '../core/data/auth_repository.dart';
import '../core/data/config_repository.dart';
import '../core/data/user_repository.dart';
import '../features/profile/profile_screen.dart';
import '../features/roles/admin/approvals_screen.dart';
import '../features/roles/admin/config_screen.dart';
import '../features/roles/admin/directory_screen.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({
    super.key,
    required this.session,
    required this.auth,
    required this.users,
    required this.configs,
    this.onReadFullNotice,
  });

  final Session session;
  final AuthRepository auth;
  final UserRepository users;
  final ConfigRepository configs;
  final VoidCallback? onReadFullNotice;

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return RoleGuard(
      session: widget.session,
      allowed: (role) => role.canManageUsers,
      child: Scaffold(
        body: IndexedStack(
          index: _tab,
          children: [
            ApprovalsScreen(users: widget.users),
            DirectoryScreen(users: widget.users),
            ConfigScreen(configs: widget.configs, users: widget.users),
            ProfileScreen(
              session: widget.session,
              auth: widget.auth,
              onReadFullNotice: widget.onReadFullNotice,
            ),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: (i) => setState(() => _tab = i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.how_to_reg_outlined),
              selectedIcon: Icon(Icons.how_to_reg_rounded),
              label: 'Approvals',
            ),
            NavigationDestination(
              icon: Icon(Icons.groups_outlined),
              selectedIcon: Icon(Icons.groups_rounded),
              label: 'Directory',
            ),
            NavigationDestination(
              icon: Icon(Icons.tune_outlined),
              selectedIcon: Icon(Icons.tune_rounded),
              label: 'Config',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
