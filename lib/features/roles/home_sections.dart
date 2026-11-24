// lib/features/roles/home_sections.dart
//
// Pieces shared by the Level 2 and Level 3 Home screens. They behave the same
// as the Level 1 Home: stale data goes gray with "No recent data", every
// color comes with words, and touch targets are big.
//
// Nothing here talks to a server directly. Actions go through the
// HomeController, which the server permissions back up.

import 'package:flutter/material.dart';

import '../../core/auth/session.dart';
import '../../core/data/alert_repository.dart';
import '../../core/data/node_repository.dart';
import '../../core/models/drainage_models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/time_format.dart';
import '../../shared/components.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/app_ui.dart';
import '../../shared/widgets/metric_tile.dart';
import '../../shared/widgets/sheet_helper.dart';
import '../../shared/widgets/top_chrome.dart';
import 'home_controller.dart';

/// Header + pull-to-refresh + loading, around a list of body widgets.
class HomeScaffold extends StatelessWidget {
  const HomeScaffold({
    super.key,
    required this.controller,
    required this.session,
    required this.roleBadge,
    required this.bodyBuilder,
    this.subtitle = 'Field Operations',
    this.onOpenProfile,
  });

  final HomeController controller;
  final Session session;
  final String roleBadge;
  final String subtitle;
  final VoidCallback? onOpenProfile;
  final List<Widget> Function(BuildContext context) bodyBuilder;

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
                roleBadge: roleBadge,
                userName: session.user?.name ?? '',
                subtitle: subtitle,
                onAccountTap: onOpenProfile,
              ),
              Expanded(
                child: controller.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                        onRefresh: () async => controller.retry(),
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(15, 16, 15, 24),
                          children: bodyBuilder(context),
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// The line under the alert banner: who is next, or what is happening.
String countdownLine(HomeController controller, DrainageAlert alert) {
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

class HomeAlertBanner extends StatelessWidget {
  const HomeAlertBanner({
    super.key,
    required this.controller,
    required this.alert,
    required this.onOpen,
  });

  final HomeController controller;
  final DrainageAlert alert;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    // Rebuilds every second for the countdown only.
    return ListenableBuilder(
      listenable: controller.countdown,
      builder: (context, _) => AlertBanner(
        stage: alert.stage,
        title: 'Stage ${alert.stage} alert',
        countdownText: countdownLine(controller, alert),
        onOpen: onOpen,
      ),
    );
  }
}

/// Shown when there is no open alert.
class HomeStatusCard extends StatelessWidget {
  const HomeStatusCard({super.key, required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
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
}

class HomeGaugeCard extends StatelessWidget {
  const HomeGaugeCard({super.key, required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
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
}

class HomeMetricsRow extends StatelessWidget {
  const HomeMetricsRow({super.key, required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    final node = controller.node;
    final stale = controller.isStale;
    final stage = node?.waterStage ?? 0;

    String? pct(double? v) => v == null ? null : v.round().toString();

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
}

/// Acknowledge / Add remark / Mark cleared, plus optional [extraActions]
/// (Reassign, Manage credited personnel) added by Level 2 and Level 3.
class HomeActionsCard extends StatelessWidget {
  const HomeActionsCard({
    super.key,
    required this.controller,
    required this.session,
    required this.alert,
    required this.onOpenAlert,
    required this.onAddRemark,
    this.onOfferCoResponders,
    this.extraActions = const <Widget>[],
  });

  final HomeController controller;
  final Session session;
  final DrainageAlert alert;
  final void Function(DrainageAlert alert) onOpenAlert;
  final void Function(DrainageAlert alert) onAddRemark;
  final void Function(DrainageAlert alert)? onOfferCoResponders;
  final List<Widget> extraActions;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final text = Theme.of(context).textTheme;
    final busy = controller.busy;

    final waitingForSensor = alert.status == AlertStatus.pendingConfirmation;
    final canAcknowledge = !alert.isAcknowledged && !waitingForSensor;

    return AppCard(
      title: 'Your response',
      subtitle: _responseLine(),
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
                  ? const ButtonSpinner()
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
                  style: bigOutlinedStyle(),
                  icon: const Icon(Icons.edit_note_rounded),
                  label: const Text('Add remark'),
                ),
              ),
              if (!waitingForSensor) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: busy ? null : () => _markCleared(context),
                    style: bigOutlinedStyle(),
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
          for (final extra in extraActions) ...[
            const SizedBox(height: 10),
            extra,
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

  String _responseLine() {
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
      showAppToast(context, 'Acknowledged. The escalation timer is stopped.');
      onOfferCoResponders?.call(updated);
    } on AlertException catch (e) {
      if (!context.mounted) return;
      showAppToast(context, alertFailureText(e.failure));
    } catch (_) {
      if (!context.mounted) return;
      showAppToast(context, alertFailureText(AlertFailure.unknown));
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
      showAppToast(context, 'Marked cleared. Waiting for the sensor to confirm.');
      onOfferCoResponders?.call(updated);
    } on AlertException catch (e) {
      if (!context.mounted) return;
      showAppToast(context, alertFailureText(e.failure));
    } catch (_) {
      if (!context.mounted) return;
      showAppToast(context, alertFailureText(AlertFailure.unknown));
    }
  }
}
