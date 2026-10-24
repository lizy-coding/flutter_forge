import 'package:flutter/material.dart';
import 'package:flutter_forge_app/modules/popup_table/overlay_follow_compare/module_root.dart';
import 'package:flutter_forge_app/modules/popup_table/overlay_follow_compare/widgets/follower_demo.dart';
import 'package:flutter_forge_app/modules/popup_table/overlay_follow_compare/widgets/manual_demo.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // The module page embeds both demos inside a fixed-height demo box; the
  // per-demo cases below host each demo full-screen so the scroll gestures
  // have room to move the overlays.
  testWidgets('follower overlay follows scrolling without rebuilding', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(500, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: FollowerDemo())),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Follower 下拉菜单'), 200);
    await tester.tap(find.text('Follower 下拉菜单'));
    await tester.pumpAndSettle();
    expect(find.text('Follower'), findsOneWidget);
    expect(find.text('rebuild: 1'), findsOneWidget);

    await tester.drag(find.text('Item 20'), const Offset(0, -120));
    await tester.pumpAndSettle();
    // Layer-link sync moves the overlay without a new overlay build.
    expect(find.text('rebuild: 1'), findsOneWidget);
  });

  testWidgets('manual overlay rebuilds on every scroll tick', (tester) async {
    tester.view.physicalSize = const Size(500, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ManualRebuildDemo())),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('手动刷新下拉菜单'), 200);
    await tester.tap(find.text('手动刷新下拉菜单'));
    await tester.pumpAndSettle();
    expect(find.text('Manual'), findsOneWidget);
    expect(find.text('rebuild: 1'), findsOneWidget);

    await tester.drag(find.text('Item 20'), const Offset(0, -120));
    await tester.pumpAndSettle();
    expect(
      find.text('rebuild: 2'),
      findsOneWidget,
      reason: '滚动必须触发 markNeedsBuild 重建',
    );
  });

  testWidgets('tapping outside closes the follower overlay cleanly', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(500, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: FollowerDemo())),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Follower 下拉菜单'), 200);
    await tester.tap(find.text('Follower 下拉菜单'));
    await tester.pumpAndSettle();
    expect(find.text('Follower'), findsOneWidget);

    // While open, the translucent full-area dismiss layer sits above the
    // list, so a second tap anywhere — including the button — toggles closed.
    await tester.tap(find.text('Follower 下拉菜单'));
    await tester.pumpAndSettle();
    expect(find.text('Follower'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('narrow viewport stacks the two comparison panels', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: OverlayComparePage()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final follower = tester.getTopLeft(find.text('Follower 自动跟随'));
    final manual = tester.getTopLeft(find.text('onScroll 手动刷新'));
    expect(manual.dy, greaterThan(follower.dy), reason: '窄屏应上下堆叠');
  });

  testWidgets('wide viewport places the panels side by side', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: OverlayComparePage()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final follower = tester.getTopLeft(find.text('Follower 自动跟随'));
    final manual = tester.getTopLeft(find.text('onScroll 手动刷新'));
    expect(manual.dx, greaterThan(follower.dx), reason: '宽屏应左右并列');
  });
}
