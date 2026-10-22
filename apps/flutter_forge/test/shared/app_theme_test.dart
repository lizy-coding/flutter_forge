import 'package:flutter/material.dart';
import 'package:flutter_forge_app/app/app.dart';
import 'package:flutter_forge_app/app/app_platform_provider.dart';
import 'package:flutter_forge_app/app/router/app_router.dart';
import 'package:flutter_forge_app/app/theme/app_theme.dart';
import 'package:flutter_forge_app/app/theme/app_theme_controller.dart';
import 'package:flutter_forge_app/app/theme/app_theme_selection.dart';
import 'package:flutter_forge_app/app/theme/forge_theme_tokens.dart';
import 'package:flutter_forge_app/app/theme/forge_glass.dart';
import 'package:flutter_forge_app/module_registry/app_platform_snapshot.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';

const _android = AppPlatformSnapshot(platform: AppTargetPlatform.android);

void main() {
  test('Graphite Forge exposes stable workbench and semantic colors', () {
    final dark = AppTheme.dark(AppThemePalette.graphiteForge);
    final light = AppTheme.light(AppThemePalette.graphiteForge);

    expect(dark.scaffoldBackgroundColor, const Color(0xFF0B0F14));
    expect(dark.colorScheme.primary, const Color(0xFF55C2F3));
    expect(
      dark.extension<ForgeThemeTokens>()!.aiAccent,
      const Color(0xFFA78BFA),
    );
    expect(light.scaffoldBackgroundColor, const Color(0xFFF3F6F9));
    expect(light.colorScheme.primary, const Color(0xFF087EA4));
  });

  test('theme preference persists across controller reloads', () async {
    SharedPreferences.setMockInitialValues({});
    final controller = await AppThemeController.load();

    await controller.setMode(AppThemeModePreference.dark);
    final restored = await AppThemeController.load();

    expect(restored.mode, AppThemeModePreference.dark);
    expect(restored.palette, AppThemePalette.liquidGlass);
  });

  test('legacy mode-only preferences migrate to the default palette', () {
    final selection = AppThemeSelection.decode('dark');

    expect(selection.mode, AppThemeModePreference.dark);
    expect(selection.palette, AppThemePalette.liquidGlass);
    expect(AppThemeSelection.decode(selection.encode()), selection);
  });

  test('glass is the default and explicit palette choices persist', () async {
    SharedPreferences.setMockInitialValues({});
    final controller = await AppThemeController.load();
    expect(controller.palette, AppThemePalette.liquidGlass);

    await controller.setSelection(
      const AppThemeSelection(
        mode: AppThemeModePreference.dark,
        palette: AppThemePalette.graphiteForge,
      ),
    );
    final restoredGraphite = await AppThemeController.load();
    expect(restoredGraphite.selection, controller.selection);

    await controller.setPalette(AppThemePalette.liquidGlass);
    final restoredGlass = await AppThemeController.load();
    expect(restoredGlass.selection, controller.selection);
    expect(restoredGlass.mode, AppThemeModePreference.dark);
    expect(
      AppThemeSelection.decode('{"palette":"future"}').palette,
      AppThemePalette.liquidGlass,
    );
    controller.dispose();
    restoredGraphite.dispose();
    restoredGlass.dispose();
  });

  testWidgets('switching palettes preserves the active route and brightness', (
    tester,
  ) async {
    final controller = AppThemeController.forTesting(
      const AppThemeSelection(mode: AppThemeModePreference.dark),
    );
    final router = AppRouter.create(_android);
    addTearDown(router.dispose);
    addTearDown(controller.dispose);
    await tester.binding.setSurfaceSize(const Size(1100, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appPlatformProvider.overrideWithValue(_android)],
        child: App(router: router, themeController: controller),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(LiquidGlassLens), findsWidgets);
    router.go('/category/basic');
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('theme-mode-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('theme-palette:graphiteForge')));
    await tester.pumpAndSettle();
    expect(find.byType(LiquidGlassLens), findsNothing);
    expect(find.byKey(const ValueKey('category-page:basic')), findsOneWidget);
    expect(_brightnessOf(tester), Brightness.dark);

    await tester.tap(find.byKey(const ValueKey('theme-mode-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('theme-palette:liquidGlass')));
    await tester.pumpAndSettle();
    expect(controller.palette, AppThemePalette.liquidGlass);
    expect(find.byType(LiquidGlassLens), findsWidgets);
    expect(router.routeInformationProvider.value.uri.path, '/category/basic');
    expect(_brightnessOf(tester), Brightness.dark);
    expect(tester.takeException(), isNull);
  });

  testWidgets('compact glass home navigates to a category without overflow', (
    tester,
  ) async {
    final controller = AppThemeController.forTesting();
    final router = AppRouter.create(_android);
    addTearDown(router.dispose);
    addTearDown(controller.dispose);
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appPlatformProvider.overrideWithValue(_android)],
        child: App(router: router, themeController: controller),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('learning-category:basic')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('category-page:basic')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('high contrast keeps glass controls on an opaque surface', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(AppThemePalette.liquidGlass),
        home: const MediaQuery(
          data: MediaQueryData(highContrast: true),
          child: Center(child: ForgeGlassSurface(child: Text('高对比度内容'))),
        ),
      ),
    );
    expect(find.text('高对比度内容'), findsOneWidget);
    expect(find.byType(LiquidGlassLens), findsNothing);
  });

  testWidgets('theme selection remains active across top-level routes', (
    tester,
  ) async {
    final controller = AppThemeController.forTesting(
      const AppThemeSelection(mode: AppThemeModePreference.light),
    );
    final router = AppRouter.create(_android);
    addTearDown(router.dispose);
    await tester.binding.setSurfaceSize(const Size(800, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appPlatformProvider.overrideWithValue(_android)],
        child: App(router: router, themeController: controller),
      ),
    );
    await tester.pumpAndSettle();
    expect(_brightnessOf(tester), Brightness.light);

    await tester.tap(find.byKey(const ValueKey('theme-mode-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('theme-mode:dark')));
    await tester.pumpAndSettle();
    expect(controller.mode, AppThemeModePreference.dark);
    expect(_brightnessOf(tester), Brightness.dark);

    router.go('/category/basic');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('category-page:basic')), findsOneWidget);
    expect(_brightnessOf(tester), Brightness.dark);
    expect(tester.takeException(), isNull);
  });
}

Brightness _brightnessOf(WidgetTester tester) {
  final context = tester.element(find.byType(Scaffold).first);
  return Theme.of(context).brightness;
}
