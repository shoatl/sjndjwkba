// lib/shared/widgets/metric_tile.dart
// Consistent real-data metric card used across the dashboard.

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'app_card.dart';

class MetricTile extends StatelessWidget {
  const MetricTile({super.key, required this.label, required this.value, this.unit, this.icon, this.caption, this.accent});

  final String label;
  final String? value;
  final String? unit;
  final IconData? icon;
  final String? caption;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final text = Theme.of(context).textTheme;
    final tint = accent ?? scheme.onSurfaceVariant;
    final hasValue = value != null;

    return Semantics(
      container: true,
      label: '$label: ${hasValue ? '$value${unit ?? ''}' : 'no data'}${caption == null ? '' : ', $caption'}',
      excludeSemantics: true,
      child: AppCard(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) Container(width: 30, height: 30, decoration: BoxDecoration(color: tint.withAlpha(24), borderRadius: BorderRadius.circular(9), border: Border.all(color: tint.withAlpha(70))), child: Icon(icon, size: 17, color: tint)),
            const SizedBox(height: 9),
            Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [Text(value ?? '--', style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w900, fontFeatures: const [FontFeature.tabularFigures()], color: hasValue ? scheme.onSurface : scheme.onSurfaceVariant)), if (hasValue && unit != null) ...[const SizedBox(width: 3), Text(unit!, style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant))]]),
            const SizedBox(height: 3),
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: text.labelSmall?.copyWith(color: scheme.onSurfaceVariant, fontWeight: FontWeight.w700)),
            if (caption != null) ...[const SizedBox(height: 5), Text(hasValue ? caption! : 'No data', maxLines: 1, overflow: TextOverflow.ellipsis, style: text.bodySmall?.copyWith(color: tint, fontWeight: FontWeight.w700))],
          ],
        ),
      ),
    );
  }
}
