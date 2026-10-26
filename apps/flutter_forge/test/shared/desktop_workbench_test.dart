import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_forge_app/app/app.dart';
import 'package:flutter_forge_app/app/app_platform_provider.dart';
import 'package:flutter_forge_app/app/category_window_app.dart';
import 'package:flutter_forge_app/app/desktop_window_host.dart';
import 'package:flutter_forge_app/app/forge_nav_tile.dart';
import 'package:flutter_forge_app/app/router/app_route_table.dart';
import 'package:flutter_forge_app/app/router/app_router.dart';
import 'package:flutter_forge_app/app/theme/app_theme.dart';
import 'package:flutter_forge_app/app/theme/app_theme_controller.dart';
import 'package:flutter_forge_app/app/theme/app_theme_selection.dart';
import 'package:flutter_forge_app/app/theme/forge_theme_tokens.dart';
import 'package:flutter_forge_app/app/workbench_history.dart';
import 'package:flutter_forge_app/module_registry/app_platform_snapshot.dart';
import 'package:flutter_forge_app/module_registry/module_category.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _desktopPlatforms = TargetPlatformVariant({
  TargetPlatform.macOS,
  TargetPlatform.windows,
});
const _neutral = AppThemeSelection(palette: AppThemePalette.graphiteForge);

