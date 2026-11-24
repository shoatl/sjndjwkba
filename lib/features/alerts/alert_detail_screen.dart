// lib/features/alerts/alert_detail_screen.dart
//
// Alert Detail: summary, who acknowledged and cleared, the actions this role
// may use, the photo slot ("Image pending" until photos are decided),
// the incident timeline, credited responders, and remarks.
//
// The server enforces permissions. Hiding buttons here is for usability.
// Alerts hold user ids only, so names are looked up through UserRepository
// (names only, never phone numbers).

import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/auth/session.dart';
import '../../core/data/alert_repository.dart';
import '../../core/data/user_repository.dart';
import '../../core/models/drainage_models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/countdown.dart';
import '../../core/utils/time_format.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/app_ui.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/sheet_helper.dart';
import '../history/response_metrics.dart';
import '../roles/level2_official/reassign_sheet.dart';
import 'co_responder_sheet.dart';
import 'manage_credited_sheet.dart';
import 'remark_sheet.dart';

class AlertDetailScreen extends StatefulWidget {
  const AlertDetailScreen({
    super.key,
    required this.alertId,
    required this.session,
    required this.alerts,
    required this.users,
    this.initial,
  });

  final String alertId;
  final Session session;
  final AlertRepository alerts;
  final UserRepository users;

  /// Show this right away while the latest copy loads.
  final DrainageAlert? initial;

  @override
  State<AlertDetailScreen> createState() => _AlertDetailScreenState();
}

class _AlertDetailScreenState extends State<AlertDetailScreen> {
  final CountdownController _countdown = CountdownController();

  DrainageAlert? _alert;
  Map<String, PersonSummary> _names = <String, PersonSummary>{};
  Object? _error;
  bool _busy = false;
  StreamSubscription<DrainageAlert?>? _sub;

