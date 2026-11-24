import 'package:flutter/material.dart';
import 'app_palette.dart';
import 'status_colors.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData get light => _build(activePalette.light);
  static ThemeData get dark => _build(activePalette.dark);

  static ThemeData _build(PaletteMode mode) {
    final scheme = ColorScheme(
      brightness: mode.brightness,
      primary: mode.primary,
      onPrimary: mode.onPrimary,
      primaryContainer: mode.primaryContainer,
      onPrimaryContainer: mode.onPrimaryContainer,
      secondary: mode.secondary,
      onSecondary: mode.onSecondary,
      surface: mode.surface,
      onSurface: mode.onSurface,
      onSurfaceVariant: mode.onSurfaceVariant,
      surfaceContainerHighest: mode.surfaceContainerHighest,
      outline: mode.outline,
      outlineVariant: mode.outlineVariant,
      error: mode.error,
      onError: mode.onError,
    );

    final statusColors = StatusColors(
      normal: mode.normal,
      stage1: mode.stage1,
      stage2: mode.stage2,
      stage3: mode.stage3,
      stale: mode.stale,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: mode.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: mode.surface,
        foregroundColor: mode.onSurface,
        elevation: 0,
        centerTitle: false,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: mode.surfaceContainerHighest,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      extensions: [statusColors],
    );
  }
}

extension AppThemeContext on BuildContext {
  ColorScheme get colors => Theme.of(this).colorScheme;
  StatusColors get status => Theme.of(this).extension<StatusColors>()!;
}
