// lib/features/roles/level2_official/reassign_sheet.dart
//
// Level 2 and 3: hand the alert to a specific Level 1 or Level 2 person.
// Names only. The server enforces who may reassign.

import 'package:flutter/material.dart';

import '../../../core/data/alert_repository.dart';
import '../../../core/data/user_repository.dart';
import '../../../core/models/drainage_models.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_ui.dart';
import '../../../shared/widgets/load_view.dart';
import '../../../shared/widgets/sheet_helper.dart';

/// Returns the updated alert if it was reassigned, else null.
Future<DrainageAlert?> showReassignSheet(
  BuildContext context, {
  required DrainageAlert alert,
  required UserRepository users,
  required AlertRepository alerts,
}) {
  return showAppSheet<DrainageAlert>(
    context,
    title: 'Reassign alert',
    subtitle: 'Choose a Level 1 or Level 2 person to take over.',
    builder: (sheetContext) => LoadView<List<PersonSummary>>(
      compact: true,
      load: () => users.fetchResponders(
        roles: <UserRole>{UserRole.level1, UserRole.level2},
      ),
      builder: (context, people, reload) =>
          _ReassignForm(alert: alert, people: people, alerts: alerts),
    ),
  );
}

class _ReassignForm extends StatefulWidget {
  const _ReassignForm({
    required this.alert,
    required this.people,
    required this.alerts,
  });

  final DrainageAlert alert;
  final List<PersonSummary> people;
  final AlertRepository alerts;

  @override
  State<_ReassignForm> createState() => _ReassignFormState();
}

class _ReassignFormState extends State<_ReassignForm> {
  String? _selectedId;
  bool _saving = false;
  String? _error;

  Future<void> _save() async {
    final id = _selectedId;
    if (id == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final updated = await widget.alerts.reassign(widget.alert.id, id);
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

    if (widget.people.isEmpty) {
      return Text(
        'No Level 1 or Level 2 people are available.',
        style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final person in widget.people)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: _selectedId == person.id
                  ? scheme.primaryContainer.withAlpha(120)
                  : scheme.surfaceContainerHighest.withAlpha(90),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _saving
                    ? null
                    : () => setState(() => _selectedId = person.id),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      PersonAvatar(name: person.name),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              person.name,
                              style: text.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              person.role.plainLabel,
                              style: text.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        _selectedId == person.id
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: _selectedId == person.id
                            ? scheme.primary
                            : scheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        if (_error != null) ...[
          const SizedBox(height: 4),
          InlineError(message: _error!),
        ],
        const SizedBox(height: 12),
        FilledButton(
          onPressed: (_saving || _selectedId == null) ? null : _save,
          style: bigFilledStyle(),
          child: _saving ? const ButtonSpinner() : const Text('Reassign'),
        ),
      ],
    );
  }
}
