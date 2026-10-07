import 'dart:convert';

import 'package:flutter/material.dart';

enum AppThemeModePreference {
  system,
  light,
  dark;

  ThemeMode get themeMode => switch (this) {
    AppThemeModePreference.system => ThemeMode.system,
    AppThemeModePreference.light => ThemeMode.light,
    AppThemeModePreference.dark => ThemeMode.dark,
  };

  String get label => switch (this) {
    AppThemeModePreference.system => '跟随系统',
    AppThemeModePreference.light => '白日模式',
    AppThemeModePreference.dark => '黑暗模式',
  };

  IconData get icon => switch (this) {
    AppThemeModePreference.system => Icons.brightness_auto_outlined,
    AppThemeModePreference.light => Icons.light_mode_outlined,
    AppThemeModePreference.dark => Icons.dark_mode_outlined,
  };

  static AppThemeModePreference parse(String? value) => values.firstWhere(
    (mode) => mode.name == value,
    orElse: () => AppThemeModePreference.system,
  );
}

enum AppThemePalette {
  graphiteForge;

  String get label => switch (this) {
    AppThemePalette.graphiteForge => 'Graphite Forge',
  };

  static AppThemePalette parse(String? value) => values.firstWhere(
    (palette) => palette.name == value,
    orElse: () => AppThemePalette.graphiteForge,
  );
}

@immutable
class AppThemeSelection {
  const AppThemeSelection({
    this.mode = AppThemeModePreference.system,
    this.palette = AppThemePalette.graphiteForge,
  });

  final AppThemeModePreference mode;
  final AppThemePalette palette;

  ThemeMode get themeMode => mode.themeMode;

  AppThemeSelection copyWith({
    AppThemeModePreference? mode,
    AppThemePalette? palette,
  }) => AppThemeSelection(
    mode: mode ?? this.mode,
    palette: palette ?? this.palette,
  );

  String encode() =>
      jsonEncode({'version': 1, 'mode': mode.name, 'palette': palette.name});

  static AppThemeSelection decode(String? payload) {
    if (payload == null || payload.isEmpty) return const AppThemeSelection();
    if (AppThemeModePreference.values.any((mode) => mode.name == payload)) {
      return AppThemeSelection(mode: AppThemeModePreference.parse(payload));
    }
    try {
      final json = jsonDecode(payload) as Map<String, dynamic>;
      return AppThemeSelection(
        mode: AppThemeModePreference.parse(json['mode'] as String?),
        palette: AppThemePalette.parse(json['palette'] as String?),
      );
    } on FormatException {
      return const AppThemeSelection();
    } on TypeError {
      return const AppThemeSelection();
    }
  }

  @override
  bool operator ==(Object other) =>
      other is AppThemeSelection &&
      other.mode == mode &&
      other.palette == palette;

  @override
  int get hashCode => Object.hash(mode, palette);
}
