// lib/shared/widgets/top_chrome.dart
//
// The header block at the top of the role Home screens, like the navy
// header in the simulation: connection chip, brand, and the signed-in
// person's role badge and name.
//
// Colors come from the app bar theme (so it follows the active palette)
// and from context.status for the connection dot. No logos: the brand
// mark is a plain icon.

import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Whether the node is reporting. Stale means "No recent data", which is
/// not an all-clear.
enum ChromeConnection { live, stale }

class TopChrome extends StatelessWidget {
  const TopChrome({
    super.key,
    required this.connection,
    required this.roleBadge,
    required this.userName,
    this.title = 'Drainage Monitor',
    this.subtitle,
    this.onAccountTap,
  });

  final ChromeConnection connection;

  /// Short role label shown on the account chip, such as "L1" or "ADMIN".
  final String roleBadge;

  final String userName;

  final String title;

  /// One short line under the title, such as "Field Operations".
  final String? subtitle;

  /// Tapping the account chip, for example to open Profile.
  final VoidCallback? onAccountTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final bar = Theme.of(context).appBarTheme;
    final base = scheme.surfaceContainerHighest;
    final onBase = bar.foregroundColor ?? scheme.onPrimary;
    final text = Theme.of(context).textTheme;
    final top = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(18, top + 10, 18, 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: scheme.outline.withAlpha(110))),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [base.withAlpha(248), scheme.surface],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ConnectionChip(connection: connection, onBase: onBase),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: onBase.withAlpha(30),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: onBase.withAlpha(50)),
                ),
                child: Icon(Icons.water_drop_outlined, color: onBase, size: 21),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.titleMedium?.copyWith(
                        color: onBase,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodySmall?.copyWith(
                          color: onBase.withAlpha(190),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _AccountChip(
                roleBadge: roleBadge,
                userName: userName,
                onBase: onBase,
                onTap: onAccountTap,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ConnectionChip extends StatelessWidget {
  const _ConnectionChip({required this.connection, required this.onBase});

  final ChromeConnection connection;
  final Color onBase;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final live = connection == ChromeConnection.live;
    final dot = live ? context.status.normal : context.status.stale;
    final label = live ? 'Live' : 'No recent data';

    return Semantics(
      label: 'Node connection: $label',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: onBase.withAlpha(26),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: onBase.withAlpha(46)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: text.labelMedium?.copyWith(
                color: onBase,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountChip extends StatelessWidget {
  const _AccountChip({
    required this.roleBadge,
    required this.userName,
    required this.onBase,
    this.onTap,
  });

  final String roleBadge;
  final String userName;
  final Color onBase;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final trimmed = userName.trim();
    final initial = trimmed.isEmpty
        ? '?'
        : String.fromCharCode(trimmed.runes.first).toUpperCase();

    return Semantics(
      button: onTap != null,
      label: 'Account: $userName, $roleBadge',
      excludeSemantics: true,
      child: Material(
        color: onBase.withAlpha(26),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: onBase.withAlpha(56)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: onBase,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(
                    initial,
                    style: text.labelMedium?.copyWith(
                      color: Theme.of(context).appBarTheme.backgroundColor ??
                          context.colors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      roleBadge,
                      style: text.labelSmall?.copyWith(
                        color: onBase,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 84),
                      child: Text(
                        userName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.labelSmall?.copyWith(
                          color: onBase.withAlpha(200),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
