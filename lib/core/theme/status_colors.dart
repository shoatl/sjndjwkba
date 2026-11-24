import 'package:flutter/material.dart';

@immutable
class StatusColors extends ThemeExtension<StatusColors> {
  const StatusColors({
    required this.normal,
    required this.stage1,
    required this.stage2,
    required this.stage3,
    required this.stale,
  });

  final Color normal;
  final Color stage1;
  final Color stage2;
  final Color stage3;
  final Color stale;

  Color forStage(int stage) {
    switch (stage) {
      case 1:
        return stage1;
      case 2:
        return stage2;
      case 3:
        return stage3;
      default:
        return normal;
    }
  }

  static Color on(Color background) {
    return ThemeData.estimateBrightnessForColor(background) == Brightness.dark
        ? const Color(0xFFFFFFFF)
        : const Color(0xFF111827);
  }

  @override
  StatusColors copyWith({
    Color? normal,
    Color? stage1,
    Color? stage2,
    Color? stage3,
    Color? stale,
  }) {
    return StatusColors(
      normal: normal ?? this.normal,
      stage1: stage1 ?? this.stage1,
      stage2: stage2 ?? this.stage2,
      stage3: stage3 ?? this.stage3,
      stale: stale ?? this.stale,
    );
  }

  @override
  StatusColors lerp(ThemeExtension<StatusColors>? other, double t) {
    if (other is! StatusColors) return this;
    return StatusColors(
      normal: Color.lerp(normal, other.normal, t)!,
      stage1: Color.lerp(stage1, other.stage1, t)!,
      stage2: Color.lerp(stage2, other.stage2, t)!,
      stage3: Color.lerp(stage3, other.stage3, t)!,
      stale: Color.lerp(stale, other.stale, t)!,
    );
  }
}
