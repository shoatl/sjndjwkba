import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'app_card.dart';

/// A lightweight, touch-orbitable 3D-style cutaway of the monitored channel.
/// The view is a visualization only; all displayed level/status values come
/// from the existing node controller.
class InteractiveDrainageView extends StatefulWidget {
  const InteractiveDrainageView({
    super.key,
    required this.waterPercent,
    required this.stage,
    required this.isStale,
  });

  final double? waterPercent;
  final int stage;
  final bool isStale;

  @override
  State<InteractiveDrainageView> createState() => _InteractiveDrainageViewState();
}

class _InteractiveDrainageViewState extends State<InteractiveDrainageView> {
  double _yaw = -0.62;
  double _pitch = 0.34;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final status = widget.isStale
        ? context.status.stale
        : context.status.forStage(widget.stage);

    return AppCard(
      title: 'Interactive 3D cutaway',
      subtitle: 'Drag to rotate the channel view',
      trailing: Icon(Icons.view_in_ar_rounded, color: scheme.primary),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Column(
        children: [
          SizedBox(
            height: 210,
            width: double.infinity,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanUpdate: (details) => setState(() {
                _yaw += details.delta.dx * 0.009;
                _pitch = (_pitch - details.delta.dy * 0.006).clamp(-0.12, 0.82).toDouble();
              }),
              child: CustomPaint(
                painter: _Channel3DPainter(
                  yaw: _yaw,
                  pitch: _pitch,
                  waterPercent: widget.waterPercent,
                  waterColor: status,
                  accent: scheme.primary,
                  muted: scheme.onSurfaceVariant,
                  stale: widget.isStale,
                ),
                child: const SizedBox.expand(),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.pan_tool_alt_rounded, size: 15, color: scheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  widget.isStale
                      ? 'Last-known level · not a live reading'
                      : 'Current node level · Stage ${widget.stage}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ),
              TextButton.icon(
                onPressed: () => setState(() {
                  _yaw = -0.62;
                  _pitch = 0.34;
                }),
                icon: const Icon(Icons.center_focus_strong_rounded, size: 16),
                label: const Text('Reset view'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Channel3DPainter extends CustomPainter {
  _Channel3DPainter({
    required this.yaw,
    required this.pitch,
    required this.waterPercent,
    required this.waterColor,
    required this.accent,
    required this.muted,
    required this.stale,
  });

  final double yaw;
  final double pitch;
  final double? waterPercent;
  final Color waterColor;
  final Color accent;
  final Color muted;
  final bool stale;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.54);
    final scale = math.min(size.width * 0.34, size.height * 0.78).toDouble();
    Offset project(double x, double y, double z) {
      final cy = math.cos(yaw), sy = math.sin(yaw);
      final cp = math.cos(pitch), sp = math.sin(pitch);
      final rx = x * cy - z * sy;
      final rz = x * sy + z * cy;
      final ry = y * cp - rz * sp;
      final depth = 1.0 + (rz * 0.10);
      return Offset(center.dx + rx * scale / depth, center.dy + ry * scale / depth);
    }

    final top = <Offset>[
      project(-1.2, -0.42, -0.62),
      project(1.2, -0.42, -0.62),
      project(1.2, -0.42, 0.62),
      project(-1.2, -0.42, 0.62),
    ];
    final base = <Offset>[
      project(-1.2, 0.46, -0.62),
      project(1.2, 0.46, -0.62),
      project(1.2, 0.46, 0.62),
      project(-1.2, 0.46, 0.62),
    ];

    Path polygon(List<Offset> points) => Path()..addPolygon(points, true);
    final opacity = stale ? 0.42 : 1.0;
    final shell = Paint()..color = const Color(0xFF17374A).withOpacity(opacity);
    final side = Paint()..color = const Color(0xFF0B2435).withOpacity(opacity);
    final edge = Paint()
      ..color = accent.withOpacity(0.88 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7;

    canvas.drawPath(polygon([top[1], top[2], base[2], base[1]]), side);
    canvas.drawPath(polygon([top[0], top[1], base[1], base[0]]), shell);
    canvas.drawPath(polygon(top), Paint()..color = const Color(0xFF21485C).withOpacity(opacity));
    canvas.drawPath(polygon([top[0], top[1], base[1], base[0]]), edge);
    canvas.drawPath(polygon([top[1], top[2], base[2], base[1]]), edge);

    final pct = ((waterPercent ?? 0).clamp(0.0, 100.0) / 100.0).toDouble();
    final waterY = 0.42 - pct * 0.76;
    final water = <Offset>[
      project(-1.16, waterY, -0.58),
      project(1.16, waterY, -0.58),
      project(1.16, waterY, 0.58),
      project(-1.16, waterY, 0.58),
    ];
    canvas.drawPath(
      polygon(water),
      Paint()..color = waterColor.withOpacity((waterPercent == null ? 0.12 : 0.58) * opacity),
    );
    canvas.drawPath(polygon(water), Paint()
      ..color = waterColor.withOpacity(opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5);

    // One real monitored node is represented by one sensor mast.
    final mastBase = project(-0.48, -0.43, 0.0);
    final mastTop = project(-0.48, -1.05, 0.0);
    canvas.drawLine(mastBase, mastTop, Paint()
      ..color = stale ? muted : accent
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round);
    canvas.drawCircle(mastTop, 6, Paint()..color = stale ? muted : accent);
    canvas.drawCircle(mastTop, 11, Paint()
      ..color = (stale ? muted : accent).withOpacity(0.18));

    final label = TextPainter(
      text: TextSpan(
        text: stale ? 'NODE · LAST KNOWN' : 'MONITORED NODE',
        style: TextStyle(color: stale ? muted : accent, fontSize: 9,
          fontWeight: FontWeight.w800, letterSpacing: 1.1),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    label.paint(canvas, Offset(12, 10));

    final level = TextPainter(
      text: TextSpan(
        text: waterPercent == null ? 'NO LEVEL DATA' : '${waterPercent!.round()}%',
        style: TextStyle(color: Colors.white.withOpacity(opacity),
          fontSize: 15, fontWeight: FontWeight.w900),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    level.paint(canvas, Offset(size.width - level.width - 14, 10));
  }

  @override
  bool shouldRepaint(covariant _Channel3DPainter old) =>
      old.yaw != yaw || old.pitch != pitch || old.waterPercent != waterPercent ||
      old.waterColor != waterColor || old.stale != stale;
}
