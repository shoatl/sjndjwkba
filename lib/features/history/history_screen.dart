// lib/features/history/history_screen.dart
//
// Role-scoped incident list. The server decides what each role may see:
// Level 1 gets only incidents they are credited on (shown with a
// contribution badge), Level 2 and 3 get all of them. Level 3 also sees
// response-time metrics at the top.

import 'package:flutter/material.dart';

import '../../core/auth/session.dart';
import '../../core/data/alert_repository.dart';
import '../../core/models/drainage_models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/time_format.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/app_ui.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/metric_tile.dart';
import '../../shared/widgets/section_heading.dart';
import 'response_metrics.dart';

enum _HistoryFilter { all, open, cleared }

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({
    super.key,
    required this.session,
    required this.alerts,
    required this.onOpenAlert,
  });

  final Session session;
  final AlertRepository alerts;
  final void Function(DrainageAlert alert) onOpenAlert;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  static const int _pageSize = 20;

  final List<DrainageAlert> _items = <DrainageAlert>[];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = false;
  Object? _error;
  _HistoryFilter _filter = _HistoryFilter.all;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    try {
      final page = await widget.alerts.fetchHistory(limit: _pageSize);
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(page);
        _hasMore = page.length >= _pageSize;
        _error = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      if (_items.isEmpty) {
        setState(() {
          _error = e;
          _loading = false;
        });
      } else {
        showAppToast(context, errorText(e));
      }
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _items.isEmpty) return;
    final before = _items.last.pagingTime;
    if (before == null) {
      setState(() => _hasMore = false);
      return;
    }
    setState(() => _loadingMore = true);
    try {
      final page = await widget.alerts.fetchHistory(
        limit: _pageSize,
        before: before,
      );
      if (!mounted) return;
      setState(() {
        _items.addAll(page);
        _hasMore = page.length >= _pageSize;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
      showAppToast(context, errorText(e));
    }
  }

  List<DrainageAlert> get _visible {
    switch (_filter) {
      case _HistoryFilter.all:
        return _items;
      case _HistoryFilter.open:
        return _items.where((a) => a.status.isActive).toList(growable: false);
      case _HistoryFilter.cleared:
        return _items.where((a) => !a.status.isActive).toList(growable: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final background = Color.alphaBlend(
      scheme.surfaceContainerHighest.withAlpha(90),
      scheme.surface,
    );
    final role = widget.session.role;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(title: const Text('History')),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [scheme.surfaceContainerHighest.withAlpha(105), scheme.surface, scheme.surface],
          ),
        ),
        child: _buildBody(context, role),
      ),
    );
  }

  Widget _buildBody(BuildContext context, UserRole? role) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return EmptyState(
        icon: Icons.cloud_off_outlined,
        title: 'Could not load history',
        message: errorText(_error!),
        actionLabel: 'Try again',
        onAction: () {
          setState(() {
            _error = null;
            _loading = true;
          });
          _refresh();
        },
      );
    }

    final visible = _visible;
    final mine = widget.session.user?.id;
    final showMetrics = role == UserRole.level3 && _items.isNotEmpty;
    final onlyMine = !(role?.seesAllHistory ?? false);

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 28),
        children: [
          SectionHeading(
            eyebrow: onlyMine ? 'Your incidents' : 'All incidents',
            title: 'History',
            subtitle: onlyMine
                ? 'Incidents where you are credited.'
                : 'Newest first.',
          ),
          const SizedBox(height: 14),
          if (showMetrics) ...[
            _MetricsCard(metrics: ResponseMetrics.from(_items)),
            const SizedBox(height: 14),
          ],
          Wrap(
            spacing: 8,
            children: [
              for (final f in _HistoryFilter.values)
                ChoiceChip(
                  label: Text(_filterLabel(f)),
                  selected: _filter == f,
                  onSelected: (_) => setState(() => _filter = f),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (visible.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: EmptyState(
                icon: Icons.history_rounded,
                title: _items.isEmpty ? 'No incidents yet' : 'Nothing here',
                message: _items.isEmpty
                    ? (onlyMine
                        ? 'Incidents you take part in will show up here.'
                        : 'Past incidents will show up here.')
                    : 'No incidents match this filter.',
              ),
            )
          else
            for (final alert in visible) ...[
              _IncidentCard(
                alert: alert,
                contribution: mine == null ? null : alert.contributionOf(mine),
                onTap: () => widget.onOpenAlert(alert),
              ),
              const SizedBox(height: 12),
            ],
          if (_hasMore)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: OutlinedButton(
                onPressed: _loadingMore ? null : _loadMore,
                style: bigOutlinedStyle(),
                child: _loadingMore
                    ? const ButtonSpinner(onFilled: false)
                    : const Text('Load more'),
              ),
            ),
        ],
      ),
    );
  }

  String _filterLabel(_HistoryFilter f) {
    switch (f) {
      case _HistoryFilter.all:
        return 'All';
      case _HistoryFilter.open:
        return 'Open';
      case _HistoryFilter.cleared:
        return 'Cleared';
    }
  }
}

class _MetricsCard extends StatelessWidget {
  const _MetricsCard({required this.metrics});

  final ResponseMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      title: 'Response metrics',
      subtitle: 'From the ${metrics.total} incidents loaded',
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: MetricTile(
                  label: 'To acknowledge',
                  value: metrics.averageAcknowledge == null
                      ? null
                      : formatDuration(metrics.averageAcknowledge!),
                  icon: Icons.timer_outlined,
                  caption: 'Average',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: MetricTile(
                  label: 'To clear',
                  value: metrics.averageClear == null
                      ? null
                      : formatDuration(metrics.averageClear!),
                  icon: Icons.task_alt_rounded,
                  caption: 'Average',
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          InfoRow(label: 'Unacknowledged', value: '${metrics.unacknowledged}'),
          InfoRow(label: 'Still open', value: '${metrics.active}'),
        ],
      ),
    );
  }
}

class _IncidentCard extends StatelessWidget {
  const _IncidentCard({
    required this.alert,
    required this.contribution,
    required this.onTap,
  });

  final DrainageAlert alert;
  final Contribution? contribution;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final text = Theme.of(context).textTheme;
    final started = alert.startedAt;
    final ack = alert.acknowledgedBy;
    final cleared = alert.clearedBy;

    final String ackLine;
    if (ack != null) {
      final took = alert.timeToAcknowledge;
      ackLine = took == null
          ? 'Acknowledged at ${formatClock(ack.at)}'
          : 'Acknowledged in ${formatDuration(took)}';
    } else if (cleared != null) {
      ackLine = 'Cleared on site, not acknowledged';
    } else {
      ackLine = 'Not acknowledged';
    }

    return AppCard(
      accent: alertColor(context, alert),
      onTap: onTap,
      semanticLabel: 'Stage ${alert.stage} incident, ${alert.status.label}. '
          'Open details.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Stage ${alert.stage} alert',
                  style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
            ],
          ),
          if (started != null)
            Text(
              formatDateTime(started),
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AppPill(
                label: alert.status.label,
                color: alertColor(context, alert),
              ),
              if (contribution != null)
                AppPill(
                  label: contribution!.label,
                  icon: Icons.person_outline,
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            ackLine,
            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