  @override
  void initState() {
    super.initState();
    final first = widget.initial;
    if (first != null) {
      _alert = first;
      _updateCountdown(first);
      _loadNames(first);
    }
    _load();
    _sub = widget.alerts.watchActiveAlert().listen(
      (a) {
        if (a != null && a.id == widget.alertId) _apply(a);
      },
      onError: (Object _) {
        // The pull-to-refresh still works.
      },
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    _countdown.dispose();
    super.dispose();
  }

  // ---- Loading -------------------------------------------------------------

  void _updateCountdown(DrainageAlert a) {
    final running =
        a.status.isActive && !a.isAcknowledged && a.timerDeadline != null;
    _countdown.update(deadline: running ? a.timerDeadline : null);
  }

  Future<void> _load() async {
    try {
      final fresh = await widget.alerts.fetchAlert(widget.alertId);
      if (!mounted) return;
      await _apply(fresh);
    } catch (e) {
      if (!mounted) return;
      if (_alert == null) {
        setState(() => _error = e);
      } else {
        showAppToast(context, errorText(e));
      }
    }
  }

  Future<void> _apply(DrainageAlert a) async {
    if (!mounted) return;
    setState(() {
      _alert = a;
      _error = null;
    });
    _updateCountdown(a);
    await _loadNames(a);
  }

  Future<void> _loadNames(DrainageAlert a) async {
    final ids = <String>{
      if (a.acknowledgedBy != null) a.acknowledgedBy!.userId,
      if (a.clearedBy != null) a.clearedBy!.userId,
      for (final c in a.creditedResponders) c.userId,
      for (final r in a.remarks) r.authorId,
      for (final t in a.timeline)
        if (t.actorId != null) t.actorId!,
    };
    if (ids.isEmpty) return;
    try {
      final found = await widget.users.lookup(ids);
      if (!mounted) return;
      setState(() => _names = found);
    } catch (_) {
      // Names stay as "Unknown person".
    }
  }

  // ---- Actions -------------------------------------------------------------

  Future<DrainageAlert?> _run(
    Future<DrainageAlert> Function() action,
    String successMessage,
  ) async {
    if (_busy) return null;
    setState(() => _busy = true);
    try {
      final updated = await action();
      if (!mounted) return null;
      await _apply(updated);
      if (!mounted) return null;
      showAppToast(context, successMessage);
      return updated;
    } catch (e) {
      if (!mounted) return null;
      showAppToast(context, errorText(e));
      return null;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _offerCoResponders(DrainageAlert alert) async {
    final me = widget.session.user?.id;
    if (me == null) return;
    final updated = await showCoResponderSheet(
      context,
      alert: alert,
      currentUserId: me,
      users: widget.users,
      alerts: widget.alerts,
    );
    if (updated != null && mounted) {
      await _apply(updated);
      if (!mounted) return;
      showAppToast(context, 'Co-responders added.');
    }
  }

  Future<void> _acknowledge(DrainageAlert alert) async {
    final updated = await _run(
      () => widget.alerts.acknowledge(alert.id),
      'Acknowledged. The escalation timer is stopped.',
    );
    if (updated != null && mounted) await _offerCoResponders(updated);
  }

  Future<void> _markCleared(DrainageAlert alert) async {
    final confirmed = await showConfirmSheet(
      context,
      title: 'Mark as cleared?',
      message: 'The sensor will check that water is below Stage 1. '
          'If it is not, the alert reopens by itself.',
      confirmLabel: 'Mark cleared',
    );
    if (!confirmed || !mounted) return;
    final updated = await _run(
      () => widget.alerts.markCleared(alert.id),
      'Marked cleared. Waiting for the sensor to confirm.',
    );
    if (updated != null && mounted) await _offerCoResponders(updated);
  }

  Future<void> _addRemark(DrainageAlert alert) async {
    final posted = await showRemarkSheet(
      context,
      onSubmit: (text) async {
        final updated = await widget.alerts.addRemark(alert.id, text);
        await _apply(updated);
      },
    );
    if (posted && mounted) showAppToast(context, 'Remark added.');
  }

  Future<void> _reassign(DrainageAlert alert) async {
    final updated = await showReassignSheet(
      context,
      alert: alert,
      users: widget.users,
      alerts: widget.alerts,
    );
    if (updated != null && mounted) {
      await _apply(updated);
      if (!mounted) return;
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
      await _apply(updated);
      if (!mounted) return;
      showAppToast(context, 'Credited personnel updated.');
    }
  }

  // ---- Build ---------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final alert = _alert;

    final background = Color.alphaBlend(
      scheme.surfaceContainerHighest.withAlpha(90),
      scheme.surface,
    );

    Widget body;
    if (alert == null) {
      body = _error != null
          ? EmptyState(
              icon: Icons.cloud_off_outlined,
              title: 'Could not load this alert',
              message: errorText(_error!),
              actionLabel: 'Try again',
              onAction: () {
                setState(() => _error = null);
                _load();
              },
            )
          : const Center(child: CircularProgressIndicator());
    } else {
      body = RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(15, 16, 15, 28),
          children: [
            _SummaryCard(alert: alert, names: _names, countdown: _countdown),
            const SizedBox(height: 14),
            ..._actionsFor(alert),
            const _PhotoCard(),
            const SizedBox(height: 14),
            _TimelineCard(alert: alert, names: _names),
            const SizedBox(height: 14),
            _CreditedCard(alert: alert, names: _names),
            const SizedBox(height: 14),
            _RemarksCard(alert: alert, names: _names),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(title: const Text('Alert details')),
      body: body,
    );
  }

  List<Widget> _actionsFor(DrainageAlert alert) {
    final role = widget.session.role;
    if (role == null) return const <Widget>[];

    final active = alert.status.isActive;
    final waiting = alert.status == AlertStatus.pendingConfirmation;
    final canAcknowledge =
        role.canRespond && active && !alert.isAcknowledged && !waiting;
    final canRemark = role.canRespond && active;
    final canClear = role.canRespond && active && !waiting;
    final canReassign = role.canReassign && active;
    final canManage = role.canManageCredits;

    if (!canAcknowledge &&
        !canRemark &&
        !canClear &&
        !canReassign &&
        !canManage) {
      return const <Widget>[];
    }

    final text = Theme.of(context).textTheme;

    return [
      AppCard(
        title: 'Actions',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (canAcknowledge) ...[
              FilledButton.icon(
                onPressed: _busy ? null : () => _acknowledge(alert),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(64),
                  textStyle: text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: _busy
                    ? const ButtonSpinner()
                    : const Icon(Icons.check_rounded, size: 26),
                label: const Text('Acknowledge'),
              ),
              const SizedBox(height: 10),
            ],
            if (canRemark || canClear)
              Row(
                children: [
                  if (canRemark)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _busy ? null : () => _addRemark(alert),
                        style: bigOutlinedStyle(),
                        icon: const Icon(Icons.edit_note_rounded),
                        label: const Text('Add remark'),
                      ),
                    ),
                  if (canRemark && canClear) const SizedBox(width: 10),
                  if (canClear)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _busy ? null : () => _markCleared(alert),
                        style: bigOutlinedStyle(),
                        icon: const Icon(Icons.task_alt_rounded),
                        label: const Text('Mark cleared'),
                      ),
                    ),
                ],
              ),
            if (canReassign) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _busy ? null : () => _reassign(alert),
                style: bigOutlinedStyle(),
                icon: const Icon(Icons.swap_horiz_rounded),
                label: const Text('Reassign'),
              ),
            ],
            if (canManage) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _busy ? null : () => _manageCredited(alert),
                style: bigOutlinedStyle(),
                icon: const Icon(Icons.groups_outlined),
                label: const Text('Manage credited personnel'),
              ),
            ],
          ],
        ),
      ),
      const SizedBox(height: 14),
    ];
  }
}

