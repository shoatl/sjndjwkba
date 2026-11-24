// lib/features/profile/profile_screen.dart
//
// Profile: account info, notification settings and health (field roles),
// the Privacy section, and Log out. Admin sees account info, Privacy, and
// Log out only (no notification settings, because Admin is not field
// response).
//
// Level 1 is push only. The SMS fallback switch shows for Level 2 and 3.

import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/auth/session.dart';
import '../../core/data/auth_repository.dart';
import '../../core/models/drainage_models.dart';
import '../../core/services/notification_health.dart';
import '../../core/services/notification_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/time_format.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/app_ui.dart';
import '../../shared/widgets/section_heading.dart';
import '../../shared/widgets/sheet_helper.dart';
import '../privacy/privacy_screens.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.session,
    required this.auth,
    this.notifications,
    this.onReadFullNotice,
    this.onWithdrawConsent,
    this.onRequestData,
  });

  final Session session;
  final AuthRepository auth;

  /// Null for Admin, who has no notification settings.
  final NotificationService? notifications;

  final VoidCallback? onReadFullNotice;

  /// Start the consent withdrawal. If null, a short explanation is shown.
  final VoidCallback? onWithdrawConsent;

  /// Ask for a copy of personal data. If null, a short explanation is shown.
  final VoidCallback? onRequestData;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  NotificationSettings? _settings;
  NotificationHealth? _health;
  bool _settingsFailed = false;
  bool _checking = false;
  bool _signingOut = false;

  @override
  void initState() {
    super.initState();
    if (widget.notifications != null) {
      _checking = true; // The first check starts below, before the first build.
      _loadSettings();
      _runHealthCheck();
    }
  }

  Future<void> _loadSettings() async {
    try {
      final loaded = await widget.notifications!.loadSettings();
      if (!mounted) return;
      setState(() {
        _settings = loaded;
        _settingsFailed = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _settingsFailed = true);
    }
  }

  Future<void> _checkHealth() {
    setState(() => _checking = true);
    return _runHealthCheck();
  }

  Future<void> _runHealthCheck() async {
    try {
      final health = await widget.notifications!.checkHealth();
      if (!mounted) return;
      setState(() {
        _health = health;
        _checking = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _checking = false);
      showAppToast(context, 'Could not check notifications. Try again.');
    }
  }

  Future<void> _change(NotificationSettings next) async {
    final before = _settings;
    setState(() => _settings = next);
    try {
      final saved = await widget.notifications!.saveSettings(next);
      if (!mounted) return;
      setState(() => _settings = saved);
    } catch (_) {
      if (!mounted) return;
      setState(() => _settings = before);
      showAppToast(context, 'Could not save. Please try again.');
    }
  }

  Future<void> _turnOn() async {
    try {
      final granted = await widget.notifications!.requestPermission();
      if (!granted) await widget.notifications!.openSystemSettings();
    } catch (_) {
      if (!mounted) return;
      showAppToast(context, 'Could not open notification settings.');
    }
    if (mounted) await _checkHealth();
  }

  Future<void> _signOut() async {
    final confirmed = await showConfirmSheet(
      context,
      title: 'Log out?',
      message: 'This phone will stop receiving alerts until you sign in again.',
      confirmLabel: 'Log out',
    );
    if (!confirmed || !mounted) return;

    setState(() => _signingOut = true);
    try {
      await widget.auth.signOut();
    } catch (_) {
      // Sign out locally even if the server could not be reached.
    }
    if (!mounted) return;
    widget.session.signOut();
  }

  void _explain(String title, String message) {
    showAppSheet<void>(
      context,
      title: title,
      builder: (sheetContext) {
        final scheme = sheetContext.colors;
        final text = Theme.of(sheetContext).textTheme;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              message,
              style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Navigator.of(sheetContext).pop(),
              style: bigFilledStyle(),
              child: const Text('Got it'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final background = Color.alphaBlend(
      scheme.surfaceContainerHighest.withAlpha(90),
      scheme.surface,
    );

    return ListenableBuilder(
      listenable: widget.session,
      builder: (context, _) {
        final user = widget.session.user;
        return Scaffold(
          backgroundColor: scheme.surface,
          appBar: AppBar(title: const Text('Profile')),
          body: user == null
              ? const SizedBox.shrink()
              : Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [scheme.surfaceContainerHighest.withAlpha(105), scheme.surface, scheme.surface],
                    ),
                  ),
                  child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 20, 18, 32),
                  children: [
                    const SectionHeading(eyebrow: 'Account', title: 'Profile'),
                    const SizedBox(height: 14),
                    _AccountCard(user: user),
                    if (widget.notifications != null) ...[
                      const SizedBox(height: 14),
                      _buildSettingsCard(context, user.role),
                      const SizedBox(height: 14),
                      _buildHealthCard(context),
                    ],
                    const SizedBox(height: 14),
                    PrivacySection(
                      onViewNotice: widget.onReadFullNotice ?? () {},
                      onWithdrawConsent: widget.onWithdrawConsent ??
                          () => _explain(
                                'Withdraw consent',
                                'Withdrawing consent ends your access to the '
                                    'app. Please contact the barangay Admin or '
                                    'the data protection officer to do this.',
                              ),
                      onRequestData: widget.onRequestData ??
                          () => _explain(
                                'Request my data',
                                'To get a copy of the personal data we keep '
                                    'about you, please contact the barangay '
                                    'Admin or the data protection officer.',
                              ),
                    ),
                    const SizedBox(height: 20),
                    OutlinedButton.icon(
                      onPressed: _signingOut ? null : _signOut,
                      style: bigOutlinedStyle(),
                      icon: _signingOut
                          ? const ButtonSpinner(onFilled: false)
                          : const Icon(Icons.logout_rounded),
                      label: const Text('Log out'),
                    ),
                  ],
                ),
              ),
        );
      },
    );
  }

  Widget _buildSettingsCard(BuildContext context, UserRole role) {
    final scheme = context.colors;
    final text = Theme.of(context).textTheme;
    final s = _settings;

    Widget body;
    if (s == null) {
      body = _settingsFailed
          ? Row(
              children: [
                Expanded(
                  child: Text(
                    'Could not load your settings.',
                    style: text.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _loadSettings,
                  child: const Text('Try again'),
                ),
              ],
            )
          : const Padding(
              padding: EdgeInsets.all(8),
              child: Center(child: CircularProgressIndicator()),
            );
    } else {
      body = Column(
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: s.pushEnabled,
            onChanged: (v) => _change(s.copyWith(pushEnabled: v)),
            title: const Text('Push alerts'),
            subtitle: const Text('Notifications on this phone.'),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: s.alertSound,
            onChanged: (v) => _change(s.copyWith(alertSound: v)),
            title: const Text('Alert sound'),
            subtitle: const Text('Play a loud sound for new alerts.'),
          ),
          if (role.receivesSmsFallback)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: s.smsFallback,
              onChanged: (v) => _change(s.copyWith(smsFallback: v)),
              title: const Text('SMS fallback'),
              subtitle: const Text('Get a text if a push is not delivered.'),
            ),
        ],
      );
    }

    return AppCard(title: 'Notifications', child: body);
  }

  Widget _buildHealthCard(BuildContext context) {
    final scheme = context.colors;
    final text = Theme.of(context).textTheme;
    final h = _health;

    final healthy = h?.isHealthy ?? false;
    final Color tint = h == null
        ? scheme.onSurfaceVariant
        : (healthy ? context.status.normal : context.status.stage2);

    return AppCard(
      title: 'Notification health',
      subtitle: 'Check that alerts can reach this phone.',
      trailing: h == null
          ? null
          : AppPill(label: healthy ? 'Working' : 'Needs attention', color: tint),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (h == null)
            Text(
              _checking ? 'Checking...' : 'Not checked yet.',
              style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            )
          else ...[
            InfoRow(
              label: 'Permission',
              value: _permissionText(h.permission),
            ),
            InfoRow(
              label: 'This phone',
              value: h.deviceRegistered ? 'Registered' : 'Not registered',
            ),
            if (h.lastDeliveredAt != null)
              InfoRow(
                label: 'Last alert',
                value: agoText(h.lastDeliveredAt!, DateTime.now()),
              ),
            if (h.problem != null) ...[
              const SizedBox(height: 8),
              InlineError(message: h.problem!),
            ],
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _checking ? null : _checkHealth,
                  style: bigOutlinedStyle(),
                  icon: _checking
                      ? const ButtonSpinner(onFilled: false)
                      : const Icon(Icons.refresh_rounded),
                  label: const Text('Check again'),
                ),
              ),
              if (h != null && !healthy) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: _turnOn,
                    style: bigFilledStyle(),
                    child: const Text('Fix'),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _permissionText(NotificationPermission p) {
    switch (p) {
      case NotificationPermission.enabled:
        return 'Allowed';
      case NotificationPermission.blocked:
        return 'Blocked';
      case NotificationPermission.notAsked:
        return 'Not asked yet';
    }
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final text = Theme.of(context).textTheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: scheme.primary.withAlpha(150), width: 1.5),
                ),
                child: PersonAvatar(name: user.name, size: 60),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: text.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.role.label.toUpperCase(),
                      style: text.labelSmall?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 8),
          if (user.phone != null)
            InfoRow(label: 'Phone', value: user.phone!),
          InfoRow(
            label: 'Role',
            value: user.role.plainLabel,
          ),
          if (user.serviceSpans.isNotEmpty)
            InfoRow(
              label: 'In service since',
              value: formatDate(user.serviceSpans.last.start),
            ),
        ],
      ),
    );
  }
}
