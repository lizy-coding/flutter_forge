import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_forge_app/app/app.dart';
import 'package:flutter_forge_app/app/app_platform_provider.dart';
import 'package:flutter_forge_app/app/category_window_app.dart';
import 'package:flutter_forge_app/app/mac_desktop_host.dart';
import 'package:flutter_forge_app/app/router/app_router.dart';
import 'package:flutter_forge_app/app/theme/app_theme.dart';
import 'package:flutter_forge_app/app/theme/app_theme_controller.dart';
import 'package:flutter_forge_app/app/theme/app_theme_selection.dart';
import 'package:flutter_forge_app/app/theme/forge_theme_tokens.dart';
import 'package:flutter_forge_app/module_registry/app_platform_snapshot.dart';
import 'package:flutter_forge_app/module_registry/module_category.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';

const _platform = AppPlatformSnapshot(platform: AppTargetPlatform.macOS);

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

  testWidgets('native commands reuse search, sidebar and existing routes', (
    tester,
  ) async {
    final calls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      MacDesktopHost.channel,
      (call) async {
        calls.add(call);
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        MacDesktopHost.channel,
        null,
      ),
    );
    final controller = AppThemeController.forTesting();
    final router = AppRouter.create(_platform);
    addTearDown(controller.dispose);
    addTearDown(router.dispose);
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appPlatformProvider.overrideWithValue(_platform)],
        child: App(router: router, themeController: controller),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(LiquidGlassLens), findsNothing);
    expect(find.byType(LiquidGlassMotionPill), findsNothing);
    expect(find.byKey(const ValueKey('expanded-sidebar')), findsOneWidget);

    await _command(tester, 'toggleSidebar');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('expanded-sidebar')), findsNothing);
    expect(find.byKey(const ValueKey('navigation-rail')), findsOneWidget);

    final search = _command(tester, 'search');
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '三棵树');
    await tester.pumpAndSettle();
    expect(find.text('三棵树与生命周期'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    await search;

    router.go('/category/basic');
    await tester.pumpAndSettle();
    await _command(tester, 'home');
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/');
    await controller.setMode(AppThemeModePreference.dark);
    await tester.pumpAndSettle();
    expect(
      calls.any(
        (call) => call.method == 'setAppearance' && call.arguments == 'dark',
      ),
      isTrue,
    );
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

  testWidgets('category window uses the same host without another sidebar', (
    tester,
  ) async {
    final calls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      MacDesktopHost.channel,
      (call) async {
        calls.add(call);
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        MacDesktopHost.channel,
        null,
      ),
    );
    final controller = AppThemeController.forTesting();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      CategoryWindowApp(
        category: ModuleCategory.basic,
        platform: _platform,
        themeController: controller,
      ),
    );
    await tester.pumpAndSettle();
    expect(
      calls.any(
        (call) =>
            call.method == 'setSidebarAvailable' && call.arguments == false,
      ),
      isTrue,
    );
    final search = _command(tester, 'search');
    await tester.pumpAndSettle();
    expect(find.text('搜索模块标题'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    await search;
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));
}

Future<ByteData?> _command(WidgetTester tester, String command) =>
    tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      MacDesktopHost.channel.name,
      const StandardMethodCodec().encodeMethodCall(MethodCall(command)),
      (_) {},
    );
