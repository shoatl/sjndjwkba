// lib/features/history/history_screen.dart
// Incident history with preserved filtering, search, pagination and alert navigation.

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
  const HistoryScreen({super.key, required this.session, required this.alerts, required this.onOpenAlert});
  final Session session;
  final AlertRepository alerts;
  final void Function(DrainageAlert alert) onOpenAlert;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  static const int _pageSize = 20;
  final List<DrainageAlert> _items = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = false;
  Object? _error;
  _HistoryFilter _filter = _HistoryFilter.all;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() { super.initState(); _refresh(); }

  @override
  void dispose() { _searchController.dispose(); super.dispose(); }

  Future<void> _refresh() async {
    try {
      final page = await widget.alerts.fetchHistory(limit: _pageSize);
      if (!mounted) return;
      setState(() { _items..clear()..addAll(page); _hasMore = page.length >= _pageSize; _error = null; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      if (_items.isEmpty) setState(() { _error = e; _loading = false; });
      else showAppToast(context, errorText(e));
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _items.isEmpty) return;
    final before = _items.last.pagingTime;
    if (before == null) { setState(() => _hasMore = false); return; }
    setState(() => _loadingMore = true);
    try {
      final page = await widget.alerts.fetchHistory(limit: _pageSize, before: before);
      if (!mounted) return;
      setState(() { _items.addAll(page); _hasMore = page.length >= _pageSize; _loadingMore = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
      showAppToast(context, errorText(e));
    }
  }

  List<DrainageAlert> get _visible {
    final filtered = switch (_filter) {
      _HistoryFilter.all => _items,
      _HistoryFilter.open => _items.where((a) => a.status.isActive).toList(growable: false),
      _HistoryFilter.cleared => _items.where((a) => !a.status.isActive).toList(growable: false),
    };
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return filtered;
    return filtered.where((alert) {
      final date = alert.startedAt == null ? '' : formatDateTime(alert.startedAt!);
      return ('Stage ${alert.stage} ${alert.status.label} $date').toLowerCase().contains(query);
    }).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final role = widget.session.role;
    final scheme = context.colors;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Incident History'),
        actions: [IconButton(onPressed: () {}, tooltip: 'Filter', icon: const Icon(Icons.filter_list_rounded))],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [scheme.primary.withAlpha(12), scheme.surface, scheme.surface]),
        ),
        child: _buildBody(context, role),
      ),
    );
  }

  Widget _buildBody(BuildContext context, UserRole? role) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return EmptyState(icon: Icons.cloud_off_outlined, title: 'Could not load history', message: errorText(_error!), actionLabel: 'Try again', onAction: () { setState(() { _error = null; _loading = true; }); _refresh(); });

    final visible = _visible;
    final mine = widget.session.user?.id;
    final scheme = context.colors;
    final openCount = _items.where((a) => a.status.isActive).length;
    final clearedCount = _items.length - openCount;
    final showMetrics = role == UserRole.level3 && _items.isNotEmpty;
    final onlyMine = !(role?.seesAllHistory ?? false);

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          Row(children: [
            Expanded(child: _SummaryTile(label: 'Total', value: _items.length.toString(), icon: Icons.warning_amber_rounded, color: scheme.primary)),
            const SizedBox(width: 8),
            Expanded(child: _SummaryTile(label: 'Open', value: openCount.toString(), icon: Icons.access_time_rounded, color: context.status.stage2)),
            const SizedBox(width: 8),
            Expanded(child: _SummaryTile(label: 'Cleared', value: clearedCount.toString(), icon: Icons.check_circle_outline, color: context.status.normal)),
          ]),
          const SizedBox(height: 14),
          if (showMetrics) ...[_MetricsCard(metrics: ResponseMetrics.from(_items)), const SizedBox(height: 14)],
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                icon: const Icon(Icons.search_rounded),
                hintText: 'Search incidents...',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                suffixIcon: _searchQuery.isEmpty ? null : IconButton(tooltip: 'Clear search', onPressed: () { _searchController.clear(); setState(() => _searchQuery = ''); }, icon: const Icon(Icons.close_rounded)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(children: [
            for (final filter in _HistoryFilter.values) ...[
              if (filter != _HistoryFilter.values.first) const SizedBox(width: 8),
              Expanded(child: _FilterChip(label: _filterLabel(filter), selected: _filter == filter, onTap: () => setState(() => _filter = filter))),
            ],
          ]),
          const SizedBox(height: 14),
          if (visible.isEmpty)
            EmptyState(icon: Icons.history_rounded, title: _items.isEmpty ? 'No incidents yet' : 'Nothing here', message: _items.isEmpty ? (onlyMine ? 'Incidents you take part in will show up here.' : 'Past incidents will show up here.') : 'No incidents match this filter.')
          else
            for (final alert in visible) ...[_IncidentCard(alert: alert, contribution: mine == null ? null : alert.contributionOf(mine), onTap: () => widget.onOpenAlert(alert)), const SizedBox(height: 12)],
          if (_hasMore)
            Padding(padding: const EdgeInsets.only(top: 4), child: OutlinedButton(onPressed: _loadingMore ? null : _loadMore, child: _loadingMore ? const ButtonSpinner(onFilled: false) : const Text('Load more'))),
        ],
      ),
    );
  }

  String _filterLabel(_HistoryFilter f) => switch (f) { _HistoryFilter.all => 'All', _HistoryFilter.open => 'Open', _HistoryFilter.cleared => 'Cleared' };
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({required this.label, required this.value, required this.icon, required this.color});
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return AppCard(padding: const EdgeInsets.fromLTRB(12, 13, 12, 12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: color, size: 20), const SizedBox(height: 8), Text(value, style: text.titleLarge?.copyWith(fontWeight: FontWeight.w900, color: color, fontFeatures: const [FontFeature.tabularFigures()])), const SizedBox(height: 2), Text(label, style: text.labelSmall?.copyWith(color: context.colors.onSurfaceVariant))]));
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(999), child: Container(height: 42, alignment: Alignment.center, decoration: BoxDecoration(color: selected ? scheme.primary : scheme.surfaceContainerHighest.withAlpha(170), borderRadius: BorderRadius.circular(999), border: Border.all(color: selected ? scheme.primary : scheme.outline.withAlpha(120)), boxShadow: selected ? [BoxShadow(color: scheme.primary.withAlpha(36), blurRadius: 12)] : null), child: Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: selected ? scheme.onPrimary : scheme.onSurfaceVariant, fontWeight: FontWeight.w700))));
  }
}

