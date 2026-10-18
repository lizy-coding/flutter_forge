import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_forge_app/app/app.dart';
import 'package:flutter_forge_app/app/app_platform_provider.dart';
import 'package:flutter_forge_app/app/forge_bubble_navigation.dart';
import 'package:flutter_forge_app/app/router/app_router.dart';
import 'package:flutter_forge_app/app/theme/app_theme.dart';
import 'package:flutter_forge_app/app/theme/app_theme_controller.dart';
import 'package:flutter_forge_app/app/theme/app_theme_selection.dart';
import 'package:flutter_forge_app/module_registry/app_platform_snapshot.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';

const _destinations = [
  ForgeNavigationDestination('首页', Icons.home_outlined),
  ForgeNavigationDestination('基础机制', Icons.widgets_outlined),
  ForgeNavigationDestination('异步并发', Icons.bolt_outlined),
];

void main() {
  testWidgets('bubble travels continuously when a new target interrupts it', (
    tester,
  ) async {
    final selection = ValueNotifier(0);
    addTearDown(selection.dispose);
    await _pumpNavigation(tester, selection);
    final start = _pill(tester).center;

    await tester.tap(find.byKey(const ValueKey('destination:2')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    final traveling = _pill(tester);
    expect(traveling.active, isTrue);
    expect(traveling.center.dy, greaterThan(start.dy));
    expect(traveling.center.dy, lessThan(start.dy + 112));

    selection.value = 1;
    await tester.pump();
    expect(_pill(tester).center.dy, closeTo(traveling.center.dy, 0.01));
    await tester.pumpAndSettle();
    expect(_pill(tester).center.dy, closeTo(start.dy + 56, 0.1));
    expect(_pill(tester).active, isFalse);
    expect(tester.binding.transientCallbackCount, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('turning off animations stops an in-flight bubble', (
    tester,
  ) async {
    final selection = ValueNotifier(0);
    addTearDown(selection.dispose);
    await _pumpNavigation(tester, selection);
    selection.value = 2;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    expect(_pill(tester).active, isTrue);

    await _pumpNavigation(tester, selection, disableAnimations: true);
    await tester.pumpAndSettle();
    expect(find.byType(LiquidGlassMotionPill), findsNothing);
    expect(find.byKey(const ValueKey('navigation-bubble')), findsOneWidget);
    expect(tester.binding.transientCallbackCount, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keyboard navigation updates selection', (tester) async {
    final selection = ValueNotifier(0);
    addTearDown(selection.dispose);
    await _pumpNavigation(tester, selection);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(selection.value, 1);
    expect(_pill(tester).active, isFalse);
  });

  for (final width in [800.0, 1200.0]) {
    testWidgets('bubble follows clicks and external routes at ${width}dp', (
      tester,
    ) async {
      const platform = AppPlatformSnapshot(platform: AppTargetPlatform.android);
      final controller = AppThemeController.forTesting();
      final router = AppRouter.create(platform);
      addTearDown(router.dispose);
      addTearDown(controller.dispose);
      await tester.binding.setSurfaceSize(Size(width, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [appPlatformProvider.overrideWithValue(platform)],
          child: App(router: router, themeController: controller),
        ),
      );
      await tester.pumpAndSettle();
      final prefix = width < 1024 ? 'rail' : 'sidebar';
      await tester.tap(find.byKey(ValueKey('$prefix-destination:2')));
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/category/async');
      expect(
        tester
            .widget<ForgeBubbleNavigation>(find.byType(ForgeBubbleNavigation))
            .selectedIndex,
        2,
      );

      router.go('/category/ui');
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<ForgeBubbleNavigation>(find.byType(ForgeBubbleNavigation))
            .selectedIndex,
        4,
      );
      expect(_pill(tester).active, isFalse);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('compact drawer keeps its existing category routes', (
    tester,
  ) async {
    const platform = AppPlatformSnapshot(platform: AppTargetPlatform.android);
    final controller = AppThemeController.forTesting();
    final router = AppRouter.create(platform);
    addTearDown(router.dispose);
    addTearDown(controller.dispose);
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appPlatformProvider.overrideWithValue(platform)],
        child: App(router: router, themeController: controller),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    expect(find.byType(ForgeBubbleNavigation), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('category-drawer:ui')));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/category/ui');
    expect(find.byKey(const ValueKey('category-page:ui')), findsOneWidget);
    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('category-drawer:ui')));
    await tester.pumpAndSettle();
    expect(
      tester
          .state<ScaffoldState>(
            find.byKey(const ValueKey('adaptive-app-shell')),
          )
          .isDrawerOpen,
      isFalse,
    );
    expect(tester.takeException(), isNull);
  });
}

LiquidGlassMotionPill _pill(WidgetTester tester) =>
    tester.widget<LiquidGlassMotionPill>(find.byType(LiquidGlassMotionPill));

Future<void> _pumpNavigation(
  WidgetTester tester,
  ValueNotifier<int> selection, {
  bool disableAnimations = false,
}) => tester.pumpWidget(
  MaterialApp(
    theme: AppTheme.light(AppThemePalette.liquidGlass),
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: disableAnimations),
      child: Material(
        child: Center(
          child: SizedBox(
            width: 264,
            child: ValueListenableBuilder<int>(
              valueListenable: selection,
              builder: (context, value, child) => ForgeBubbleNavigation(
                destinations: _destinations,
                selectedIndex: value,
                onDestinationSelected: (index) => selection.value = index,
                destinationKey: (index) => ValueKey('destination:$index'),
              ),
            ),
          ),
        ),
      ),
    ),
  ),
);
