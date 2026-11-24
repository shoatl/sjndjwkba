import 'package:flutter/material.dart';

class AppColors extends ThemeExtension<AppColors> {
  const AppColors({required this.primary, required this.onPrimary, required this.surface, required this.onSurface, required this.onSurfaceVariant, required this.outline, required this.primaryContainer, required this.onPrimaryContainer, required this.surfaceContainerHighest, required this.error, required this.errorContainer, required this.shadow});
  final Color primary, onPrimary, surface, onSurface, onSurfaceVariant, outline, primaryContainer, onPrimaryContainer, surfaceContainerHighest, error, errorContainer, shadow;
  @override AppColors copyWith({Color? primary, Color? onPrimary, Color? surface, Color? onSurface, Color? onSurfaceVariant, Color? outline, Color? primaryContainer, Color? onPrimaryContainer, Color? surfaceContainerHighest, Color? error, Color? errorContainer, Color? shadow}) => AppColors(primary: primary ?? this.primary, onPrimary: onPrimary ?? this.onPrimary, surface: surface ?? this.surface, onSurface: onSurface ?? this.onSurface, onSurfaceVariant: onSurfaceVariant ?? this.onSurfaceVariant, outline: outline ?? this.outline, primaryContainer: primaryContainer ?? this.primaryContainer, onPrimaryContainer: onPrimaryContainer ?? this.onPrimaryContainer, surfaceContainerHighest: surfaceContainerHighest ?? this.surfaceContainerHighest, error: error ?? this.error, errorContainer: errorContainer ?? this.errorContainer, shadow: shadow ?? this.shadow);
  @override AppColors lerp(ThemeExtension<AppColors>? other, double t) => other is AppColors ? AppColors(primary: Color.lerp(primary, other.primary, t)!, onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!, surface: Color.lerp(surface, other.surface, t)!, onSurface: Color.lerp(onSurface, other.onSurface, t)!, onSurfaceVariant: Color.lerp(onSurfaceVariant, other.onSurfaceVariant, t)!, outline: Color.lerp(outline, other.outline, t)!, primaryContainer: Color.lerp(primaryContainer, other.primaryContainer, t)!, onPrimaryContainer: Color.lerp(onPrimaryContainer, other.onPrimaryContainer, t)!, surfaceContainerHighest: Color.lerp(surfaceContainerHighest, other.surfaceContainerHighest, t)!, error: Color.lerp(error, other.error, t)!, errorContainer: Color.lerp(errorContainer, other.errorContainer, t)!, shadow: Color.lerp(shadow, other.shadow, t)!) : this;
}

class AppStatusColors {
  const AppStatusColors({required this.normal, required this.stage1, required this.stage2, required this.stage3, required this.stale});
  final Color normal, stage1, stage2, stage3, stale;
  Color forStage(int stage) => stage <= 0 ? normal : stage == 1 ? stage1 : stage == 2 ? stage2 : stage3;
}

extension AppThemeContext on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
  AppStatusColors get status => const AppStatusColors(normal: Color(0xFF2E7D32), stage1: Color(0xFFF9A825), stage2: Color(0xFFEF6C00), stage3: Color(0xFFC62828), stale: Color(0xFF757575));
}

class AppTheme {
  static final light = _theme(Brightness.light);
  static final dark = _theme(Brightness.dark);

  static ThemeData _theme(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF1565C0), brightness: brightness);
    final colors = AppColors(primary: scheme.primary, onPrimary: scheme.onPrimary, surface: scheme.surface, onSurface: scheme.onSurface, onSurfaceVariant: scheme.onSurfaceVariant, outline: scheme.outline, primaryContainer: scheme.primaryContainer, onPrimaryContainer: scheme.onPrimaryContainer, surfaceContainerHighest: scheme.surfaceContainerHighest, error: scheme.error, errorContainer: scheme.errorContainer, shadow: scheme.shadow);
    return ThemeData(colorScheme: scheme, brightness: brightness, useMaterial3: true, extensions: [colors]);
  }
}
