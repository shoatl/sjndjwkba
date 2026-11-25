// lib/features/roles/level1_maintenance/level1_home_screen.dart
//
// Level 1 (maintenance) Home: gauge, rain, power, last seen, and the three
// field actions: Acknowledge, Add remark, Mark cleared.
//
// UX rules from the guide:
//  - Acknowledge is two taps or less from this screen.
//  - Stale data turns gray with "No recent data. This is not an all-clear."
//  - Words as well as colors. Big touch targets.
//
// The server enforces permissions. Hiding buttons here is only for usability.

import 'package:flutter/material.dart';

import '../../../core/auth/session.dart';
import '../../../core/data/alert_repository.dart';
import '../../../core/data/node_repository.dart';
import '../../../core/models/drainage_models.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/time_format.dart';
import '../../../shared/components.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/metric_tile.dart';
import '../../../shared/widgets/section_heading.dart';
import '../../../shared/widgets/sheet_helper.dart';
import '../../../shared/widgets/top_chrome.dart';
import '../../../shared/widgets/drainage_system_panel.dart';
import '../../../shared/widgets/interactive_drainage_view.dart';
import '../home_controller.dart';

class Level1HomeScreen extends StatelessWidget {
  const Level1HomeScreen({
    super.key,
    required this.controller,
    required this.session,
    required this.onOpenAlert,
    required this.onAddRemark,
    this.onOfferCoResponders,
    this.onOpenProfile,
  });

  final HomeController controller;
  final Session session;

  /// Open Alert Detail.
  final void Function(DrainageAlert alert) onOpenAlert;

  /// Open the Add remark sheet for this alert.
  final void Function(DrainageAlert alert) onAddRemark;

  /// Called after Acknowledge or Mark cleared succeeds, so the app can offer
  /// "Who else is responding with you?". Optional.
  final void Function(DrainageAlert alert)? onOfferCoResponders;

