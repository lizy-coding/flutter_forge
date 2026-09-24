import 'package:flutter/material.dart';
import 'package:flutter_forge_app/app/app.dart';
import 'package:flutter_forge_app/app/app_platform_provider.dart';
import 'package:flutter_forge_app/app/module_home_page.dart';
import 'package:flutter_forge_app/app/router/app_route_table.dart';
import 'package:flutter_forge_app/app/router/app_router.dart';
import 'package:flutter_forge_app/module_registry/module_catalog_utils.dart';
import 'package:flutter_forge_app/module_registry/app_platform_snapshot.dart';
import 'package:flutter_forge_app/modules/popup_table/popup_widgets/module_root.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  late AppPlatformSnapshot platform;
  late GoRouter router;

  setUp(() {
    platform = AppPlatformSnapshot.detect();
    router = AppRouter.create(platform)..go('/');
  });

  tearDown(() => router.dispose());

  Widget testApp() => ProviderScope(
    overrides: [appPlatformProvider.overrideWithValue(platform)],
    child: App(router: router),
  );

  testWidgets('available modules open and return', (tester) async {
    await tester.pumpWidget(testApp());
    await tester.pumpAndSettle();

    expect(find.text('Flutter 学习实验室'), findsOneWidget);

    final modules = AppRouteTable.modules
        .where((module) => isModuleAvailable(module, platform))
        .toList();

    for (final module in modules) {
      final tile = find.byKey(ValueKey('module:${module.path}'));
      await tester.scrollUntilVisible(
        tile,
        500,
        scrollable: find.byType(Scrollable).first,
      );
      debugPrint('Android module smoke: ${module.path}');
      await tester.tap(tile);
      await tester.pump(const Duration(milliseconds: 600));

      final moduleException = tester.takeException();
      if (moduleException != null) {
        fail('${module.path} raised during Android smoke: $moduleException');
      }

      expect(find.byType(Scaffold), findsOneWidget, reason: module.path);
      await tester.pageBack();
      await tester.pumpAndSettle();
    }
  });

  testWidgets('popup and list child routes open from the module page', (
    tester,
  ) async {
    await tester.pumpWidget(testApp());
    await tester.pumpAndSettle();

    router.go('/popup-list-interaction');
    await tester.pumpAndSettle();

    final popupTile = find.widgetWithText(ListTile, '弹窗组件');
    await tester.tap(popupTile);
    await tester.pumpAndSettle();
    expect(find.byType(PopDemoHomePage), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 300));
    router.go('/popup-list-interaction');
    await tester.pumpAndSettle();
    router.go('/popup-list-interaction/list');
    await tester.pumpAndSettle();
    expect(find.text('二维滚动表格演示'), findsOneWidget);
  });

  testWidgets('mobile category drawer opens a top-level category', (
    tester,
  ) async {
    if (platform.hostFamily != AppHostFamily.mobile) {
      return;
    }

    await tester.pumpWidget(testApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    expect(find.text('创作者主页'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('category-drawer:platform')));
    await tester.pumpAndSettle();

    expect(find.byType(CategoryHomePage), findsOneWidget);
    expect(find.text('网络与平台'), findsOneWidget);
  });
}