class _IncidentCard extends StatelessWidget {
  const _IncidentCard({required this.alert, required this.contribution, required this.onTap});
  final DrainageAlert alert;
  final Contribution? contribution;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final text = Theme.of(context).textTheme;
    final started = alert.startedAt;
    final color = alertColor(context, alert);

    return AppCard(accent: color, onTap: onTap, semanticLabel: 'Stage ${alert.stage} incident, ${alert.status.label}. Open details.', padding: const EdgeInsets.fromLTRB(14, 12, 14, 12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [AppPill(label: alert.status.label, color: color), const Spacer(), if (started != null) Text(formatDateTime(started), style: text.labelSmall?.copyWith(color: scheme.onSurfaceVariant))]),
      const SizedBox(height: 11),
      Text('Stage ${alert.stage} alert', style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
      const SizedBox(height: 4),
      Text(alert.status.isActive ? 'Current incident status: ${alert.status.label}' : 'Cleared and archived', style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
      const SizedBox(height: 10),
      Row(children: [if (contribution != null) AppPill(label: contribution!.label, icon: Icons.person_outline), const Spacer(), Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant)]),
    ]));
  }
}

class _MetricsCard extends StatelessWidget {
  const _MetricsCard({required this.metrics});
  final ResponseMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return AppCard(title: 'Response metrics', subtitle: 'From the ${metrics.total} incidents loaded', child: Row(children: [Expanded(child: MetricTile(label: 'To acknowledge', value: metrics.averageAcknowledge == null ? null : formatDuration(metrics.averageAcknowledge!), icon: Icons.timer_outlined, caption: 'Average')), const SizedBox(width: 10), Expanded(child: MetricTile(label: 'To clear', value: metrics.averageClear == null ? null : formatDuration(metrics.averageClear!), icon: Icons.task_alt_rounded, caption: 'Average'))]));
  }
}
