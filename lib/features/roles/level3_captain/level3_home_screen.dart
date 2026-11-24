// lib/features/roles/level3_captain/level3_home_screen.dart
//
// Level 3 (barangay captain) Home: system status, a loud "Critical,
// unacknowledged" banner, response-time summaries, and full authority to
// reassign and manage credited personnel.
//
// The server enforces permissions. Hiding buttons here is for usability.

import 'package:flutter/material.dart';

import '../../../core/auth/session.dart';
import '../../../core/data/alert_repository.dart';
import '../../../core/models/drainage_models.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/time_format.dart';
import '../../../shared/components.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_ui.dart';
import '../../../shared/widgets/load_view.dart';
import '../../../shared/widgets/metric_tile.dart';
import '../../../shared/widgets/section_heading.dart';
import '../../history/response_metrics.dart';
import '../home_controller.dart';
import '../home_sections.dart';

class Level3HomeScreen extends StatelessWidget {
  const Level3HomeScreen({
    super.key,
    required this.controller,
    required this.session,
    required this.alerts,
    required this.onOpenAlert,
    required this.onAddRemark,
    required this.onReassign,
    required this.onManageCredited,
    this.onOfferCoResponders,
    this.onOpenProfile,
  });

  final HomeController controller;
  final Session session;
  final AlertRepository alerts;

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
      roleBadge: 'L3',
      subtitle: 'Oversight',
      onOpenProfile: onOpenProfile,
      bodyBuilder: _body,
    );
  }

  List<Widget> _body(BuildContext context) {
    final alert = controller.activeAlert;
    final role = session.role;
    final canRespond = role?.canRespond ?? false;
    final critical = alert != null && alert.status == AlertStatus.critical;

    return [
      const SectionHeading(eyebrow: 'Oversight', title: 'Home'),
      const SizedBox(height: 14),
      if (controller.isStale) ...[
        StaleDataBanner(
          lastSeenText: lastSeenText(controller.node?.lastSeen, controller.now),
        ),
        const SizedBox(height: 14),
      ],
      if (alert != null && critical) ...[
        _CriticalCard(alert: alert, onOpen: () => onOpenAlert(alert)),
        const SizedBox(height: 14),
      ] else if (alert != null) ...[
        HomeAlertBanner(
          controller: controller,
          alert: alert,
          onOpen: () => onOpenAlert(alert),
        ),
        const SizedBox(height: 14),
      ] else if (!controller.isStale) ...[
        HomeStatusCard(controller: controller),
        const SizedBox(height: 14),
      ],
      _SystemStatusCard(controller: controller, alert: alert),
      const SizedBox(height: 14),
      HomeGaugeCard(controller: controller),
      const SizedBox(height: 14),
      HomeMetricsRow(controller: controller),
      const SizedBox(height: 14),
      _ResponseSummary(alerts: alerts),
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
            OutlinedButton.icon(
              onPressed: controller.busy ? null : () => onReassign(alert),
              style: bigOutlinedStyle(),
              icon: const Icon(Icons.swap_horiz_rounded),
              label: const Text('Reassign'),
            ),
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

/// Level 3 missed too: nobody has answered. Words and an icon, not color alone.
class _CriticalCard extends StatelessWidget {
  const _CriticalCard({required this.alert, required this.onOpen});

  final DrainageAlert alert;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final text = Theme.of(context).textTheme;
    final color = context.status.stage3;

    return AppCard(
      accent: color,
      semanticLabel: 'Critical, unacknowledged. Stage ${alert.stage}. '
          'Open alert details.',
      onTap: onOpen,
      child: Row(
        children: [
          Icon(Icons.crisis_alert_rounded, color: color, size: 34),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Critical, unacknowledged',
                  style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  'Stage ${alert.stage}. Nobody has responded. '
                  'Please act or reassign now.',
                  style: text.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
        ],
      ),
    );
  }
}

/// A plain read-out of the whole system.
class _SystemStatusCard extends StatelessWidget {
  const _SystemStatusCard({required this.controller, required this.alert});

  final HomeController controller;
  final DrainageAlert? alert;

  @override
  Widget build(BuildContext context) {
    final stale = controller.isStale;
    final stage = controller.node?.waterStage ?? 0;
    final alert = this.alert;

    return AppCard(
      title: 'System status',
      subtitle: 'Single monitoring node',
      trailing: AppPill(
        label: stale ? 'No recent data' : 'Reporting',
        color: stale ? context.status.stale : context.status.normal,
      ),
      child: Column(
        children: [
          InfoRow(
            label: 'Node',
            value: stale
                ? 'No recent data. This is not an all-clear.'
                : 'Live',
          ),
          InfoRow(
            label: 'Last seen',
            value: lastSeenText(controller.node?.lastSeen, controller.now)
                .replaceFirst('Last seen ', ''),
          ),
          InfoRow(
            label: 'Water',
            value: stale ? 'Last known: ${stageText(stage)}' : stageText(stage),
          ),
          InfoRow(
            label: 'Alert',
            value: alert == null
                ? 'None open'
                : '${alert.status.label}, Level ${alert.escalationLevel} '
                    'notified',
          ),
          InfoRow(
            label: 'Timeout',
            value: '${controller.config.escalationTimeout.inMinutes} min '
                'per level',
          ),
        ],
      ),
    );
  }
}

/// Average response times from the latest incidents.
class _ResponseSummary extends StatelessWidget {
  const _ResponseSummary({required this.alerts});

  final AlertRepository alerts;

  @override
  Widget build(BuildContext context) {
    return LoadView<List<DrainageAlert>>(
      compact: true,
      load: () => alerts.fetchHistory(limit: 50),
      builder: (context, items, reload) {
        final m = ResponseMetrics.from(items);
        return AppCard(
          title: 'Response summary',
          subtitle: 'Latest ${m.total} incident${m.total == 1 ? '' : 's'}',
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: MetricTile(
                      label: 'To acknowledge',
                      value: m.averageAcknowledge == null
                          ? null
                          : formatDuration(m.averageAcknowledge!),
                      icon: Icons.timer_outlined,
                      caption: 'Average',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: MetricTile(
                      label: 'To clear',
                      value: m.averageClear == null
                          ? null
                          : formatDuration(m.averageClear!),
                      icon: Icons.task_alt_rounded,
                      caption: 'Average',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              InfoRow(label: 'Unacknowledged', value: '${m.unacknowledged}'),
              InfoRow(label: 'Still open', value: '${m.active}'),
            ],
          ),
        );
      },
    );
  }
}
