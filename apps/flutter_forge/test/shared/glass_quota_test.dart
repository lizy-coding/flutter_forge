import 'package:flutter/material.dart';
import 'package:flutter_forge_app/app/app.dart';
import 'package:flutter_forge_app/app/app_platform_provider.dart';
import 'package:flutter_forge_app/app/desktop_window_host.dart';
import 'package:flutter_forge_app/app/router/app_router.dart';
import 'package:flutter_forge_app/app/theme/app_theme_controller.dart';
import 'package:flutter_forge_app/app/theme/app_theme_selection.dart';
import 'package:flutter_forge_app/app/workbench_history.dart';
import 'package:flutter_forge_app/module_registry/app_platform_snapshot.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';

void main() {
  Future<GoRouter> pumpWorkbench(
    WidgetTester tester,
    AppThemeController theme,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const platform = AppPlatformSnapshot(platform: AppTargetPlatform.macOS);
    final router = AppRouter.create(platform);
    final history = WorkbenchHistory();
    addTearDown(router.dispose);
    addTearDown(history.dispose);
    addTearDown(theme.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appPlatformProvider.overrideWithValue(platform)],
        child: WorkbenchHistoryScope(
          history: history,
          child: App(router: router, themeController: theme),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  void mockMaterial(WidgetTester tester, bool active) {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      DesktopWindowHost.channel,
      (call) async => {
        'materialActive':
            active && (call.arguments as Map?)?['materialEnabled'] == true,
        'transparencyAllowed': true,
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        DesktopWindowHost.channel,
        null,
      ),
    );
  }

  testWidgets('native material keeps cards solid with no backdrop blur', (
    tester,
  ) async {
    mockMaterial(tester, true);
    final router = await pumpWorkbench(
      tester,
      AppThemeController.forTesting(
        const AppThemeSelection(palette: AppThemePalette.liquidGlass),
      ),
    );
    expect(find.byType(BackdropFilter), findsNothing);
    expect(find.byType(LiquidGlassLens), findsNothing);
    router.go('/category/basic');
    await tester.pumpAndSettle();
    expect(find.byType(BackdropFilter), findsNothing);
    expect(find.byType(LiquidGlassLens), findsNothing);
    expect(tester.takeException(), isNull);
  }, variant: const TargetPlatformVariant({TargetPlatform.macOS}));

  testWidgets('material loss falls back to solid chrome without glass cards', (
    tester,
  ) async {
    mockMaterial(tester, false);
    final router = await pumpWorkbench(
      tester,
      AppThemeController.forTesting(
        const AppThemeSelection(palette: AppThemePalette.liquidGlass),
      ),
    );
    expect(find.byType(BackdropFilter), findsNothing);
    expect(find.byType(LiquidGlassLens), findsNothing);
    router.go('/category/basic');
    await tester.pumpAndSettle();
    expect(find.byType(BackdropFilter), findsNothing);
    expect(find.byType(LiquidGlassLens), findsNothing);
    expect(tester.takeException(), isNull);
  }, variant: const TargetPlatformVariant({TargetPlatform.macOS}));
}
