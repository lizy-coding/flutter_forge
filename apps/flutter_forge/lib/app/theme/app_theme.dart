import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

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
    AppThemePalette.liquidGlass: AppThemeDefinition(
      palette: AppThemePalette.liquidGlass,
      lightScheme: _glassLight,
      darkScheme: _glassDark,
      lightTokens: ForgeThemeTokens.light.copyWith(
        canvas: const Color(0xFFEFF3FF),
        sidebar: Colors.transparent,
        glass: true,
      ),
      darkTokens: ForgeThemeTokens.dark.copyWith(
        canvas: const Color(0xFF101426),
        sidebar: Colors.transparent,
        glass: true,
      ),
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
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.macOS) {
      final scheme =
          ColorScheme.fromSeed(
            seedColor: const Color(0xFF007AFF),
            brightness: brightness,
          ).copyWith(
            primary: dark ? const Color(0xFF64A9FF) : const Color(0xFF0064D2),
            surface: dark ? const Color(0xFF252525) : const Color(0xFFFFFFFF),
            surfaceContainer: dark
                ? const Color(0xFF2C2C2C)
                : const Color(0xFFFFFFFF),
            surfaceContainerHighest: dark
                ? const Color(0xFF353535)
                : const Color(0xFFECECEC),
            onSurface: dark ? const Color(0xFFF1F1F1) : const Color(0xFF202020),
            onSurfaceVariant: dark
                ? const Color(0xFFBBBBBB)
                : const Color(0xFF606060),
            outlineVariant: dark
                ? const Color(0xFF414141)
                : const Color(0xFFDDDDDD),
          );
      final tokens = (dark ? ForgeThemeTokens.dark : ForgeThemeTokens.light)
          .copyWith(
            canvas: dark ? const Color(0xFF202020) : const Color(0xFFF5F5F5),
            sidebar: Colors.transparent,
            glass: false,
            nativeDesktop: true,
          );
      return ThemeData(
        platform: TargetPlatform.macOS,
        brightness: brightness,
        colorScheme: scheme,
        extensions: [tokens],
        useMaterial3: true,
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        typography: Typography.material2021(platform: TargetPlatform.macOS),
        scaffoldBackgroundColor: tokens.canvas,
        cardTheme: CardThemeData(
          color: scheme.surface,
          elevation: 0,
          margin: const EdgeInsets.all(4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: scheme.outlineVariant),
          ),
        ),
        appBarTheme: AppBarTheme(
          toolbarHeight: 44,
          backgroundColor: tokens.canvas,
          foregroundColor: scheme.onSurface,
          elevation: 0,
          scrolledUnderElevation: 0,
          titleTextStyle: TextStyle(
            color: scheme.onSurface,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        navigationRailTheme: NavigationRailThemeData(
          backgroundColor: Colors.transparent,
          indicatorColor: scheme.primary.withValues(alpha: 0.12),
        ),
        inputDecorationTheme: InputDecorationTheme(
          isDense: true,
          filled: true,
          fillColor: scheme.surface.withValues(alpha: 0.8),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 10,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: scheme.outlineVariant),
          ),
        ),
        dividerTheme: DividerThemeData(color: scheme.outlineVariant),
      );
    }
    final colors = dark ? definition.darkScheme : definition.lightScheme;
    final tokens = dark ? definition.darkTokens : definition.lightTokens;
    return ThemeData(
      brightness: brightness,
      colorScheme: colors,
      extensions: [tokens],
      useMaterial3: true,
      scaffoldBackgroundColor: tokens.glass
          ? Colors.transparent
          : tokens.canvas,
      cardTheme: CardThemeData(
        elevation: 0,
        color: tokens.glass
            ? colors.surfaceContainer.withValues(alpha: 0.68)
            : colors.surfaceContainer,
        surfaceTintColor: tokens.glass ? Colors.transparent : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.outlineVariant),
        ),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: tokens.glass
            ? colors.surface.withValues(alpha: 0.72)
            : colors.surface,
        foregroundColor: colors.onSurface,
      ),
      navigationDrawerTheme: NavigationDrawerThemeData(
        backgroundColor: tokens.glass
            ? colors.surface.withValues(alpha: 0.94)
            : tokens.sidebar,
        indicatorColor: colors.primaryContainer,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: tokens.sidebar,
        indicatorColor: colors.primaryContainer,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: tokens.glass
            ? colors.surfaceContainerHighest.withValues(alpha: 0.65)
            : colors.surfaceContainerHighest,
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
      menuTheme: tokens.glass
          ? MenuThemeData(
              style: MenuStyle(
                backgroundColor: WidgetStatePropertyAll(
                  colors.surface.withValues(alpha: 0.94),
                ),
                surfaceTintColor: const WidgetStatePropertyAll(
                  Colors.transparent,
                ),
              ),
            )
          : null,
      popupMenuTheme: tokens.glass
          ? PopupMenuThemeData(
              color: colors.surface.withValues(alpha: 0.94),
              surfaceTintColor: Colors.transparent,
            )
          : null,
      dialogTheme: tokens.glass
          ? DialogThemeData(
              backgroundColor: colors.surface.withValues(alpha: 0.94),
              surfaceTintColor: Colors.transparent,
            )
          : null,
      bottomSheetTheme: tokens.glass
          ? BottomSheetThemeData(
              backgroundColor: colors.surface.withValues(alpha: 0.94),
              modalBackgroundColor: colors.surface.withValues(alpha: 0.94),
              surfaceTintColor: Colors.transparent,
            )
          : null,
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

final _glassLight =
    ColorScheme.fromSeed(
      seedColor: const Color(0xFF5655C8),
      brightness: Brightness.light,
    ).copyWith(
      surface: const Color(0xFFF8FAFF),
      surfaceContainer: const Color(0xFFF3F5FF),
      onSurface: const Color(0xFF1B2340),
      onSurfaceVariant: const Color(0xFF46516B),
    );

final _glassDark =
    ColorScheme.fromSeed(
      seedColor: const Color(0xFFB8B7FF),
      brightness: Brightness.dark,
    ).copyWith(
      surface: const Color(0xFF1A2038),
      surfaceContainer: const Color(0xFF222B45),
      onSurface: const Color(0xFFF0F2FF),
      onSurfaceVariant: const Color(0xFFC2CAE3),
    );
