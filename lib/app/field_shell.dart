// lib/app/field_shell.dart
//
// The signed-in area for Level 1 to 3: bottom tabs Home, History, Profile.
//
// It creates ONE HomeController (node + shared alert + settings), shares it
// with whichever Home screen the role needs, and wires every sheet and the
// Alert Detail screen. Put it in AuthGate like this:
//
//   fieldHomeBuilder: (context) => FieldShell(
//     session: session,
//     auth: authRepository,
//     nodes: nodeRepository,
//     alerts: alertRepository,
//     users: userRepository,
//     configs: configRepository,
//     notifications: notificationService,
//     nodeId: 'node-1',
//     onReadFullNotice: openPrivacyNotice,
//   ),

import 'package:flutter/material.dart';

import '../core/auth/role_guard.dart';
import '../core/auth/session.dart';
import '../core/data/alert_repository.dart';
import '../core/data/auth_repository.dart';
import '../core/data/config_repository.dart';
import '../core/data/node_repository.dart';
import '../core/data/user_repository.dart';
import '../core/models/drainage_models.dart';
import '../core/services/notification_service.dart';
import '../features/alerts/alert_detail_screen.dart';
import '../features/alerts/co_responder_sheet.dart';
import '../features/alerts/manage_credited_sheet.dart';
import '../features/alerts/remark_sheet.dart';
import '../features/history/history_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/roles/home_controller.dart';
import '../features/roles/level1_maintenance/level1_home_screen.dart';
import '../features/roles/level2_official/level2_home_screen.dart';
import '../features/roles/level2_official/reassign_sheet.dart';
import '../features/roles/level3_captain/level3_home_screen.dart';
import '../shared/widgets/app_ui.dart';

class FieldShell extends StatefulWidget {
  const FieldShell({
    super.key,
    required this.session,
    required this.auth,
    required this.nodes,
    required this.alerts,
    required this.users,
    required this.configs,
    required this.notifications,
    required this.nodeId,
    this.onReadFullNotice,
  });

  final Session session;
  final AuthRepository auth;
  final NodeRepository nodes;
  final AlertRepository alerts;
  final UserRepository users;
  final ConfigRepository configs;
  final NotificationService notifications;

  /// The single monitoring node. The UI is single-node.
  final String nodeId;

  final VoidCallback? onReadFullNotice;

  @override
  State<FieldShell> createState() => _FieldShellState();
}

class _FieldShellState extends State<FieldShell> {
  static const int _homeTab = 0;
  static const int _profileTab = 2;

  late final HomeController _controller;
  int _tab = _homeTab;

  @override
  void initState() {
    super.initState();
    _controller = HomeController(
      nodeId: widget.nodeId,
      nodes: widget.nodes,
      alerts: widget.alerts,
      configs: widget.configs,
    )..start();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ---- Navigation and sheets -----------------------------------------------

  void _goProfile() => setState(() => _tab = _profileTab);

  void _openAlert(DrainageAlert alert) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => AlertDetailScreen(
          alertId: alert.id,
          initial: alert,
          session: widget.session,
          alerts: widget.alerts,
          users: widget.users,
        ),
      ),
    );
  }

  Future<void> _addRemark(DrainageAlert alert) async {
    final posted = await showRemarkSheet(
      context,
      onSubmit: (text) async {
        await _controller.addRemark(text);
      },
    );
    if (posted && mounted) showAppToast(context, 'Remark added.');
  }

  Future<void> _offerCoResponders(DrainageAlert alert) async {
    final me = widget.session.user?.id;
    if (me == null || !mounted) return;
    final updated = await showCoResponderSheet(
      context,
      alert: alert,
      currentUserId: me,
      users: widget.users,
      alerts: widget.alerts,
    );
    if (updated != null && mounted) {
      showAppToast(context, 'Co-responders added.');
    }
  }

  Future<void> _reassign(DrainageAlert alert) async {
    final updated = await showReassignSheet(
      context,
      alert: alert,
      users: widget.users,
      alerts: widget.alerts,
    );
    if (updated != null && mounted) {
      showAppToast(context, 'Alert reassigned.');
    }
  }

  Future<void> _manageCredited(DrainageAlert alert) async {
    final updated = await showManageCreditedSheet(
      context,
      alert: alert,
      users: widget.users,
      alerts: widget.alerts,
    );
    if (updated != null && mounted) {
      showAppToast(context, 'Credited personnel updated.');
    }
  }

  // ---- Build ---------------------------------------------------------------

  Widget _home(UserRole role) {
    switch (role) {
      case UserRole.level1:
        return Level1HomeScreen(
          controller: _controller,
          session: widget.session,
          onOpenAlert: _openAlert,
          onAddRemark: _addRemark,
          onOfferCoResponders: _offerCoResponders,
          onOpenProfile: _goProfile,
        );
      case UserRole.level2:
        return Level2HomeScreen(
          controller: _controller,
          session: widget.session,
          users: widget.users,
          onOpenAlert: _openAlert,
          onAddRemark: _addRemark,
          onReassign: _reassign,
          onManageCredited: _manageCredited,
          onOfferCoResponders: _offerCoResponders,
          onOpenProfile: _goProfile,
        );
      case UserRole.level3:
        return Level3HomeScreen(
          controller: _controller,
          session: widget.session,
          alerts: widget.alerts,
          onOpenAlert: _openAlert,
          onAddRemark: _addRemark,
          onReassign: _reassign,
          onManageCredited: _manageCredited,
          onOfferCoResponders: _offerCoResponders,
          onOpenProfile: _goProfile,
        );
      case UserRole.admin:
        // Admin never reaches this shell. RoleGuard shows "No access".
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return RoleGuard(
      session: widget.session,
      allowed: (role) => role.isFieldRole,
      child: ListenableBuilder(
        listenable: widget.session,
        builder: (context, _) {
          final role = widget.session.role;
          if (role == null) return const SizedBox.shrink();

          return Scaffold(
            body: IndexedStack(
              index: _tab,
              children: [
                _home(role),
                HistoryScreen(
                  session: widget.session,
                  alerts: widget.alerts,
                  onOpenAlert: _openAlert,
                ),
                ProfileScreen(
                  session: widget.session,
                  auth: widget.auth,
                  notifications: widget.notifications,
                  onReadFullNotice: widget.onReadFullNotice,
                ),
              ],
            ),
            bottomNavigationBar: NavigationBar(
              selectedIndex: _tab,
              onDestinationSelected: (i) => setState(() => _tab = i),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home_rounded),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.history_rounded),
                  selectedIcon: Icon(Icons.history_rounded),
                  label: 'History',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline_rounded),
                  selectedIcon: Icon(Icons.person_rounded),
                  label: 'Profile',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
