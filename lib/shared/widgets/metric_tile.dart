// lib/shared/widgets/metric_tile.dart
//
// One reading in a grid, such as Water level, Rain, or Power.
// Numbers use tabular figures so they do not jiggle as values change.
//
// A null [value] shows "--" and "No data", so a missing reading is never
// mistaken for a good one (silence is not safety).
//
// Put tiles in a Row with Expanded, or in a GridView. The tile does not
// choose its own width.

import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'app_card.dart';

class MetricTile extends StatelessWidget {
  const MetricTile({
    super.key,
    required this.label,
    required this.value,
    this.unit,
    this.icon,
    this.caption,
    this.accent,
  });

  /// Short name, such as "Water level". Shown in small capitals.
  final String label;

  /// The reading, already formatted, such as "78". Null means no data.
  final String? value;

  /// Unit shown beside the value, such as "%".
  final String? unit;

  final IconData? icon;

  /// A word that explains the reading, such as "Normal" or "On battery".
  /// Always give one when you set [accent], so color is never the only cue.
  final String? caption;

  /// Optional tint for the icon and caption, such as context.status.stage2.
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final text = Theme.of(context).textTheme;
    final tint = accent ?? scheme.onSurfaceVariant;
    final hasValue = value != null;
    final shownCaption = hasValue ? caption : 'No data';

    return Semantics(
      container: true,
      label: '$label: ${hasValue ? '$value${unit ?? ''}' : 'no data'}'
          '${shownCaption == null ? '' : ', $shownCaption'}',
      excludeSemantics: true,
      child: AppCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16, color: tint),
                  const SizedBox(width: 6),
                ],
                Expanded(
                  child: Text(
                    label.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Flexible(
                  child: Text(
                    value ?? '--',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      color: hasValue
                          ? scheme.onSurface
                          : scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                if (hasValue && unit != null) ...[
                  const SizedBox(width: 3),
                  Text(
                    unit!,
                    style: text.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
            if (shownCaption != null) ...[
              const SizedBox(height: 4),
              Text(
                shownCaption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.bodySmall?.copyWith(
                  color: hasValue ? tint : scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
