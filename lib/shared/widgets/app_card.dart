// lib/shared/widgets/app_card.dart
// Reusable restrained glass surface for the SCADA interface.

import 'dart:ui';

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

  static const double radius = 20;

  final Widget child;
  final String? title;
  final String? subtitle;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;
  final Color? accent;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final borderRadius = BorderRadius.circular(radius);

    final content = title == null
        ? Padding(padding: padding, child: child)
        : Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _CardHeader(title: title!, subtitle: subtitle, trailing: trailing),
              Divider(height: 1, thickness: 1, color: scheme.outlineVariant.withAlpha(125)),
              Padding(padding: padding, child: child),
            ],
          );

    final card = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(45),
            blurRadius: 24,
            spreadRadius: -8,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Material(
            color: scheme.surfaceContainerHighest.withAlpha(
              scheme.brightness == Brightness.dark ? 210 : 238,
            ),
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: borderRadius,
              side: BorderSide(color: scheme.outline.withAlpha(145), width: 0.9),
            ),
            child: InkWell(
              onTap: onTap,
              borderRadius: borderRadius,
              child: Stack(
                fit: StackFit.passthrough,
                children: [
                  content,
                  if (accent != null)
                    Positioned(
                      left: 0,
                      top: 12,
                      bottom: 12,
                      width: 3,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: accent,
                          borderRadius: const BorderRadius.horizontal(right: Radius.circular(3)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
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
                Text(title, style: text.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(subtitle!, style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
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
