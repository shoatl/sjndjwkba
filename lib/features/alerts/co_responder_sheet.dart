// lib/features/alerts/co_responder_sheet.dart
//
// "Who else is responding with you?" Offered after Acknowledge or Mark
// cleared. Optional: the person can skip. Shows NAMES ONLY, never phone
// numbers (the repository returns PersonSummary, which has no phone).

import 'package:flutter/material.dart';

import '../../core/data/alert_repository.dart';
import '../../core/data/user_repository.dart';
import '../../core/models/drainage_models.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_ui.dart';
import '../../shared/widgets/load_view.dart';
import '../../shared/widgets/sheet_helper.dart';

/// Returns the updated alert if co-responders were added, else null.
Future<DrainageAlert?> showCoResponderSheet(
  BuildContext context, {
  required DrainageAlert alert,
  required String currentUserId,
  required UserRepository users,
  required AlertRepository alerts,
}) {
  return showAppSheet<DrainageAlert>(
    context,
    title: 'Who else is responding with you?',
    subtitle: 'Optional. They will be credited on this incident.',
    builder: (sheetContext) => LoadView<List<PersonSummary>>(
      compact: true,
      load: () => users.fetchResponders(),
      builder: (context, people, reload) => _CoResponderForm(
        alert: alert,
        people: people
            .where((p) => p.id != currentUserId)
            .toList(growable: false),
        alerts: alerts,
      ),
    ),
  );
}

class _CoResponderForm extends StatefulWidget {
  const _CoResponderForm({
    required this.alert,
    required this.people,
    required this.alerts,
  });

  final DrainageAlert alert;
  final List<PersonSummary> people;
  final AlertRepository alerts;

  @override
  State<_CoResponderForm> createState() => _CoResponderFormState();
}

class _CoResponderFormState extends State<_CoResponderForm> {
  final Set<String> _picked = <String>{};
  bool _saving = false;
  String? _error;

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final updated = await widget.alerts.addCoResponders(
        widget.alert.id,
        _picked.toList(growable: false),
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

    if (widget.people.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'No other responders are available to add.',
            style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: bigOutlinedStyle(),
            child: const Text('Close'),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final person in widget.people)
          CheckboxListTile(
            value: _picked.contains(person.id),
            onChanged: _saving
                ? null
                : (checked) {
                    setState(() {
                      if (checked ?? false) {
                        _picked.add(person.id);
                      } else {
                        _picked.remove(person.id);
                      }
                    });
                  },
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.trailing,
            secondary: PersonAvatar(name: person.name),
            title: Text(
              person.name,
              style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(person.role.plainLabel),
          ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          InlineError(message: _error!),
        ],
        const SizedBox(height: 16),
        FilledButton(
          onPressed: (_saving || _picked.isEmpty) ? null : _save,
          style: bigFilledStyle(),
          child: _saving
              ? const ButtonSpinner()
              : Text(
                  _picked.isEmpty
                      ? 'Add co-responders'
                      : 'Add ${_picked.length} co-responder'
                          '${_picked.length == 1 ? '' : 's'}',
                ),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          child: const Text('Skip'),
        ),
      ],
    );
  }
}
