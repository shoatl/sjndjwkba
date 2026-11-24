// lib/features/roles/admin/directory_screen.dart
//
// Active Personnel Directory (Admin only): search, filter by role, edit a
// person's name, phone and role, and archive departing staff. Correct phone
// numbers matter because Level 2 and 3 get an SMS fallback.
//
// The Archived Users Vault opens from the box icon in the app bar.

import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/data/user_repository.dart';
import '../../../core/models/drainage_models.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_ui.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/section_heading.dart';
import '../../../shared/widgets/sheet_helper.dart';
import 'archive_vault_screen.dart';

class DirectoryScreen extends StatefulWidget {
  const DirectoryScreen({super.key, required this.users});

  final UserRepository users;

  @override
  State<DirectoryScreen> createState() => _DirectoryScreenState();
}

class _DirectoryScreenState extends State<DirectoryScreen> {
  final TextEditingController _search = TextEditingController();
  Timer? _debounce;

  List<AppUser> _people = <AppUser>[];
  UserRole? _role;
  bool _loading = true;
  Object? _error;
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final mine = ++_requestId;
    final query = _search.text.trim();
    try {
      final result = await widget.users.fetchActive(
        query: query.isEmpty ? null : query,
        role: _role,
      );
      // Ignore answers to older searches.
      if (!mounted || mine != _requestId) return;
      setState(() {
        _people = result;
        _error = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted || mine != _requestId) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _load);
  }

  void _setRole(UserRole? role) {
    setState(() => _role = role);
    _load();
  }

  Future<void> _edit(AppUser person) async {
    final result = await showAppSheet<String>(
      context,
      title: 'Edit person',
      subtitle: 'Changes apply right away.',
      builder: (sheetContext) =>
          _EditForm(users: widget.users, person: person),
    );
    if (result == null || !mounted) return;
    showAppToast(
      context,
      result == 'archived' ? 'Account archived.' : 'Changes saved.',
    );
    await _load();
  }

  void _openVault() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ArchiveVaultScreen(users: widget.users),
      ),
    );
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
      appBar: AppBar(
        title: const Text('Directory'),
        actions: [
          IconButton(
            tooltip: 'Archived users',
            onPressed: _openVault,
            icon: const Icon(Icons.inventory_2_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 14, 15, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeading(
                  eyebrow: 'Personnel',
                  title: 'Active directory',
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _search,
                  onChanged: _onSearchChanged,
                  textInputAction: TextInputAction.search,
                  decoration: appInputDecoration(
                    context,
                    label: 'Search name or phone',
                    icon: Icons.search_rounded,
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ChoiceChip(
                        label: const Text('All'),
                        selected: _role == null,
                        onSelected: (_) => _setRole(null),
                      ),
                      for (final role in UserRole.values) ...[
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: Text(role.shortLabel),
                          selected: _role == role,
                          onSelected: (_) => _setRole(role),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 6),
              ],
            ),
          ),
          Expanded(child: _buildList(context)),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return EmptyState(
        icon: Icons.cloud_off_outlined,
        title: 'Could not load the directory',
        message: errorText(_error!),
        actionLabel: 'Try again',
        onAction: () {
          setState(() {
            _error = null;
            _loading = true;
          });
          _load();
        },
      );
    }

    if (_people.isEmpty) {
      return const EmptyState(
        icon: Icons.person_search_outlined,
        title: 'No one found',
        message: 'Try a different name, number, or role.',
      );
    }

    final scheme = context.colors;
    final text = Theme.of(context).textTheme;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(15, 8, 15, 24),
        itemCount: _people.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final person = _people[index];
          return AppCard(
            onTap: () => _edit(person),
            semanticLabel: 'Edit ${person.name}',
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                const SizedBox(width: 8),
                AppPill(label: person.role.shortLabel),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _EditForm extends StatefulWidget {
  const _EditForm({required this.users, required this.person});

  final UserRepository users;
  final AppUser person;

  @override
  State<_EditForm> createState() => _EditFormState();
}

class _EditFormState extends State<_EditForm> {
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late UserRole _role;
  bool _working = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.person.name);
    _phone = TextEditingController(text: widget.person.phone ?? '');
    _role = widget.person.role;
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final phone = _phone.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Enter a name.');
      return;
    }
    if (!looksLikePhone(phone)) {
      setState(() => _error = 'Enter a valid phone number (10 to 13 digits).');
      return;
    }

    final nameChanged = name != widget.person.name;
    final phoneChanged = phone != (widget.person.phone ?? '');
    final roleChanged = _role != widget.person.role;
    if (!nameChanged && !phoneChanged && !roleChanged) {
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _working = true;
      _error = null;
    });
    try {
      await widget.users.update(
        userId: widget.person.id,
        name: nameChanged ? name : null,
        phone: phoneChanged ? phone : null,
        role: roleChanged ? _role : null,
      );
      if (!mounted) return;
      Navigator.of(context).pop('saved');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _working = false;
        _error = errorText(e);
      });
    }
  }

  Future<void> _archive() async {
    final confirmed = await showConfirmSheet(
      context,
      title: 'Archive ${widget.person.name}?',
      message: 'They will be blocked from logging in. Their phone number and '
          'credentials are removed. Only name, role and service dates are '
          'kept. You can restore the account later.',
      confirmLabel: 'Archive',
    );
    if (!confirmed || !mounted) return;
    setState(() {
      _working = true;
      _error = null;
    });
    try {
      await widget.users.archive(widget.person.id);
      if (!mounted) return;
      Navigator.of(context).pop('archived');
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
        if (_error != null) ...[
          const SizedBox(height: 12),
          InlineError(message: _error!),
        ],
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _working ? null : _save,
          style: bigFilledStyle(),
          child: _working ? const ButtonSpinner() : const Text('Save changes'),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: _working ? null : _archive,
          style: bigOutlinedStyle(),
          icon: const Icon(Icons.archive_outlined),
          label: const Text('Archive account'),
        ),
      ],
    );
  }
}
