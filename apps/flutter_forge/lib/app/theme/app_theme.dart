import 'package:flutter/material.dart';

import 'app_theme_selection.dart';
import 'forge_theme_tokens.dart';

@immutable
class AppThemeDefinition {
  const AppThemeDefinition({
    required this.palette,
    required this.lightScheme,
    required this.darkScheme,
    required this.lightTokens,
    required this.darkTokens,
  });

  final AppThemePalette palette;
  final ColorScheme lightScheme;
  final ColorScheme darkScheme;
  final ForgeThemeTokens lightTokens;
  final ForgeThemeTokens darkTokens;
}

abstract final class AppThemeCatalog {
  static final definitions = <AppThemePalette, AppThemeDefinition>{
    AppThemePalette.graphiteForge: AppThemeDefinition(
      palette: AppThemePalette.graphiteForge,
      lightScheme: _graphiteLight,
      darkScheme: _graphiteDark,
      lightTokens: ForgeThemeTokens.light,
      darkTokens: ForgeThemeTokens.dark,
    ),
  };

  static AppThemeDefinition definition(AppThemePalette palette) =>
      definitions[palette]!;
}

abstract final class AppTheme {
  static ThemeData light(AppThemePalette palette) =>
      _build(AppThemeCatalog.definition(palette), Brightness.light);

  static ThemeData dark(AppThemePalette palette) =>
      _build(AppThemeCatalog.definition(palette), Brightness.dark);

  static ThemeData _build(
    AppThemeDefinition definition,
    Brightness brightness,
  ) {
    final dark = brightness == Brightness.dark;
    final colors = dark ? definition.darkScheme : definition.lightScheme;
    final tokens = dark ? definition.darkTokens : definition.lightTokens;
    return ThemeData(
      brightness: brightness,
      colorScheme: colors,
      extensions: [tokens],
      useMaterial3: true,
      scaffoldBackgroundColor: tokens.canvas,
      cardTheme: CardThemeData(
        elevation: 0,
        color: colors.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.outlineVariant),
        ),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: colors.surface,
        foregroundColor: colors.onSurface,
      ),
      navigationDrawerTheme: NavigationDrawerThemeData(
        backgroundColor: tokens.sidebar,
        indicatorColor: colors.primaryContainer,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: tokens.sidebar,
        indicatorColor: colors.primaryContainer,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.primary, width: 1.5),
        ),
      ),
      dividerTheme: DividerThemeData(color: colors.outlineVariant),
    );
  }
}

final _graphiteLight =
    ColorScheme.fromSeed(
      seedColor: const Color(0xFF087EA4),
      brightness: Brightness.light,
    ).copyWith(
      primary: const Color(0xFF087EA4),
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFFD8F1FB),
      onPrimaryContainer: const Color(0xFF043849),
      secondary: const Color(0xFF7157C8),
      tertiary: const Color(0xFF16875D),
      error: const Color(0xFFC93C37),
      surface: const Color(0xFFF8FAFC),
      surfaceContainerLowest: const Color(0xFFFFFFFF),
      surfaceContainerLow: const Color(0xFFFFFFFF),
      surfaceContainer: const Color(0xFFFFFFFF),
      surfaceContainerHigh: const Color(0xFFEEF2F6),
      surfaceContainerHighest: const Color(0xFFEAF0F5),
      onSurface: const Color(0xFF17212B),
      onSurfaceVariant: const Color(0xFF526170),
      outline: const Color(0xFF9DAFBE),
      outlineVariant: const Color(0xFFD5DEE7),
    );

final _graphiteDark =
    ColorScheme.fromSeed(
      seedColor: const Color(0xFF55C2F3),
      brightness: Brightness.dark,
    ).copyWith(
      primary: const Color(0xFF55C2F3),
      onPrimary: const Color(0xFF002B3A),
      primaryContainer: const Color(0xFF123D55),
      onPrimaryContainer: const Color(0xFFC7EEFF),
      secondary: const Color(0xFFA78BFA),
      tertiary: const Color(0xFF45C486),
      error: const Color(0xFFF47067),
      surface: const Color(0xFF10161D),
      surfaceContainerLowest: const Color(0xFF0B0F14),
      surfaceContainerLow: const Color(0xFF131B24),
      surfaceContainer: const Color(0xFF17212B),
      surfaceContainerHigh: const Color(0xFF1A2530),
      surfaceContainerHighest: const Color(0xFF1D2935),
      onSurface: const Color(0xFFE8EEF5),
      onSurfaceVariant: const Color(0xFFA8B3BF),
      outline: const Color(0xFF405367),
      outlineVariant: const Color(0xFF2A3948),
    );
