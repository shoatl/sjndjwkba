// lib/features/roles/admin/approvals_screen.dart
//
// Pending Approval queue (Admin only). For each request the Admin verifies
// the person's identity, corrects the name and phone number, assigns the
// role, then approves or rejects. Nobody ever picks their own role.
//
// The server enforces that only an Admin can do this.

import 'package:flutter/material.dart';

import '../../../core/data/user_repository.dart';
import '../../../core/models/drainage_models.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_ui.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/load_view.dart';
import '../../../shared/widgets/section_heading.dart';
import '../../../shared/widgets/sheet_helper.dart';

class ApprovalsScreen extends StatelessWidget {
  const ApprovalsScreen({super.key, required this.users});

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
      appBar: AppBar(title: const Text('Approvals')),
      body: LoadView<List<AppUser>>(
        load: users.fetchPending,
        builder: (context, pending, reload) => RefreshIndicator(
          onRefresh: reload,
          child: _PendingList(users: users, pending: pending, reload: reload),
        ),
      ),
    );
  }
}

class _PendingList extends StatelessWidget {
  const _PendingList({
    required this.users,
    required this.pending,
    required this.reload,
  });

  final UserRepository users;
  final List<AppUser> pending;
  final Future<void> Function() reload;

  Future<void> _review(BuildContext context, AppUser person) async {
    final done = await showAppSheet<String>(
      context,
      title: 'Review request',
      subtitle: 'Verify who this is before you approve.',
      builder: (sheetContext) => _ReviewForm(users: users, person: person),
    );
    if (done == null || !context.mounted) return;
    showAppToast(
      context,
      done == 'approved' ? 'Account approved.' : 'Request rejected.',
    );
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
          title: 'Pending approval',
          subtitle: pending.isEmpty
              ? 'Nobody is waiting.'
              : '${pending.length} waiting, oldest first.',
        ),
        const SizedBox(height: 14),
        if (pending.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 24),
            child: EmptyState(
              icon: Icons.how_to_reg_outlined,
              title: 'All caught up',
              message: 'New access requests will show up here.',
            ),
          )
        else
          for (final person in pending) ...[
            AppCard(
              onTap: () => _review(context, person),
              semanticLabel: 'Review request from ${person.name}',
              child: Row(
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
                        const SizedBox(height: 2),
                        Text(
                          person.phone ?? 'No phone number',
                          style: text.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const AppPill(label: 'Pending'),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: scheme.onSurfaceVariant,
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

class _ReviewForm extends StatefulWidget {
  const _ReviewForm({required this.users, required this.person});

  final UserRepository users;
  final AppUser person;

  @override
  State<_ReviewForm> createState() => _ReviewFormState();
}

class _ReviewFormState extends State<_ReviewForm> {
  late final TextEditingController _name;
  late final TextEditingController _phone;
  UserRole _role = UserRole.level1;
  bool _working = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.person.name);
    _phone = TextEditingController(text: widget.person.phone ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _approve() async {
    final name = _name.text.trim();
    final phone = _phone.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Enter the verified name.');
      return;
    }
    if (!looksLikePhone(phone)) {
      setState(() => _error = 'Enter a valid phone number (10 to 13 digits).');
      return;
    }
    setState(() {
      _working = true;
      _error = null;
    });
    try {
      await widget.users.approve(
        userId: widget.person.id,
        role: _role,
        verifiedName: name,
        verifiedPhone: phone,
      );
      if (!mounted) return;
      Navigator.of(context).pop('approved');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _working = false;
        _error = errorText(e);
      });
    }
  }

  Future<void> _reject() async {
    final confirmed = await showConfirmSheet(
      context,
      title: 'Reject this request?',
      message: 'The person will not get an account. This cannot be undone.',
      confirmLabel: 'Reject',
    );
    if (!confirmed || !mounted) return;
    setState(() {
      _working = true;
      _error = null;
    });
    try {
      await widget.users.reject(widget.person.id);
      if (!mounted) return;
      Navigator.of(context).pop('rejected');
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
          controller: _name,
          enabled: !_working,
          textCapitalization: TextCapitalization.words,
          decoration: appInputDecoration(
            context,
            label: 'Full name',
            icon: Icons.person_outline,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _phone,
          enabled: !_working,
          keyboardType: TextInputType.phone,
          decoration: appInputDecoration(
            context,
            label: 'Phone number',
            icon: Icons.phone_outlined,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'ASSIGN ROLE',
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
        if (_error != null) ...[
          const SizedBox(height: 12),
          InlineError(message: _error!),
        ],
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: _working ? null : _approve,
          style: bigFilledStyle(),
          icon: _working
              ? const ButtonSpinner()
              : const Icon(Icons.check_rounded),
          label: const Text('Approve'),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: _working ? null : _reject,
          style: bigOutlinedStyle(),
          icon: const Icon(Icons.close_rounded),
          label: const Text('Reject'),
        ),
      ],
    );
  }
}