  final VoidCallback? onOpenProfile;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final background = Color.alphaBlend(
      scheme.surfaceContainerHighest.withAlpha(90),
      scheme.surface,
    );

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: background,
          body: Column(
            children: [
              TopChrome(
                connection: controller.isStale
                    ? ChromeConnection.stale
                    : ChromeConnection.live,
                roleBadge: 'L1',
                userName: session.user?.name ?? '',
                subtitle: 'Field Operations',
                onAccountTap: onOpenProfile,
              ),
              Expanded(
                child: controller.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                        onRefresh: () async => controller.retry(),
                        child: _buildBody(context),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context) {
    final alert = controller.activeAlert;
    final canRespond = session.role?.canRespond ?? false;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(15, 16, 15, 24),
      children: [
        const SectionHeading(
          eyebrow: 'Monitoring node',
          title: 'Home',
        ),
        const SizedBox(height: 14),
        if (controller.isStale) ...[
          StaleDataBanner(
            lastSeenText: lastSeenText(controller.node?.lastSeen, controller.now),
          ),
          const SizedBox(height: 14),
        ],
        if (alert != null) ...[
          _buildAlertBanner(context, alert),
          const SizedBox(height: 14),
        ] else if (!controller.isStale) ...[
          _buildStatusCard(context),
          const SizedBox(height: 14),
        ],
        // Put the live readings before the large drainage visual, matching
        // the reference layout's scan order: alert, metrics, visualization.
        _buildMetrics(context),
        const SizedBox(height: 14),
        DrainageSystemPanel(
          waterPercent: controller.node?.waterLevelPercent,
          stage: controller.node?.waterStage ?? 0,
          isStale: controller.isStale,
        ),
        const SizedBox(height: 14),
        InteractiveDrainageView(
          waterPercent: controller.node?.waterLevelPercent,
          stage: controller.node?.waterStage ?? 0,
          isStale: controller.isStale,
        ),
        const SizedBox(height: 14),
        _buildGaugeCard(context),
        if (alert != null && canRespond) ...[
          const SizedBox(height: 14),
          _buildActions(context, alert),
        ],
      ],
    );
  }

  // ---- Alert ---------------------------------------------------------------

  Widget _buildAlertBanner(BuildContext context, DrainageAlert alert) {
    // Rebuilds every second for the countdown only.
    return ListenableBuilder(
      listenable: controller.countdown,
      builder: (context, _) => AlertBanner(
        stage: alert.stage,
        title: 'Stage ${alert.stage} alert',
        countdownText: _countdownText(alert),
        onOpen: () => onOpenAlert(alert),
      ),
    );
  }

  String _countdownText(DrainageAlert alert) {
    if (alert.status == AlertStatus.pendingConfirmation) {
      return 'Waiting for the sensor to confirm';
    }
    if (alert.status == AlertStatus.critical) {
      return 'Critical, unacknowledged';
    }
    if (alert.isAcknowledged) return 'In progress';
    if (alert.escalationLevel >= 3) return 'Captain notified';
    if (controller.countdown.isExpired) return 'Escalating...';
    return 'Level ${alert.escalationLevel + 1} in ${controller.countdown.text}';
  }

  // ---- Normal state --------------------------------------------------------

  Widget _buildStatusCard(BuildContext context) {
    final scheme = context.colors;
    final text = Theme.of(context).textTheme;
    final stage = controller.node?.waterStage ?? 0;
    final normal = stage == 0;
    final color = context.status.forStage(stage);

    return AppCard(
      accent: color,
      child: Row(
        children: [
          Icon(
            normal ? Icons.check_circle_outline : Icons.warning_amber_rounded,
            color: color,
            size: 30,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  normal ? 'All normal' : 'Water at Stage $stage',
                  style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  normal
                      ? 'Water is below Stage 1.'
                      : 'Waiting for the system to raise an alert.',
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

  // ---- Gauge and readings --------------------------------------------------

  Widget _buildGaugeCard(BuildContext context) {
    final stale = controller.isStale;
    final stage = controller.node?.waterStage ?? 0;

    return AppCard(
      title: 'Water stage',
      subtitle: stale
          ? 'Last known reading. Not current.'
          : (stage == 0 ? 'Below Stage 1' : 'Stage $stage of 3'),
      child: Opacity(
        opacity: stale ? 0.5 : 1,
        child: WaterLevelGauge(currentStage: stage),
      ),
    );
  }

  Widget _buildMetrics(BuildContext context) {
    final node = controller.node;
    final stale = controller.isStale;
    final stage = node?.waterStage ?? 0;

    String? pct(double? v) => v?.round().toString();

    // Power: show what the node reports, in words.
    String? powerValue;
    String? powerUnit;
    String? powerCaption;
    switch (node?.powerSource ?? PowerSource.unknown) {
      case PowerSource.battery:
        powerValue = node?.batteryPercent?.toString();
        powerUnit = powerValue == null ? null : '%';
        powerCaption = 'On battery';
      case PowerSource.mains:
        powerValue = 'AC';
        powerCaption = 'Mains power';
      case PowerSource.unknown:
        break;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: MetricTile(
            label: 'Water',
            value: pct(node?.waterLevelPercent),
            unit: '%',
            icon: Icons.water_outlined,
            caption: stale
                ? 'Last known'
                : (stage == 0 ? 'Normal' : 'Stage $stage'),
            accent: stale ? null : context.status.forStage(stage),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: MetricTile(
            label: 'Rain',
            value: pct(node?.rainPercent),
            unit: '%',
            icon: Icons.grain,
            caption: stale ? 'Last known' : null,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: MetricTile(
            label: 'Power',
            value: powerValue,
            unit: powerUnit,
            icon: Icons.bolt_outlined,
            caption: powerCaption,
          ),
        ),
      ],
    );
  }

  // ---- Actions -------------------------------------------------------------

  Widget _buildActions(BuildContext context, DrainageAlert alert) {
    final scheme = context.colors;
    final text = Theme.of(context).textTheme;
    final busy = controller.busy;

    final waitingForSensor = alert.status == AlertStatus.pendingConfirmation;
    final canAcknowledge = !alert.isAcknowledged && !waitingForSensor;

    return AppCard(
      title: 'Your response',
      subtitle: _responseLine(alert),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (canAcknowledge) ...[
            FilledButton.icon(
              onPressed: busy ? null : () => _acknowledge(context),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(64),
                textStyle: text.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: busy
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: scheme.onPrimary,
                      ),
                    )
                  : const Icon(Icons.check_rounded, size: 26),
              label: const Text('Acknowledge'),
            ),
            const SizedBox(height: 10),
          ],
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: busy ? null : () => onAddRemark(alert),
                  style: _secondaryStyle(),
                  icon: const Icon(Icons.edit_note_rounded),
                  label: const Text('Add remark'),
                ),
              ),
              if (!waitingForSensor) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: busy ? null : () => _markCleared(context),
                    style: _secondaryStyle(),
                    icon: const Icon(Icons.task_alt_rounded),
                    label: const Text('Mark cleared'),
                  ),
                ),
              ],
            ],
          ),
          if (waitingForSensor) ...[
            const SizedBox(height: 10),
            Text(
              'Marked cleared. The alert closes when the sensor confirms '
              'water is below Stage 1. If not, it reopens.',
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
          const SizedBox(height: 4),
          TextButton(
            onPressed: () => onOpenAlert(alert),
            style: TextButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            child: const Text('Open alert details'),
          ),
        ],
      ),
    );
  }

  ButtonStyle _secondaryStyle() => OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      );

  /// Who has the alert, in words. Names come later from the Alert Detail
  /// screen, which looks them up. Home only says "you" or "another responder".
  String _responseLine(DrainageAlert alert) {
    final ack = alert.acknowledgedBy;
    if (ack == null) return 'Nobody has acknowledged yet.';
    final mine = ack.userId == session.user?.id;
    return 'Acknowledged by ${mine ? 'you' : 'another responder'} '
        'at ${formatClock(ack.at)}.';
  }

  Future<void> _acknowledge(BuildContext context) async {
    try {
      final updated = await controller.acknowledge();
      if (!context.mounted) return;
      _toast(context, 'Acknowledged. The escalation timer is stopped.');
      onOfferCoResponders?.call(updated);
    } on AlertException catch (e) {
      if (!context.mounted) return;
      _toast(context, _messageFor(e.failure));
    } catch (_) {
      if (!context.mounted) return;
      _toast(context, _messageFor(AlertFailure.unknown));
    }
  }

  Future<void> _markCleared(BuildContext context) async {
    final confirmed = await showConfirmSheet(
      context,
      title: 'Mark as cleared?',
      message: 'The sensor will check that water is below Stage 1. '
          'If it is not, the alert reopens by itself.',
      confirmLabel: 'Mark cleared',
    );
    if (!confirmed || !context.mounted) return;

    try {
      final updated = await controller.markCleared();
      if (!context.mounted) return;
      _toast(context, 'Marked cleared. Waiting for the sensor to confirm.');
      onOfferCoResponders?.call(updated);
    } on AlertException catch (e) {
      if (!context.mounted) return;
      _toast(context, _messageFor(e.failure));
    } catch (_) {
      if (!context.mounted) return;
      _toast(context, _messageFor(AlertFailure.unknown));
    }
  }

  String _messageFor(AlertFailure failure) {
    switch (failure) {
      case AlertFailure.alreadyAcknowledged:
        return 'Someone else already acknowledged this alert.';
      case AlertFailure.alreadyCleared:
        return 'This alert is already cleared.';
      case AlertFailure.notAllowed:
        return 'Your account cannot do this action.';
      case AlertFailure.notFound:
        return 'This alert is no longer open.';
      case AlertFailure.network:
        return 'No connection. Check your internet and try again.';
      case AlertFailure.unknown:
        return 'Something went wrong. Please try again.';
    }
  }

  void _toast(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
