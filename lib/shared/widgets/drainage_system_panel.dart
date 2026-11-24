import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'app_card.dart';

/// An animated, isometric system schematic driven by the latest node reading.
/// It is intentionally drawn in Flutter so it adds no native/3D-engine dependency.
class DrainageSystemPanel extends StatefulWidget {
  const DrainageSystemPanel({
    super.key,
    required this.waterPercent,
    required this.stage,
    required this.isStale,
  });

  final double? waterPercent;
  final int stage;
  final bool isStale;

  @override
  State<DrainageSystemPanel> createState() => _DrainageSystemPanelState();
}

class _DrainageSystemPanelState extends State<DrainageSystemPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flow = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 5),
  )..repeat();

  @override
  void dispose() {
    _flow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final percent = widget.waterPercent;
    final stageColor = context.status.forStage(widget.stage);

    return AppCard(
      title: 'Drainage system',
      subtitle: 'Isometric sensor and water-level view',
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: (widget.isStale ? context.status.stale : stageColor)
              .withAlpha(28),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: (widget.isStale ? context.status.stale : stageColor)
                .withAlpha(90),
          ),
        ),
        child: Text(
          widget.isStale ? 'LAST KNOWN' : 'STAGE ${widget.stage}',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: widget.isStale ? context.status.stale : stageColor,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
              ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AnimatedBuilder(
            animation: _flow,
            builder: (context, _) => SizedBox(
              height: 172,
              width: double.infinity,
              child: CustomPaint(
                painter: _DrainageSchematicPainter(
                  surface: scheme.surface,
                  outline: scheme.outline,
                  cyan: scheme.primary,
                  muted: scheme.onSurfaceVariant,
                  water: stageColor,
                  waterPercent: percent,
                  phase: _flow.value,
                  stale: widget.isStale,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _LegendDot(color: scheme.primary, label: 'Sensors'),
              const SizedBox(width: 18),
              _LegendDot(color: stageColor, label: 'Water level'),
              const Spacer(),
              Text(
                percent == null
                    ? 'No level reading'
                    : '${percent.round().clamp(0, 100)}% water',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          if (widget.isStale) ...[
            const SizedBox(height: 8),
            Text(
              'No recent data. This is a last-known view, not a live reading.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
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
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}

class _DrainageSchematicPainter extends CustomPainter {
  _DrainageSchematicPainter({
    required this.surface,
    required this.outline,
    required this.cyan,
    required this.muted,
    required this.water,
    required this.waterPercent,
    required this.phase,
    required this.stale,
  });

  final Color surface;
  final Color outline;
  final Color cyan;
  final Color muted;
  final Color water;
  final double? waterPercent;
  final double phase;
  final bool stale;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final opacity = stale ? 0.38 : 1.0;
    final gridPaint = Paint()
      ..color = cyan.withOpacity(0.07 * opacity)
      ..strokeWidth = 1;
    for (var x = 12.0; x < w; x += 24) {
      canvas.drawLine(Offset(x, 8), Offset(x, h - 8), gridPaint);
    }
    for (var y = 12.0; y < h; y += 24) {
      canvas.drawLine(Offset(8, y), Offset(w - 8, y), gridPaint);
    }

    final left = w * 0.10;
    final right = w * 0.91;
    final top = h * 0.42;
    final bottom = h * 0.78;
    final depth = 13.0;

    // Pipe shadow and the two shaded faces create a restrained isometric look.
    final shadow = Path()
      ..moveTo(left + 5, bottom + 5)
      ..lineTo(right - 4, bottom + 5)
      ..lineTo(right + depth, top + depth + 5)
      ..lineTo(left + depth, top + depth + 5)
      ..close();
    canvas.drawPath(
      shadow,
      Paint()..color = Colors.black.withOpacity(0.28 * opacity),
    );

    final front = Path()
      ..moveTo(left, top)
      ..lineTo(right, top)
      ..lineTo(right, bottom)
      ..lineTo(left, bottom)
      ..close();
    final frontPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color.lerp(surface, cyan, 0.12)!.withOpacity(opacity),
          Color.lerp(surface, Colors.black, 0.32)!.withOpacity(opacity),
        ],
      ).createShader(Rect.fromLTRB(left, top, right, bottom));
    canvas.drawPath(front, frontPaint);
    canvas.drawPath(
      front,
      Paint()
        ..color = cyan.withOpacity(0.72 * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );

    final topFace = Path()
      ..moveTo(left, top)
      ..lineTo(left + depth, top - depth)
      ..lineTo(right + depth, top - depth)
      ..lineTo(right, top)
      ..close();
    canvas.drawPath(
      topFace,
      Paint()..color = Color.lerp(surface, cyan, 0.23)!.withOpacity(opacity),
    );
    canvas.drawPath(
      topFace,
      Paint()
        ..color = cyan.withOpacity(0.65 * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    final sideFace = Path()
      ..moveTo(right, top)
      ..lineTo(right + depth, top - depth)
      ..lineTo(right + depth, bottom - depth)
      ..lineTo(right, bottom)
      ..close();
    canvas.drawPath(
      sideFace,
      Paint()..color = Color.lerp(surface, Colors.black, 0.38)!.withOpacity(opacity),
    );
    canvas.drawPath(
      sideFace,
      Paint()
        ..color = cyan.withOpacity(0.42 * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // Water is clipped to the front face; the level comes from the node model.
    final pct = (waterPercent ?? 0).clamp(0.0, 100.0) / 100.0;
    final waterY = bottom - (bottom - top) * pct;
    canvas.save();
    canvas.clipPath(front);
    final waterPath = Path()
      ..moveTo(left, waterY)
      ..lineTo(right, waterY)
      ..lineTo(right, bottom)
      ..lineTo(left, bottom)
      ..close();
    canvas.drawPath(
      waterPath,
      Paint()..color = water.withOpacity((waterPercent == null ? 0.12 : 0.34) * opacity),
    );
    final wave = Path();
    for (var x = left; x <= right; x += 4) {
      final y = waterY +
          math.sin((x / 19) + (phase * math.pi * 2)) * 2.3;
      if (x == left) {
        wave.moveTo(x, y);
      } else {
        wave.lineTo(x, y);
      }
    }
    canvas.drawPath(
      wave,
      Paint()
        ..color = water.withOpacity(0.9 * opacity)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );

    // Flow markers travel along the channel without representing sensor data.
    final flowPaint = Paint()
      ..color = cyan.withOpacity(0.9 * opacity)
      ..style = PaintingStyle.fill;
    for (var i = 0; i < 5; i++) {
      final x = left + 18 + ((phase * (right - left - 36) + i * 42) %
          (right - left - 36));
      canvas.drawCircle(Offset(x, top + 18), 2.2, flowPaint);
    }
    canvas.restore();

    // Three sensor mounts, deliberately schematic and not tied to invented IDs.
    for (var i = 0; i < 3; i++) {
      final x = left + 24 + i * ((right - left - 48) / 2);
      final sensorY = top - 28 - (i == 1 ? 10 : 0);
      final sensorPaint = Paint()
        ..color = stale ? muted : cyan
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      canvas.drawLine(
        Offset(x, sensorY + 9),
        Offset(x, top + 2),
        sensorPaint,
      );
      if (!stale) {
        canvas.drawCircle(
          Offset(x, sensorY + 4),
          9,
          Paint()..color = cyan.withOpacity(0.12),
        );
      }
      canvas.drawCircle(
        Offset(x, sensorY + 4),
        4,
        Paint()..color = stale ? muted : cyan,
      );
      final label = TextPainter(
        text: TextSpan(
          text: 'S${i + 1}',
          style: TextStyle(
            color: stale ? muted : cyan,
            fontSize: 9,
            fontWeight: FontWeight.w800,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      label.paint(canvas, Offset(x - label.width / 2, sensorY - 12));
    }

    final label = TextPainter(
      text: TextSpan(
        text: stale ? 'LAST REPORTED' : 'LIVE FLOW',
        style: TextStyle(
          color: stale ? muted : cyan,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    label.paint(canvas, Offset(left, 8));
  }

  @override
  bool shouldRepaint(covariant _DrainageSchematicPainter oldDelegate) =>
      oldDelegate.phase != phase ||
      oldDelegate.waterPercent != waterPercent ||
      oldDelegate.stage != stage ||
      oldDelegate.stale != stale ||
      oldDelegate.cyan != cyan ||
      oldDelegate.surface != surface;
}
