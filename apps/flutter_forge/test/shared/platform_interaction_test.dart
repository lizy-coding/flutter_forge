import 'package:flutter/material.dart';
import 'package:flutter_forge_app/app/app.dart';
import 'package:flutter_forge_app/app/app_platform_provider.dart';
import 'package:flutter_forge_app/app/desktop_window_host.dart';
import 'package:flutter_forge_app/app/router/app_router.dart';
import 'package:flutter_forge_app/app/theme/app_theme_controller.dart';
import 'package:flutter_forge_app/app/theme/app_theme_selection.dart';
import 'package:flutter_forge_app/app/theme/forge_glass.dart';
import 'package:flutter_forge_app/app/theme/forge_theme_tokens.dart';
import 'package:flutter_forge_app/app/workbench_history.dart';
import 'package:flutter_forge_app/module_registry/app_platform_snapshot.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets(
    'native basic pages become solid teaching without replacing router',
    (tester) async {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        DesktopWindowHost.channel,
        (call) async => {
          'materialActive':
              (call.arguments as Map?)?['materialEnabled'] == true,
          'transparencyAllowed': true,
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          DesktopWindowHost.channel,
          null,
        ),
      );
      final theme = AppThemeController.forTesting();
      final router = await _pump(tester, AppTargetPlatform.macOS, theme);
      expect(
        find.byKey(const ValueKey('native-material-backdrop')),
        findsOneWidget,
      );
      router.go('/tree-state');
      await tester.pumpAndSettle();
      final scope = tester.widget<ForgeSurfaceScope>(
        find.byType(ForgeSurfaceScope),
      );
      expect(scope.nativeMaterial, isTrue);
      expect(scope.teaching, isTrue);
      expect(
        tester
            .widget<ColoredBox>(
              find.byKey(const ValueKey('workbench-content-surface')),
            )
            .color
            .a,
        1,
      );
      final shellContext = tester.element(
        find.byKey(const ValueKey('desktop-workbench-shell')),
      );
      expect(shellContext.forgeColors.glass, isFalse);
      tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(highContrast: true);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('native-material-backdrop')),
        findsNothing,
      );
      tester.binding.platformDispatcher.clearAccessibilityFeaturesTestValue();
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('native-material-backdrop')),
        findsOneWidget,
      );
      await theme.setPalette(AppThemePalette.graphiteForge);
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/tree-state');
      expect(
        find.byKey(const ValueKey('native-material-backdrop')),
        findsNothing,
      );
      router.go('/category/basic');
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<ForgeSurfaceScope>(find.byType(ForgeSurfaceScope))
            .teaching,
        isFalse,
      );
      expect(tester.takeException(), isNull);
    },
    variant: const TargetPlatformVariant({TargetPlatform.macOS}),
  );

  testWidgets(
    'missing native material falls back to solid rather than simulated glass',
    (tester) async {
      await _pump(
        tester,
        AppTargetPlatform.macOS,
        AppThemeController.forTesting(),
      );
      expect(
        find.byKey(const ValueKey('native-material-backdrop')),
        findsNothing,
      );
      final context = tester.element(
        find.byKey(const ValueKey('workbench-home')),
      );
      expect(context.forgeColors.glass, isFalse);
      expect(tester.takeException(), isNull);
    },
    variant: const TargetPlatformVariant({TargetPlatform.macOS}),
  );

  testWidgets('mobile concept search returns to the same results and query', (
    tester,
  ) async {
    final router = await _pump(
      tester,
      AppTargetPlatform.android,
      AppThemeController.forTesting(
        const AppThemeSelection(palette: AppThemePalette.graphiteForge),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('learning-home-search')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'RenderObject');
    await tester.pumpAndSettle();
    await tester.tap(find.text('三棵树与生命周期'));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/tree-state');
    router.pop();
    await tester.pumpAndSettle();
    expect(find.text('RenderObject'), findsOneWidget);
    expect(find.text('三棵树与生命周期'), findsOneWidget);
    await tester.tap(find.byTooltip('返回'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('learning-home')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('category scroll survives route replacement', (tester) async {
    final router = await _pump(
      tester,
      AppTargetPlatform.android,
      AppThemeController.forTesting(),
    );
    router.go('/category/basic');
    await tester.pumpAndSettle();
    final scroll = find.byType(Scrollable).last;
    await tester.drag(scroll, const Offset(0, -440));
    await tester.pumpAndSettle();
    final previous = tester.state<ScrollableState>(scroll).position.pixels;
    expect(previous, greaterThan(0));
    router.go('/tree-state');
    await tester.pumpAndSettle();
    router.go('/category/basic');
    await tester.pumpAndSettle();
    expect(
      tester
          .state<ScrollableState>(find.byType(Scrollable).last)
          .position
          .pixels,
      closeTo(previous, 1),
    );
    expect(tester.takeException(), isNull);
  });
}

Future<GoRouter> _pump(
  WidgetTester tester,
  AppTargetPlatform target,
  AppThemeController theme,
) async {
  await tester.binding.setSurfaceSize(const Size(1100, 800));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final platform = AppPlatformSnapshot(platform: target);
  final router = AppRouter.create(platform);
  final history = WorkbenchHistory();
  addTearDown(router.dispose);
  addTearDown(theme.dispose);
  addTearDown(history.dispose);
  await tester.pumpWidget(
    WorkbenchHistoryScope(
      history: history,
      child: ProviderScope(
        overrides: [appPlatformProvider.overrideWithValue(platform)],
        child: App(router: router, themeController: theme),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}
