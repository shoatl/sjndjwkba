// lib/features/roles/admin/archive_vault_screen.dart
//
// Archived Users Vault (Admin only). Shows only what is kept after
// archiving: name, role, and service dates. Restoring needs a newly
// verified phone number. The person must then set new credentials and
// accept consent again.

import 'package:flutter/material.dart';

import '../../../core/data/user_repository.dart';
import '../../../core/models/drainage_models.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/time_format.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_ui.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/load_view.dart';
import '../../../shared/widgets/section_heading.dart';
import '../../../shared/widgets/sheet_helper.dart';

class ArchiveVaultScreen extends StatelessWidget {
  const ArchiveVaultScreen({super.key, required this.users});

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
      appBar: AppBar(title: const Text('Archived users')),
      body: LoadView<List<AppUser>>(
        load: users.fetchArchived,
        builder: (context, archived, reload) => RefreshIndicator(
          onRefresh: reload,
          child: _VaultList(users: users, archived: archived, reload: reload),
        ),
      ),
    );
  }
}

class _VaultList extends StatelessWidget {
  const _VaultList({
    required this.users,
    required this.archived,
    required this.reload,
  });

  final UserRepository users;
  final List<AppUser> archived;
  final Future<void> Function() reload;

  Future<void> _restore(BuildContext context, AppUser person) async {
    final done = await showAppSheet<bool>(
      context,
      title: 'Restore ${person.name}',
      subtitle: 'Verify a new phone number first.',
      builder: (sheetContext) => _RestoreForm(users: users, person: person),
    );
    if (done != true || !context.mounted) return;
    showAppToast(context, 'Account restored. They must set a new password.');
    await reload();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final text = Theme.of(context).textTheme;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(15, 16, 15, 24),
      children: [
        SectionHeading(
          eyebrow: 'Accounts',
          title: 'Archive vault',
          subtitle: 'Only name, role and service dates are kept.',
          trailing: AppPill(label: '${archived.length}'),
        ),
        const SizedBox(height: 14),
        if (archived.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 24),
            child: EmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'Nothing archived',
              message: 'Archived accounts will show up here.',
            ),
          )
        else
          for (final person in archived) ...[
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      PersonAvatar(name: person.name, size: 44),
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
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (person.serviceSpans.isEmpty)
                    Text(
                      'No service dates recorded.',
                      style: text.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    )
                  else
                    for (final span in person.serviceSpans)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          '${formatDate(span.start)} to '
                          '${span.end == null ? 'present' : formatDate(span.end!)}',
                          style: text.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () => _restore(context, person),
                    style: bigOutlinedStyle(),
                    icon: const Icon(Icons.restore_rounded),
                    label: const Text('Restore account'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
      ],
    );
  }
}

class _RestoreForm extends StatefulWidget {
  const _RestoreForm({required this.users, required this.person});

  final UserRepository users;
  final AppUser person;

  @override
  State<_RestoreForm> createState() => _RestoreFormState();
}

class _RestoreFormState extends State<_RestoreForm> {
  final TextEditingController _phone = TextEditingController();
  late UserRole _role;
  bool _working = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _role = widget.person.role;
  }

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _restore() async {
    final phone = _phone.text.trim();
    if (!looksLikePhone(phone)) {
      setState(() => _error = 'Enter a valid phone number (10 to 13 digits).');
      return;
    }
    setState(() {
      _working = true;
      _error = null;
    });
    try {
      await widget.users.restore(
        userId: widget.person.id,
        verifiedPhone: phone,
        newRole: _role == widget.person.role ? null : _role,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _working = false;
        _error = errorText(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _phone,
          enabled: !_working,
          keyboardType: TextInputType.phone,
          autofocus: true,
          decoration: appInputDecoration(
            context,
            label: 'New verified phone number',
            icon: Icons.phone_outlined,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'ROLE',
          style: text.labelSmall?.copyWith(
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final role in UserRole.values)
              ChoiceChip(
                label: Text(role.plainLabel),
                selected: _role == role,
                onSelected:
                    _working ? null : (_) => setState(() => _role = role),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'After restoring, the person sets a new password and accepts the '
          'privacy consent again.',
          style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          InlineError(message: _error!),
        ],
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _working ? null : _restore,
          style: bigFilledStyle(),
          child:
              _working ? const ButtonSpinner() : const Text('Restore account'),
        ),
      ],
    );
  }
}
