// lib/features/alerts/manage_credited_sheet.dart
//
// Manage Credited Personnel. Level 2, Level 3 and Admin can override who is
// credited on any alert. The server records every change in the incident
// timeline. Names only, never phone numbers.

import 'package:flutter/material.dart';

import '../../core/data/alert_repository.dart';
import '../../core/data/user_repository.dart';
import '../../core/models/drainage_models.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_ui.dart';
import '../../shared/widgets/load_view.dart';
import '../../shared/widgets/sheet_helper.dart';

class _CreditData {
  const _CreditData({required this.people, required this.names});

  /// Everyone who could be credited.
  final List<PersonSummary> people;

  /// Names for everyone on the list now and everyone who could be added.
  final Map<String, PersonSummary> names;
}

/// Returns the updated alert if the list was saved, else null.
Future<DrainageAlert?> showManageCreditedSheet(
  BuildContext context, {
  required DrainageAlert alert,
  required UserRepository users,
  required AlertRepository alerts,
}) {
  Future<_CreditData> load() async {
    final people = await users.fetchResponders();
    final names = <String, PersonSummary>{
      for (final p in people) p.id: p,
    };
    // Archived or unknown people already on the list still need a name.
    final missing = alert.creditedResponders
        .map((c) => c.userId)
        .where((id) => !names.containsKey(id))
        .toList(growable: false);
    if (missing.isNotEmpty) {
      try {
        names.addAll(await users.lookup(missing));
      } catch (_) {
        // They will show as "Unknown person".
      }
    }
    return _CreditData(people: people, names: names);
  }

  return showAppSheet<DrainageAlert>(
    context,
    title: 'Manage credited personnel',
    subtitle: 'Changes are recorded in the incident timeline.',
    builder: (sheetContext) => LoadView<_CreditData>(
      compact: true,
      load: load,
      builder: (context, data, reload) =>
          _CreditForm(alert: alert, data: data, alerts: alerts),
    ),
  );
}

class _CreditForm extends StatefulWidget {
  const _CreditForm({
    required this.alert,
    required this.data,
    required this.alerts,
  });

  final DrainageAlert alert;
  final _CreditData data;
  final AlertRepository alerts;

  @override
  State<_CreditForm> createState() => _CreditFormState();
}

class _CreditFormState extends State<_CreditForm> {
  late List<CreditedResponder> _list;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _list = List<CreditedResponder>.of(widget.alert.creditedResponders);
  }

  bool _isCredited(String userId) => _list.any((c) => c.userId == userId);

  void _setContribution(int index, Contribution value) {
    final old = _list[index];
    setState(() {
      _list[index] = CreditedResponder(
        userId: old.userId,
        role: old.role,
        contribution: value,
      );
    });
  }

  void _add(PersonSummary person) {
    setState(() {
      _list.add(
        CreditedResponder(
          userId: person.id,
          role: person.role,
          contribution: Contribution.supervisorAssigned,
        ),
      );
    });
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final updated = await widget.alerts.setCreditedResponders(
        widget.alert.id,
        List<CreditedResponder>.of(_list),
      );
      if (!mounted) return;
      Navigator.of(context).pop(updated);
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
    final scheme = context.colors;
    final text = Theme.of(context).textTheme;
    final addable = widget.data.people
        .where((p) => !_isCredited(p.id))
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'CREDITED NOW',
          style: text.labelSmall?.copyWith(
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 6),
        if (_list.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Nobody is credited yet.',
              style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        for (var i = 0; i < _list.length; i++)
          _CreditRow(
            name: nameOf(widget.data.names, _list[i].userId),
            role: _list[i].role,
            contribution: _list[i].contribution,
            enabled: !_saving,
            onContribution: (value) => _setContribution(i, value),
            onRemove: () => setState(() => _list.removeAt(i)),
          ),
        if (addable.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(
            'ADD A PERSON',
            style: text.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          for (final person in addable)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: PersonAvatar(name: person.name, size: 36),
              title: Text(person.name),
              subtitle: Text(person.role.plainLabel),
              trailing: IconButton(
                tooltip: 'Add ${person.name}',
                onPressed: _saving ? null : () => _add(person),
                icon: const Icon(Icons.add_circle_outline),
              ),
            ),
        ],
        if (_error != null) ...[
          const SizedBox(height: 8),
          InlineError(message: _error!),
        ],
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _saving ? null : _save,
          style: bigFilledStyle(),
          child: _saving ? const ButtonSpinner() : const Text('Save changes'),
        ),
      ],
    );
  }
}

class _CreditRow extends StatelessWidget {
  const _CreditRow({
    required this.name,
    required this.role,
    required this.contribution,
    required this.enabled,
    required this.onContribution,
    required this.onRemove,
  });

  final String name;
  final UserRole role;
  final Contribution contribution;
  final bool enabled;
  final ValueChanged<Contribution> onContribution;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          PersonAvatar(name: name, size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  role.plainLabel,
                  style: text.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<Contribution>(
            enabled: enabled,
            tooltip: 'Change contribution',
            onSelected: onContribution,
            itemBuilder: (context) => [
              for (final c in Contribution.values)
                PopupMenuItem<Contribution>(value: c, child: Text(c.label)),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    contribution.label,
                    style: text.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
          IconButton(
            tooltip: 'Remove $name',
            onPressed: enabled ? onRemove : null,
            icon: const Icon(Icons.remove_circle_outline),
          ),
        ],
      ),
    );
  }
}
