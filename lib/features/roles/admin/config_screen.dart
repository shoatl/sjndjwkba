// lib/features/roles/admin/config_screen.dart
//
// System and Escalation Configuration (Admin only): the escalation timeout
// and the stale-data threshold. Settings live on the server, so a change
// applies without redeploying the app. The master audit log opens from here.

import 'package:flutter/material.dart';

import '../../../core/data/config_repository.dart';
import '../../../core/data/user_repository.dart';
import '../../../core/models/drainage_models.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_ui.dart';
import '../../../shared/widgets/load_view.dart';
import '../../../shared/widgets/section_heading.dart';
import 'audit_log_screen.dart';

class ConfigScreen extends StatelessWidget {
  const ConfigScreen({super.key, required this.configs, required this.users});

  final ConfigRepository configs;

  /// Used by the audit log to turn user ids into names.
  final UserRepository users;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final background = Color.alphaBlend(
      scheme.surfaceContainerHighest.withAlpha(90),
      scheme.surface,
    );

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(title: const Text('Config')),
      body: LoadView<SystemConfig>(
        load: configs.fetch,
        builder: (context, config, reload) => RefreshIndicator(
          onRefresh: reload,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(15, 16, 15, 24),
            children: [
              const SectionHeading(
                eyebrow: 'System',
                title: 'Escalation settings',
                subtitle: 'Changes apply to everyone without an app update.',
              ),
              const SizedBox(height: 14),
              _ConfigForm(configs: configs, initial: config),
              const SizedBox(height: 14),
              AppCard(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) =>
                          AuditLogScreen(configs: configs, users: users),
                    ),
                  );
                },
                semanticLabel: 'Open the audit log',
                child: Row(
                  children: [
                    Icon(Icons.fact_check_outlined, color: scheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Audit log',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            'Role changes and escalations.',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: scheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConfigForm extends StatefulWidget {
  const _ConfigForm({required this.configs, required this.initial});

  final ConfigRepository configs;
  final SystemConfig initial;

  @override
  State<_ConfigForm> createState() => _ConfigFormState();
}

class _ConfigFormState extends State<_ConfigForm> {
  late int _savedEscalation;
  late int _savedStale;
  late int _escalation;
  late int _stale;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _savedEscalation = _minutes(widget.initial.escalationTimeout);
    _savedStale = _minutes(widget.initial.staleAfter);
    _escalation = _savedEscalation;
    _stale = _savedStale;
  }

  /// Whole minutes, never below 1, so a saved value is always valid.
  static int _minutes(Duration d) {
    final m = d.inMinutes;
    return m < 1 ? 1 : m;
  }

  bool get _changed =>
      _escalation != _savedEscalation || _stale != _savedStale;

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final stored = await widget.configs.update(
        SystemConfig(
          escalationTimeout: Duration(minutes: _escalation),
          staleAfter: Duration(minutes: _stale),
        ),
      );
      if (!mounted) return;
      setState(() {
        _savedEscalation = _minutes(stored.escalationTimeout);
        _savedStale = _minutes(stored.staleAfter);
        _escalation = _savedEscalation;
        _stale = _savedStale;
        _saving = false;
      });
      showAppToast(context, 'Settings saved.');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = errorText(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      title: 'Timers',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _MinuteStepper(
            label: 'Escalation timeout',
            help: 'How long an unacknowledged alert waits before it moves '
                'to the next level.',
            value: _escalation,
            min: 1,
            max: 120,
            enabled: !_saving,
            onChanged: (v) => setState(() => _escalation = v),
          ),
          const Divider(height: 28),
          _MinuteStepper(
            label: 'Stale data after',
            help: 'How long without a node report before the app shows '
                '"No recent data".',
            value: _stale,
            min: 1,
            max: 240,
            enabled: !_saving,
            onChanged: (v) => setState(() => _stale = v),
          ),
          if (_error != null) ...[
            const SizedBox(height: 14),
            InlineError(message: _error!),
          ],
          const SizedBox(height: 18),
          FilledButton(
            onPressed: (_saving || !_changed) ? null : _save,
            style: bigFilledStyle(),
            child: _saving ? const ButtonSpinner() : const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _MinuteStepper extends StatelessWidget {
  const _MinuteStepper({
    required this.label,
    required this.help,
    required this.value,
    required this.min,
    required this.max,
    required this.enabled,
    required this.onChanged,
  });

  final String label;
  final String help;
  final int value;
  final int min;
  final int max;
  final bool enabled;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 2),
        Text(
          help,
          style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            IconButton.outlined(
              tooltip: 'Less',
              onPressed:
                  (enabled && value > min) ? () => onChanged(value - 1) : null,
              icon: const Icon(Icons.remove_rounded),
            ),
            Expanded(
              child: Semantics(
                label: '$label: $value minutes',
                excludeSemantics: true,
                child: Text(
                  '$value min',
                  textAlign: TextAlign.center,
                  style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
            ),
            IconButton.outlined(
              tooltip: 'More',
              onPressed:
                  (enabled && value < max) ? () => onChanged(value + 1) : null,
              icon: const Icon(Icons.add_rounded),
            ),
          ],
        ),
      ],
    );
  }
}
