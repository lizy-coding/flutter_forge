import 'package:flutter/material.dart';
import 'package:flutter_forge_app/app/router/app_route_table.dart';
import 'package:flutter_forge_app/modules/popup_table/popup_list_interaction/module_entry.dart';
import 'package:flutter_forge_app/modules/popup_table/popup_widgets/module_root.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('module entry is constructible', () {
    expect(const PopupListInteractionEntry(), isA<Widget>());
  });

  testWidgets('popup nested route opens from its module page', (tester) async {
    final router = GoRouter(
      initialLocation: '/popup-list-interaction',
      routes: AppRouteTable.routes,
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    final popupCard = find.widgetWithText(ListTile, '弹窗组件');
    expect(popupCard, findsOneWidget);
    await tester.ensureVisible(popupCard);
    await tester.tap(popupCard);
    await tester.pumpAndSettle();

    expect(find.byType(PopDemoHomePage), findsOneWidget);
    router.dispose();
  });

  testWidgets('list nested route opens from its module page', (tester) async {
    final router = GoRouter(
      initialLocation: '/popup-list-interaction',
      routes: AppRouteTable.routes,
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    final listCard = find.widgetWithText(ListTile, '列表交互');
    expect(listCard, findsOneWidget);
    await tester.ensureVisible(listCard);
    await tester.tap(listCard);
    await tester.pumpAndSettle();

    expect(find.text('二维滚动表格演示'), findsOneWidget);
    router.dispose();
  });
}
