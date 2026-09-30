import 'package:flutter/material.dart';
import 'package:flutter_forge_app/app/router/app_route_table.dart';
import 'package:flutter_forge_app/module_registry/app_platform_snapshot.dart';
import 'package:flutter_forge_app/modules/popup_table/popup_list_interaction/module_entry.dart';
import 'package:flutter_forge_app/modules/popup_table/popup_list_interaction/pages/popup_page.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('module entry is constructible', () {
    expect(const PopupListInteractionEntry(), isA<Widget>());
  });

  testWidgets('popup nested route opens from its module page', (tester) async {
    final router = GoRouter(
      initialLocation: '/popup-list-interaction',
      routes: AppRouteTable.routesFor(
        const AppPlatformSnapshot(platform: AppTargetPlatform.macOS),
      ),
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    final popupCard = find.widgetWithText(ListTile, '弹窗组件');
    expect(popupCard, findsOneWidget);
    await tester.ensureVisible(popupCard);
    await tester.tap(popupCard);
    await tester.pumpAndSettle();

    expect(find.byType(PopupPage), findsOneWidget);
  });

  testWidgets('list nested route opens from its module page', (tester) async {
    final router = GoRouter(
      initialLocation: '/popup-list-interaction',
      routes: AppRouteTable.routesFor(
        const AppPlatformSnapshot(platform: AppTargetPlatform.macOS),
      ),
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    final listCard = find.widgetWithText(ListTile, '列表交互');
    expect(listCard, findsOneWidget);
    await tester.ensureVisible(listCard);
    await tester.tap(listCard);
    await tester.pumpAndSettle();

    expect(find.text('二维滚动表格演示'), findsOneWidget);
  });

  testWidgets('cell edits commit only on save and cancel preserves the value', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/popup-list-interaction/list',
      routes: AppRouteTable.routesFor(
        const AppPlatformSnapshot(platform: AppTargetPlatform.macOS),
      ),
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    await tester.tap(find.text('学习任务 1'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('cell-edit-input')), '已修改任务');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(find.text('已修改任务'), findsOneWidget);
    await tester.tap(find.text('已修改任务'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('cell-edit-input')), '不应提交');
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(find.text('已修改任务'), findsOneWidget);
    expect(find.text('不应提交'), findsNothing);
  });

  testWidgets('leaving the list with its editor open removes the popup', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/popup-list-interaction/list',
      routes: AppRouteTable.routesFor(
        const AppPlatformSnapshot(platform: AppTargetPlatform.macOS),
      ),
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    await tester.tap(find.text('学习任务 1'));
    await tester.pumpAndSettle();
    router.go('/');
    await tester.pumpAndSettle();
    expect(find.text('编辑单元格'), findsNothing);
    expect(find.text('Lizy'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('popup actions return a result and can be cancelled', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: PopupPage()));
    await tester.tap(find.text('对话框选择动作'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('收藏'));
    await tester.pumpAndSettle();
    expect(find.text('已选择：收藏'), findsOneWidget);
    await tester.tap(find.text('底部弹窗选择动作'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(find.text('已取消，保留原状态'), findsOneWidget);
    expect(find.text('已选择：收藏'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
