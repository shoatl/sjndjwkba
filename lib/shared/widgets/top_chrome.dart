// lib/shared/widgets/top_chrome.dart
// Shared field-dashboard header: connection state, product identity, greeting,
// and the signed-in user's real role. It intentionally does not fabricate
// notifications or navigation actions that the app does not currently have.

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Whether the node is reporting. Stale means "No recent data", which is not
/// an all-clear.
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
  final String roleBadge;
  final String userName;
  final String title;
  final String? subtitle;
  final VoidCallback? onAccountTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final text = Theme.of(context).textTheme;
    final top = MediaQuery.of(context).padding.top;
    final live = connection == ChromeConnection.live;
    final statusColor = live ? context.status.normal : context.status.stale;
    final trimmedName = userName.trim();
    final initial = trimmedName.isEmpty
        ? '?'
        : String.fromCharCode(trimmedName.runes.first).toUpperCase();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(18, top + 12, 18, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.alphaBlend(scheme.primary.withAlpha(20), scheme.surfaceContainerHighest),
            scheme.surface,
          ],
        ),
        border: Border(bottom: BorderSide(color: scheme.outline.withAlpha(105))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: scheme.primary.withAlpha(24),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: scheme.primary.withAlpha(90)),
                ),
                child: Icon(Icons.water_drop_rounded, color: scheme.primary, size: 25),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'LORA',
                      style: text.labelSmall?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4,
                      ),
                    ),
                    Text(
                      title.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.15,
                      ),
                    ),
                  ],
                ),
              ),
              _ConnectionPill(label: live ? 'LIVE' : 'NO RECENT DATA', color: statusColor),
            ],
          ),
          const SizedBox(height: 17),
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scheme.primary.withAlpha(20),
                  border: Border.all(color: scheme.primary.withAlpha(170), width: 1.5),
                  boxShadow: [
                    BoxShadow(color: scheme.primary.withAlpha(24), blurRadius: 14),
                  ],
                ),
                child: Text(
                  initial,
                  style: text.titleMedium?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Monitoring overview',
                      style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      trimmedName.isEmpty ? 'Welcome' : trimmedName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: scheme.primary.withAlpha(18),
                borderRadius: BorderRadius.circular(999),
                child: InkWell(
                  onTap: onAccountTap,
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: scheme.primary.withAlpha(90)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified_user_outlined, size: 14, color: scheme.primary),
                        const SizedBox(width: 6),
                        Text(
                          roleBadge,
                          style: text.labelSmall?.copyWith(
                            color: scheme.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ConnectionPill extends StatelessWidget {
  const _ConnectionPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(22),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withAlpha(90)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: text.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.35,
            ),
          ),
        ],
      ),
    );
  }
}
