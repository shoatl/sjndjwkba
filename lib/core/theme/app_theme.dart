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

    final base = ThemeData(brightness: mode.brightness, useMaterial3: true);
    final statusColors = StatusColors(
      normal: mode.normal,
      stage1: mode.stage1,
      stage2: mode.stage2,
      stage3: mode.stage3,
      stale: mode.stale,
    );

    final text = base.textTheme.copyWith(
      headlineSmall: base.textTheme.headlineSmall?.copyWith(
        fontSize: 25,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.55,
        height: 1.15,
      ),
      titleLarge: base.textTheme.titleLarge?.copyWith(fontSize: 20, fontWeight: FontWeight.w700),
      titleMedium: base.textTheme.titleMedium?.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
      titleSmall: base.textTheme.titleSmall?.copyWith(fontSize: 14, fontWeight: FontWeight.w700),
      bodyLarge: base.textTheme.bodyLarge?.copyWith(fontSize: 15, height: 1.45),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(fontSize: 13.5, height: 1.4),
      bodySmall: base.textTheme.bodySmall?.copyWith(fontSize: 12, height: 1.35),
      labelLarge: base.textTheme.labelLarge?.copyWith(fontSize: 13, fontWeight: FontWeight.w700),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      textTheme: text,
      scaffoldBackgroundColor: mode.surface,
      dividerColor: mode.outlineVariant.withAlpha(120),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: mode.surface.withAlpha(248),
        indicatorColor: mode.primary.withAlpha(34),
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
          fontSize: 11,
          fontWeight: states.contains(WidgetState.selected) ? FontWeight.w800 : FontWeight.w500,
          color: states.contains(WidgetState.selected) ? mode.primary : mode.onSurfaceVariant,
        )),
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
          size: 22,
          color: states.contains(WidgetState.selected) ? mode.primary : mode.onSurfaceVariant,
        )),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: mode.surface.withAlpha(238),
        foregroundColor: mode.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: text.titleLarge?.copyWith(color: mode.onSurface, fontWeight: FontWeight.w700),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: mode.surfaceContainerHighest.withAlpha(170),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: TextStyle(color: mode.onSurfaceVariant.withAlpha(210)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: mode.outline.withAlpha(150)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: mode.outline.withAlpha(150)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: mode.primary, width: 1.8),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          backgroundColor: mode.primary,
          foregroundColor: mode.onPrimary,
          textStyle: text.labelLarge,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          foregroundColor: mode.onSurface,
          textStyle: text.labelLarge,
          side: BorderSide(color: mode.outline.withAlpha(190)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      cardTheme: CardThemeData(
        color: mode.surfaceContainerHighest.withAlpha(225),
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: mode.outline.withAlpha(120)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: mode.surfaceContainerHighest,
        contentTextStyle: TextStyle(color: mode.onSurface),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      choiceChipTheme: ChoiceChipThemeData(
        backgroundColor: mode.surfaceContainerHighest.withAlpha(170),
        selectedColor: mode.primary,
        side: BorderSide(color: mode.outline.withAlpha(120)),
        labelStyle: TextStyle(color: mode.onSurface, fontWeight: FontWeight.w700),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      extensions: [statusColors],
    );
  }
}

extension AppThemeContext on BuildContext {
  ColorScheme get colors => Theme.of(this).colorScheme;
  StatusColors get status => Theme.of(this).extension<StatusColors>()!;
}
