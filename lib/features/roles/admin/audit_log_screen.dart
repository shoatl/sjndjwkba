// lib/features/roles/admin/audit_log_screen.dart
//
// Master audit log (Admin only): role changes, escalations, and credit
// changes, newest first. Names come from the user repository.

import 'package:flutter/material.dart';

import '../../../core/data/config_repository.dart';
import '../../../core/data/user_repository.dart';
import '../../../core/models/drainage_models.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/time_format.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_ui.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/section_heading.dart';

class AuditLogScreen extends StatefulWidget {
  const AuditLogScreen({super.key, required this.configs, required this.users});

  final ConfigRepository configs;
  final UserRepository users;

  @override
  State<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends State<AuditLogScreen> {
  static const int _pageSize = 50;

  final List<TimelineEntry> _entries = <TimelineEntry>[];
  Map<String, PersonSummary> _names = <String, PersonSummary>{};
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    try {
      final page = await widget.configs.fetchAuditLog(limit: _pageSize);
      if (!mounted) return;
      setState(() {
        _entries
          ..clear()
          ..addAll(page);
        _hasMore = page.length >= _pageSize;
        _error = null;
        _loading = false;
      });
      await _loadNames(page);
    } catch (e) {
      if (!mounted) return;
      if (_entries.isEmpty) {
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
    if (_loadingMore || _entries.isEmpty) return;
    setState(() => _loadingMore = true);
    try {
      final page = await widget.configs.fetchAuditLog(
        limit: _pageSize,
        before: _entries.last.at,
      );
      if (!mounted) return;
      setState(() {
        _entries.addAll(page);
        _hasMore = page.length >= _pageSize;
        _loadingMore = false;
      });
      await _loadNames(page);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
      showAppToast(context, errorText(e));
    }
  }

  Future<void> _loadNames(List<TimelineEntry> page) async {
    final ids = <String>{
      for (final e in page)
        if (e.actorId != null && !_names.containsKey(e.actorId)) e.actorId!,
    };
    if (ids.isEmpty) return;
    try {
      final found = await widget.users.lookup(ids);
      if (!mounted) return;
      setState(() => _names = <String, PersonSummary>{..._names, ...found});
    } catch (_) {
      // Entries show "Unknown person" for ids the server did not return.
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final background = Color.alphaBlend(
      scheme.surfaceContainerHighest.withAlpha(90),
      scheme.surface,
    );

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(title: const Text('Audit log')),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return EmptyState(
        icon: Icons.cloud_off_outlined,
        title: 'Could not load the audit log',
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

    final scheme = context.colors;
    final text = Theme.of(context).textTheme;

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(15, 16, 15, 24),
        children: [
          const SectionHeading(
            eyebrow: 'System',
            title: 'Audit log',
            subtitle: 'Newest first.',
          ),
          const SizedBox(height: 14),
          if (_entries.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 24),
              child: EmptyState(
                icon: Icons.fact_check_outlined,
                title: 'Nothing logged yet',
                message: 'Role changes and escalations will show up here.',
              ),
            )
          else
            for (final entry in _entries) ...[
              AppCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.label,
                      style: text.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      entry.actorId == null
                          ? formatDateTime(entry.at)
                          : '${nameOf(_names, entry.actorId!)}, '
                              '${formatDateTime(entry.at)}',
                      style: text.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
          if (_hasMore)
            OutlinedButton(
              onPressed: _loadingMore ? null : _loadMore,
              style: bigOutlinedStyle(),
              child: _loadingMore
                  ? const ButtonSpinner(onFilled: false)
                  : const Text('Load more'),
            ),
        ],
      ),
    );
  }
}