// ---- Cards -------------------------------------------------------------------

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.alert,
    required this.names,
    required this.countdown,
  });

  final DrainageAlert alert;
  final Map<String, PersonSummary> names;
  final CountdownController countdown;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final text = Theme.of(context).textTheme;
    final started = alert.startedAt;
    final ack = alert.acknowledgedBy;
    final cleared = alert.clearedBy;

    return AppCard(
      accent: alertColor(context, alert),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AppPill(
                label: 'Stage ${alert.stage}',
                color: context.status.forStage(alert.stage),
              ),
              AppPill(
                label: alert.status.label,
                color: alertColor(context, alert),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Stage ${alert.stage} alert',
            style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          if (started != null) ...[
            const SizedBox(height: 2),
            Text(
              'Started ${formatDateTime(started)}',
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
          const SizedBox(height: 10),
          if (alert.status.isActive && !alert.isAcknowledged)
            ListenableBuilder(
              listenable: countdown,
              builder: (context, _) {
                final String line;
                if (alert.status == AlertStatus.critical) {
                  line = 'Critical, unacknowledged';
                } else if (alert.status == AlertStatus.pendingConfirmation) {
                  line = 'Waiting for the sensor to confirm';
                } else if (alert.escalationLevel >= 3) {
                  line = 'Captain notified';
                } else if (!countdown.hasDeadline) {
                  line = 'Level ${alert.escalationLevel} notified';
                } else if (countdown.isExpired) {
                  line = 'Escalating...';
                } else {
                  line = 'Level ${alert.escalationLevel + 1} in '
                      '${countdown.text}';
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    line,
                    style: text.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                );
              },
            ),
          InfoRow(
            label: 'Notified',
            value: 'Level ${alert.escalationLevel}',
          ),
          InfoRow(
            label: 'Acknowledged by',
            value: ack == null
                ? 'Nobody yet'
                : '${nameOf(names, ack.userId)}, ${formatClock(ack.at)}',
          ),
          InfoRow(
            label: 'Cleared by',
            value: cleared == null
                ? 'Not cleared'
                : '${nameOf(names, cleared.userId)}, '
                    '${formatClock(cleared.at)}',
          ),
          if (alert.timeToAcknowledge != null)
            InfoRow(
              label: 'Time to respond',
              value: formatDuration(alert.timeToAcknowledge!),
            ),
        ],
      ),
    );
  }
}

class _PhotoCard extends StatelessWidget {
  const _PhotoCard();

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final text = Theme.of(context).textTheme;

    return AppCard(
      title: 'Site photo',
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withAlpha(160),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.image_outlined,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Image pending',
                  style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  'A photo from the node will show here when it arrives.',
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

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({required this.alert, required this.names});

  final DrainageAlert alert;
  final Map<String, PersonSummary> names;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final text = Theme.of(context).textTheme;
    final entries = List<TimelineEntry>.of(alert.timeline)
      ..sort((a, b) => a.at.compareTo(b.at));

    return AppCard(
      title: 'Timeline',
      subtitle: 'Who was notified, and what happened',
      child: entries.isEmpty
          ? Text(
              'Nothing recorded yet.',
              style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            )
          : Column(
              children: [
                for (var i = 0; i < entries.length; i++)
                  _TimelineRow(
                    entry: entries[i],
                    actor: entries[i].actorId == null
                        ? null
                        : nameOf(names, entries[i].actorId!),
                    isLast: i == entries.length - 1,
                  ),
              ],
            ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.entry,
    required this.actor,
    required this.isLast,
  });

  final TimelineEntry entry;
  final String? actor;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final text = Theme.of(context).textTheme;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                const SizedBox(height: 4),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: scheme.outline.withAlpha(90),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.label,
                    style: text.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    actor == null
                        ? formatDateTime(entry.at)
                        : '$actor, ${formatDateTime(entry.at)}',
                    style: text.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CreditedCard extends StatelessWidget {
  const _CreditedCard({required this.alert, required this.names});

  final DrainageAlert alert;
  final Map<String, PersonSummary> names;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final text = Theme.of(context).textTheme;

    return AppCard(
      title: 'Credited responders',
      child: alert.creditedResponders.isEmpty
          ? Text(
              'Nobody is credited yet.',
              style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            )
          : Column(
              children: [
                for (final c in alert.creditedResponders)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        PersonAvatar(name: nameOf(names, c.userId), size: 36),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                nameOf(names, c.userId),
                                style: text.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                c.role.plainLabel,
                                style: text.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(child: AppPill(label: c.contribution.label)),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}

class _RemarksCard extends StatelessWidget {
  const _RemarksCard({required this.alert, required this.names});

  final DrainageAlert alert;
  final Map<String, PersonSummary> names;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final text = Theme.of(context).textTheme;
    final remarks = List<AlertRemark>.of(alert.remarks)
      ..sort((a, b) => a.at.compareTo(b.at));

    return AppCard(
      title: 'Remarks',
      subtitle: remarks.isEmpty
          ? null
          : '${remarks.length} remark${remarks.length == 1 ? '' : 's'}',
      child: remarks.isEmpty
          ? Text(
              'No remarks yet.',
              style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < remarks.length; i++) ...[
                  if (i > 0) const Divider(height: 24),
                  Text(
                    '${nameOf(names, remarks[i].authorId)}, '
                    '${formatDateTime(remarks[i].at)}',
                    style: text.labelMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(remarks[i].text, style: text.bodyMedium),
                ],
              ],
            ),
    );
  }
}
