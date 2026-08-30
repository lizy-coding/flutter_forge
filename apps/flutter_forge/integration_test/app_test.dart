import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_forge_app/app/app.dart';
import 'package:flutter_forge_app/app/router/app_route_table.dart';
import 'package:flutter_forge_app/app/router/app_router.dart';
import 'package:flutter_forge_app/module_registry/module_catalog_utils.dart';
import 'package:flutter_forge_app/modules/popup_table/popup_widgets/module_root.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    AppRouter.router.go('/');
  });

  testWidgets('available modules open and return', (tester) async {
    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();

    expect(find.text('Flutter 学习实验室'), findsOneWidget);

    final platform = defaultTargetPlatform;
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
      await tester.tap(tile);
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byType(Scaffold), findsOneWidget, reason: module.path);
      await tester.pageBack();
      await tester.pumpAndSettle();
    }
  });

  testWidgets('popup and list child routes open from the module page', (
    tester,
  ) async {
    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();

    AppRouter.router.go('/popup-list-interaction');
    await tester.pumpAndSettle();

    final popupTile = find.widgetWithText(ListTile, '弹窗组件');
    await tester.tap(popupTile);
    await tester.pumpAndSettle();
    expect(find.byType(PopDemoHomePage), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    final listTile = find.widgetWithText(ListTile, '列表交互');
    await tester.tap(listTile);
    await tester.pumpAndSettle();
    expect(find.text('二维滚动表格演示'), findsOneWidget);
  });
}
