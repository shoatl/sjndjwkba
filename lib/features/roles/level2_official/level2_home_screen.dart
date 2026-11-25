// lib/features/roles/level2_official/level2_home_screen.dart
//
// Level 2 (barangay official) Home: everything Level 1 sees, plus the
// escalation countdown, the current assignee, Reassign, and Manage credited
// personnel.
//
// The server enforces permissions. Hiding buttons here is for usability.

import 'package:flutter/material.dart';

import '../../../core/auth/session.dart';
import '../../../core/data/user_repository.dart';
import '../../../core/models/drainage_models.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/time_format.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_ui.dart';
import '../../../shared/widgets/section_heading.dart';
import '../../../shared/components.dart';
import '../home_controller.dart';
import '../home_sections.dart';

class Level2HomeScreen extends StatelessWidget {
  const Level2HomeScreen({
    super.key,
    required this.controller,
    required this.session,
    required this.users,
    required this.onOpenAlert,
    required this.onAddRemark,
    required this.onReassign,
    required this.onManageCredited,
    this.onOfferCoResponders,
    this.onOpenProfile,
  });

  final HomeController controller;
  final Session session;
  final UserRepository users;

  final void Function(DrainageAlert alert) onOpenAlert;
  final void Function(DrainageAlert alert) onAddRemark;
  final void Function(DrainageAlert alert) onReassign;
  final void Function(DrainageAlert alert) onManageCredited;
  final void Function(DrainageAlert alert)? onOfferCoResponders;
  final VoidCallback? onOpenProfile;

  @override
  Widget build(BuildContext context) {
    return HomeScaffold(
      controller: controller,
      session: session,
      roleBadge: 'L2',
      subtitle: 'Dispatch',
      onOpenProfile: onOpenProfile,
      bodyBuilder: _body,
    );
  }

  List<Widget> _body(BuildContext context) {
    final alert = controller.activeAlert;
    final role = session.role;
    final canRespond = role?.canRespond ?? false;
    final canReassign = role?.canReassign ?? false;
    final canManage = role?.canManageCredits ?? false;

    return [
      const SectionHeading(eyebrow: 'Dispatch', title: 'Home'),
      const SizedBox(height: 14),
      if (controller.isStale) ...[
        StaleDataBanner(
          lastSeenText: lastSeenText(controller.node?.lastSeen, controller.now),
        ),
        const SizedBox(height: 14),
      ],
      if (alert != null) ...[
        HomeAlertBanner(
          controller: controller,
          alert: alert,
          onOpen: () => onOpenAlert(alert),
        ),
        const SizedBox(height: 14),
        _AssigneeCard(controller: controller, alert: alert, users: users),
        const SizedBox(height: 14),
      ] else if (!controller.isStale) ...[
        HomeStatusCard(controller: controller),
        const SizedBox(height: 14),
      ],
      // Surface live readings before the larger drainage visualization.
      HomeMetricsRow(controller: controller),
      const SizedBox(height: 14),
      HomeGaugeCard(controller: controller),
      if (alert != null && canRespond) ...[
        const SizedBox(height: 14),
        HomeActionsCard(
          controller: controller,
          session: session,
          alert: alert,
          onOpenAlert: onOpenAlert,
          onAddRemark: onAddRemark,
          onOfferCoResponders: onOfferCoResponders,
          extraActions: [
            if (canReassign)
              OutlinedButton.icon(
                onPressed: controller.busy ? null : () => onReassign(alert),
                style: bigOutlinedStyle(),
                icon: const Icon(Icons.swap_horiz_rounded),
                label: const Text('Reassign'),
              ),
            if (canManage)
              OutlinedButton.icon(
                onPressed:
                    controller.busy ? null : () => onManageCredited(alert),
                style: bigOutlinedStyle(),
                icon: const Icon(Icons.groups_outlined),
                label: const Text('Manage credited personnel'),
              ),
          ],
        ),
      ],
    ];
  }
}

/// Who has the alert and where it is in the escalation.
class _AssigneeCard extends StatefulWidget {
  const _AssigneeCard({
    required this.controller,
    required this.alert,
    required this.users,
  });

  final HomeController controller;
  final DrainageAlert alert;
  final UserRepository users;

  @override
  State<_AssigneeCard> createState() => _AssigneeCardState();
}

class _AssigneeCardState extends State<_AssigneeCard> {
  String? _name;
  String? _resolvedFor;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(covariant _AssigneeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.alert.acknowledgedBy?.userId !=
        widget.alert.acknowledgedBy?.userId) {
      _resolve();
    }
  }

  Future<void> _resolve() async {
    final id = widget.alert.acknowledgedBy?.userId;
    if (id == null) {
      // build() runs right after, so no setState is needed here.
      _name = null;
      _resolvedFor = null;
      return;
    }
    if (id == _resolvedFor) return;
    _resolvedFor = id;
    try {
      final found = await widget.users.lookup(<String>[id]);
      if (!mounted || _resolvedFor != id) return;
      setState(() => _name = found[id]?.name);
    } catch (_) {
      // Fall back to "Unknown person" below.
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final text = Theme.of(context).textTheme;
    final alert = widget.alert;
    final ack = alert.acknowledgedBy;

    return AppCard(
      title: 'Escalation',
      subtitle: 'Level ${alert.escalationLevel} notified',
      trailing: AppPill(
        label: alert.status.label,
        color: alertColor(context, alert),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (ack == null) ...[
            ListenableBuilder(
              listenable: widget.controller.countdown,
              builder: (context, _) => Text(
                countdownLine(widget.controller, alert),
                style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Nobody has acknowledged yet.',
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ] else
            Row(
              children: [
                PersonAvatar(name: _name ?? '?'),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _name ?? 'Unknown person',
                        style: text.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Acknowledged at ${formatClock(ack.at)}',
                        style: text.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
