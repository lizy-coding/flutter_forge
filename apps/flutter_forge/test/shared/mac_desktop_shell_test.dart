import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_forge_app/app/theme/app_theme.dart';
import 'package:flutter_forge_app/app/theme/app_theme_selection.dart';
import 'package:flutter_forge_app/app/theme/forge_theme_tokens.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('macOS uses neutral opaque content and transparent host backdrop', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    for (final theme in [
      AppTheme.light(AppThemePalette.liquidGlass),
      AppTheme.dark(AppThemePalette.liquidGlass),
    ]) {
      final tokens = theme.extension<ForgeThemeTokens>()!;
      expect(tokens.nativeDesktop, isTrue);
      expect(tokens.glass, isFalse);
      expect(tokens.sidebar, Colors.transparent);
      expect(theme.scaffoldBackgroundColor.a, 1);
      expect(theme.appBarTheme.toolbarHeight, 44);
    }
  });
}