void main() {
  testWidgets('sidebar keyboard activates categories and modules', (
    tester,
  ) async {
    _mockHost(tester);
    final router = await _pump(tester);
    final module = AppRouteTable.modules.firstWhere(
      (module) => module.category == ModuleCategory.basic,
    );
    await tester.tap(find.byKey(const ValueKey('sidebar-category:basic')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    // Entering a category replaces the route's focus scope. Arm its sidebar
    // after the category page has mounted, then navigate using real key events.
    await tester.tap(find.byKey(const ValueKey('sidebar-category:basic')));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(
      tester
          .widget<ForgeNavTile>(
            find.byKey(ValueKey('sidebar-module:${module.path}')),
          )
          .keyboardActive,
      isTrue,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(router.routeInformationProvider.value.uri.path, module.path);

    await tester.tap(find.byKey(ValueKey('sidebar-module:${module.path}')));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.home);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(router.routeInformationProvider.value.uri.path, '/category/basic');
    expect(tester.takeException(), isNull);
  }, variant: _desktopPlatforms);

  test(
    'both desktop platforms share density, geometry and palette selection',
    () {
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      ThemeData? previous;
      for (final platform in [TargetPlatform.macOS, TargetPlatform.windows]) {
        debugDefaultTargetPlatformOverride = platform;
        final solid = AppTheme.light(AppThemePalette.graphiteForge);
        final glass = AppTheme.light(AppThemePalette.liquidGlass);
        expect(solid.extension<ForgeThemeTokens>()!.desktop, isTrue);
        expect(solid.extension<ForgeThemeTokens>()!.glass, isFalse);
        expect(glass.extension<ForgeThemeTokens>()!.glass, isTrue);
        expect(solid.visualDensity, VisualDensity.compact);
        if (previous != null) {
          expect(solid.colorScheme, previous.colorScheme);
          expect(solid.cardTheme, previous.cardTheme);
          expect(solid.platform, previous.platform);
        }
        previous = solid;
      }
    },
  );

  test(
    'desktop default does not migrate an explicit saved appearance',
    () async {
      SharedPreferences.setMockInitialValues({});
      final first = await AppThemeController.load(defaultSelection: _neutral);
      expect(first.palette, AppThemePalette.graphiteForge);
      await first.setPalette(AppThemePalette.liquidGlass);
      final second = await AppThemeController.load(defaultSelection: _neutral);
      expect(second.palette, AppThemePalette.liquidGlass);
      first.dispose();
      second.dispose();
    },
  );

  testWidgets('immersive controls and native state work on both desktops', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    try {
      final calls = _mockHost(tester);
      await _pump(tester);
      expect(
        tester.getSize(find.byKey(const ValueKey('immersive-titlebar'))).height,
        48,
      );
      expect(find.byKey(const ValueKey('workbench-home')), findsOneWidget);
      expect(find.byKey(const ValueKey('workbench-sidebar')), findsOneWidget);
      expect(find.bySemanticsLabel('快速打开'), findsOneWidget);
      expect(find.bySemanticsLabel('进入全屏'), findsOneWidget);
      expect(find.byKey(const ValueKey('window:minimize')), findsNothing);
      expect(find.byKey(const ValueKey('window:close')), findsNothing);
      for (final action in ['toggleFullscreen']) {
        await tester.tap(find.byKey(ValueKey('window:$action')));
        await tester.pump();
        expect(calls.any((call) => call.method == action), isTrue);
      }
      await _native(tester, 'windowState', {
        'fullscreen': true,
        'active': false,
      });
      await tester.pump();
      expect(find.byTooltip('退出全屏'), findsOneWidget);
      final beforeDoubleClick = calls
          .where((call) => call.method == 'captionDoubleClick')
          .length;
      await tester.tap(find.byKey(const ValueKey('titlebar-drag-area')));
      await tester.pump(const Duration(milliseconds: 60));
      await tester.tap(find.byKey(const ValueKey('titlebar-drag-area')));
      await tester.pumpAndSettle();
      expect(
        calls.where((call) => call.method == 'captionDoubleClick').length,
        beforeDoubleClick + 1,
      );
      await _native(tester, 'toggleSidebar');
      await tester.pump();
      expect(find.byKey(const ValueKey('workbench-sidebar')), findsNothing);
      await tester.tap(find.byTooltip('展开侧栏'));
      await tester.pump();
      await tester.binding.setSurfaceSize(const Size(800, 600));
      await tester.pump();
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  }, variant: _desktopPlatforms);

  testWidgets('quick open searches concepts, dismisses and opens one route', (
    tester,
  ) async {
    _mockHost(tester);
    final router = await _pump(tester);
    final module = AppRouteTable.modules.firstWhere(
      (m) => m.title == '三棵树与生命周期',
    );
    await tester.tap(find.byKey(const ValueKey('workbench-search')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('workbench-home')), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('quick-open-query')),
      'RenderObject',
    );
    await tester.pump();
    expect(find.byKey(ValueKey('quick-open:${module.path}')), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/');
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('quick-open-query')),
      module.title,
    );
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, module.path);
    expect(find.byKey(const ValueKey('module-quick-open')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('workbench-back')));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/');
    expect(find.byKey(ValueKey('recent:${module.path}')), findsOneWidget);
    expect(tester.takeException(), isNull);
  }, variant: _desktopPlatforms);

  testWidgets(
    'changing theme preserves module, sidebar and navigation history',
    (tester) async {
      _mockHost(tester);
      final theme = AppThemeController.forTesting(_neutral);
      addTearDown(theme.dispose);
      final router = await _pump(tester, theme: theme);
      router.go('/category/basic');
      await tester.pumpAndSettle();
      final module = AppRouteTable.modules.firstWhere(
        (m) => m.category == ModuleCategory.basic,
      );
      await tester.tap(find.byKey(ValueKey('module:${module.path}')));
      await tester.pumpAndSettle();
      await theme.setPalette(AppThemePalette.liquidGlass);
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, module.path);
      expect(
        find.byKey(ValueKey('sidebar-module:${module.path}')),
        findsOneWidget,
      );
      expect(
        tester
            .widget<ForgeNavTile>(
              find.byKey(ValueKey('sidebar-module:${module.path}')),
            )
            .selected,
        isTrue,
      );
      await _native(tester, 'back');
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/category/basic');
      await tester.tap(find.byKey(const ValueKey('workbench-home-button')));
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/');
      expect(find.byKey(const ValueKey('workbench-home')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
    variant: _desktopPlatforms,
  );

  testWidgets('sidebar marks the active category and about entries', (
    tester,
  ) async {
    _mockHost(tester);
    final router = await _pump(tester);
    router.go('/category/basic');
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<ForgeNavTile>(
            find.byKey(const ValueKey('sidebar-category:basic')),
          )
          .selected,
      isTrue,
    );
    router.go('/about');
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<ForgeNavTile>(find.byKey(const ValueKey('sidebar-about')))
          .selected,
      isTrue,
    );
    expect(tester.takeException(), isNull);
  }, variant: _desktopPlatforms);

  testWidgets('category windows use the shared chrome and scoped quick open', (
    tester,
  ) async {
    final calls = _mockHost(tester);
    await tester.binding.setSurfaceSize(const Size(800, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final theme = AppThemeController.forTesting(_neutral);
    addTearDown(theme.dispose);
    await tester.pumpWidget(
      CategoryWindowApp(
        category: ModuleCategory.basic,
        platform: AppPlatformSnapshot.detect(),
        themeController: theme,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('immersive-titlebar')), findsOneWidget);
    expect(find.text('关于 Flutter Forge'), findsNothing);
    expect(
      calls.any(
        (call) =>
            call.method == 'configure' &&
            (call.arguments as Map)['mainWindow'] == false,
      ),
      isTrue,
    );
    final search = _native(tester, 'search');
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('quick-open-query')),
      '蓝牙',
    );
    await tester.pump();
    expect(find.text('没有匹配模块，请尝试其他关键词'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    await search;
    expect(tester.takeException(), isNull);
  }, variant: _desktopPlatforms);

  test('recent visits are persisted, deduplicated and bounded', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final history = WorkbenchHistory(preferences: preferences);
    for (var i = 0; i < 12; i++) {
      history.record('/module-$i');
    }
    history.record('/module-5');
    await Future<void>.delayed(Duration.zero);
    final restored = WorkbenchHistory(preferences: preferences);
    expect(restored.recent, history.recent);
    expect(restored.recent, hasLength(8));
    expect(restored.recent.first, '/module-5');
    expect(restored.recent.toSet(), hasLength(8));
    history.dispose();
    restored.dispose();
  });
}

List<MethodCall> _mockHost(WidgetTester tester) {
  final calls = <MethodCall>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    DesktopWindowHost.channel,
    (call) async {
      calls.add(call);
      return {'active': true, 'fullscreen': false};
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      DesktopWindowHost.channel,
      null,
    ),
  );
  return calls;
}

Future<GoRouter> _pump(WidgetTester tester, {AppThemeController? theme}) async {
  await tester.binding.setSurfaceSize(const Size(1200, 800));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final platform = AppPlatformSnapshot.detect();
  final router = AppRouter.create(platform);
  final controller = theme ?? AppThemeController.forTesting(_neutral);
  final history = WorkbenchHistory();
  addTearDown(router.dispose);
  addTearDown(history.dispose);
  if (theme == null) addTearDown(controller.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [appPlatformProvider.overrideWithValue(platform)],
      child: WorkbenchHistoryScope(
        history: history,
        child: App(router: router, themeController: controller),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

Future<ByteData?> _native(
  WidgetTester tester,
  String command, [
  Object? arguments,
]) => tester.binding.defaultBinaryMessenger.handlePlatformMessage(
  DesktopWindowHost.channel.name,
  const StandardMethodCodec().encodeMethodCall(MethodCall(command, arguments)),
  (_) {},
);
