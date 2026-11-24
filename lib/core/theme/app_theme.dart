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

    final baseText = ThemeData(
      brightness: mode.brightness,
      useMaterial3: true,
    ).textTheme;
    final textTheme = baseText.copyWith(
      headlineSmall: baseText.headlineSmall?.copyWith(
        fontSize: 25,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.55,
        height: 1.15,
      ),
      titleLarge: baseText.titleLarge?.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
      titleMedium: baseText.titleMedium?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
      ),
      titleSmall: baseText.titleSmall?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
      bodyLarge: baseText.bodyLarge?.copyWith(
        fontSize: 15,
        height: 1.45,
        letterSpacing: 0.05,
      ),
      bodyMedium: baseText.bodyMedium?.copyWith(
        fontSize: 13.5,
        height: 1.4,
        letterSpacing: 0.05,
      ),
      bodySmall: baseText.bodySmall?.copyWith(
        fontSize: 12,
        height: 1.35,
        letterSpacing: 0.1,
      ),
      labelLarge: baseText.labelLarge?.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.15,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      visualDensity: VisualDensity.standard,
      colorScheme: scheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: mode.surface,
      dividerColor: mode.outlineVariant.withAlpha(130),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: mode.surfaceContainerHighest.withAlpha(238),
        indicatorColor: mode.primary.withAlpha(30),
        elevation: 0,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
          fontSize: 11,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
          color: states.contains(WidgetState.selected)
              ? mode.primary
              : mode.onSurfaceVariant,
        )),
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? mode.primary
              : mode.onSurfaceVariant,
        )),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: mode.surfaceContainerHighest,
        contentTextStyle: TextStyle(color: mode.onSurface),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: mode.surface.withAlpha(238),
        foregroundColor: mode.onSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(color: mode.onSurface),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: mode.surfaceContainerHighest.withAlpha(150),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        labelStyle: TextStyle(color: mode.onSurfaceVariant, fontSize: 13),
        hintStyle: TextStyle(color: mode.onSurfaceVariant.withAlpha(190)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: mode.outline.withAlpha(125)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: mode.outline.withAlpha(125)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: mode.primary, width: 1.6),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          textStyle: textTheme.labelLarge,
          side: BorderSide(color: mode.outline.withAlpha(180)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: mode.surfaceContainerHighest.withAlpha(225),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: mode.outline.withAlpha(105)),
        ),
      ),
      extensions: [statusColors],
    );
  }
}

extension AppThemeContext on BuildContext {
  ColorScheme get colors => Theme.of(this).colorScheme;
  StatusColors get status => Theme.of(this).extension<StatusColors>()!;
}
