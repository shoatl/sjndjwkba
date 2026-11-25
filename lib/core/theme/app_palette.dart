import 'package:flutter/material.dart';

@immutable
class PaletteMode {
  const PaletteMode({
    required this.brightness,
    required this.primary,
    required this.onPrimary,
    required this.primaryContainer,
    required this.onPrimaryContainer,
    required this.secondary,
    required this.onSecondary,
    required this.surface,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.surfaceContainerHighest,
    required this.outline,
    required this.outlineVariant,
    required this.error,
    required this.onError,
    required this.normal,
    required this.stage1,
    required this.stage2,
    required this.stage3,
    required this.stale,
  });

  final Brightness brightness;
  final Color primary;
  final Color onPrimary;
  final Color primaryContainer;
  final Color onPrimaryContainer;
  final Color secondary;
  final Color onSecondary;
  final Color surface;
  final Color onSurface;
  final Color onSurfaceVariant;
  final Color surfaceContainerHighest;
  final Color outline;
  final Color outlineVariant;
  final Color error;
  final Color onError;
  final Color normal;
  final Color stage1;
  final Color stage2;
  final Color stage3;
  final Color stale;
}

@immutable
class AppPalette {
  const AppPalette({required this.light, required this.dark});

  final PaletteMode light;
  final PaletteMode dark;

  static const AppPalette pasig = AppPalette(
    light: PaletteMode(
      brightness: Brightness.light,
      primary: Color(0xFF1E3A8A),
      onPrimary: Color(0xFFFFFFFF),
      primaryContainer: Color(0xFFDBEAFE),
      onPrimaryContainer: Color(0xFF1E3A8A),
      secondary: Color(0xFF0284C7),
      onSecondary: Color(0xFFFFFFFF),
      surface: Color(0xFFF8FAFC),
      onSurface: Color(0xFF0F172A),
      onSurfaceVariant: Color(0xFF475569),
      surfaceContainerHighest: Color(0xFFE2E8F0),
      outline: Color(0xFF94A3B8),
      outlineVariant: Color(0xFFCBD5E1),
      error: Color(0xFFDC2626),
      onError: Color(0xFFFFFFFF),
      normal: Color(0xFF16A34A),
      stage1: Color(0xFFCA8A04),
      stage2: Color(0xFFEA580C),
      stage3: Color(0xFFDC2626),
      stale: Color(0xFF64748B),
    ),
    // SCADA-inspired midnight navy with restrained cyan highlights.
    dark: PaletteMode(
      brightness: Brightness.dark,
      primary: Color(0xFF39C9E8),
      onPrimary: Color(0xFF042133),
      primaryContainer: Color(0xFF123C54),
      onPrimaryContainer: Color(0xFFB8F2FF),
      secondary: Color(0xFF67D6EB),
      onSecondary: Color(0xFF062635),
      surface: Color(0xFF061426),
      onSurface: Color(0xFFEAF5FF),
      onSurfaceVariant: Color(0xFF9BB2C8),
      surfaceContainerHighest: Color(0xFF10253D),
      outline: Color(0xFF31516A),
      outlineVariant: Color(0xFF203B55),
      error: Color(0xFFFF6875),
      onError: Color(0xFF3B0910),
      normal: Color(0xFF43D9A0),
      stage1: Color(0xFFF4C95D),
      stage2: Color(0xFFFFA64D),
      stage3: Color(0xFFFF5968),
      stale: Color(0xFF8298AA),
    ),
  );

  static const AppPalette maybunga = AppPalette(
    light: PaletteMode(
      brightness: Brightness.light,
      primary: Color(0xFF166534),
      onPrimary: Color(0xFFFFFFFF),
      primaryContainer: Color(0xFFDCFCE7),
      onPrimaryContainer: Color(0xFF14532D),
      secondary: Color(0xFF0D9488),
      onSecondary: Color(0xFFFFFFFF),
      surface: Color(0xFFF8FAFC),
      onSurface: Color(0xFF0F172A),
      onSurfaceVariant: Color(0xFF475569),
      surfaceContainerHighest: Color(0xFFE2E8F0),
      outline: Color(0xFF94A3B8),
      outlineVariant: Color(0xFFCBD5E1),
      error: Color(0xFFDC2626),
      onError: Color(0xFFFFFFFF),
      normal: Color(0xFF16A34A),
      stage1: Color(0xFFCA8A04),
      stage2: Color(0xFFEA580C),
      stage3: Color(0xFFDC2626),
      stale: Color(0xFF64748B),
    ),
    dark: PaletteMode(
      brightness: Brightness.dark,
      primary: Color(0xFF86EFAC),
      onPrimary: Color(0xFF14532D),
      primaryContainer: Color(0xFF166534),
      onPrimaryContainer: Color(0xFFDCFCE7),
      secondary: Color(0xFF2DD4BF),
      onSecondary: Color(0xFF134E4A),
      surface: Color(0xFF0F172A),
      onSurface: Color(0xFFF8FAFC),
      onSurfaceVariant: Color(0xFF94A3B8),
      surfaceContainerHighest: Color(0xFF1E293B),
      outline: Color(0xFF64748B),
      outlineVariant: Color(0xFF334155),
      error: Color(0xFFF87171),
      onError: Color(0xFF7F1D1D),
      normal: Color(0xFF22C55E),
      stage1: Color(0xFFEAB308),
      stage2: Color(0xFFF97316),
      stage3: Color(0xFFEF4444),
      stale: Color(0xFF94A3B8),
    ),
  );
}

const AppPalette activePalette = AppPalette.pasig;
