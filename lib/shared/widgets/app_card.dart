// lib/shared/widgets/app_card.dart
//
// The standard card used across the app: thin border, soft shadow, optional
// header, optional colored edge, optional tap. No business logic.
//
// Colors come only from context.colors. Pass [accent] from the caller
// (for example context.status.stage2) when the card needs a colored edge,
// and always show the meaning in words too, not by color alone.

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.trailing,
    this.padding = const EdgeInsets.all(16),
    this.accent,
    this.onTap,
    this.semanticLabel,
  });

  /// Corner radius shared with the Login and Request Access cards.
  static const double radius = 18;

  /// Card body.
  final Widget child;

  /// Optional header. Shown above a thin divider.
  final String? title;
  final String? subtitle;

  /// Optional widget at the right of the header, such as a status pill.
  final Widget? trailing;

  /// Padding around [child].
  final EdgeInsetsGeometry padding;

  /// Optional colored strip on the left edge.
  final Color? accent;

  /// Makes the whole card tappable.
  final VoidCallback? onTap;

  /// Spoken label for screen readers when the card is tappable.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final borderRadius = BorderRadius.circular(radius);

    final hasHeader = title != null;
    final body = Padding(padding: padding, child: child);

    final content = hasHeader
        ? Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _CardHeader(title: title!, subtitle: subtitle, trailing: trailing),
              Divider(height: 1, thickness: 1, color: scheme.outline.withAlpha(85)),
              body,
            ],
          )
        : body;

    final card = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withAlpha(22),
            blurRadius: 22,
            spreadRadius: -5,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: scheme.surface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius,
          side: BorderSide(color: scheme.outline.withAlpha(115), width: 0.8),
        ),
        child: InkWell(
          onTap: onTap,
          child: Stack(
            fit: StackFit.passthrough,
            children: [
              content,
              if (accent != null)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: 4,
                  child: ColoredBox(color: accent!),
                ),
            ],
          ),
        ),
      ),
    );

    if (onTap == null || semanticLabel == null) return card;
    return Semantics(button: true, label: semanticLabel, child: card);
  }
}

class _CardHeader extends StatelessWidget {
  const _CardHeader({required this.title, this.subtitle, this.trailing});

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle!,
                    style: text.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 10), trailing!],
        ],
      ),
    );
  }
}
