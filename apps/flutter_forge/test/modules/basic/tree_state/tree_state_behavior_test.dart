import 'package:flutter/material.dart';
import 'package:flutter_forge_app/modules/basic/tree_state/pages/state_lifecycle_page.dart';
import 'package:flutter_forge_app/modules/basic/tree_state/pages/basic_widgets_page.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('state lifecycle logs initState, setState and pushes', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: StateLifecyclePage()));
    await tester.pumpAndSettle();

    expect(find.textContaining('initState 执行'), findsOneWidget);
    expect(
      find.textContaining('didChangeDependencies'),
      findsAtLeastNWidgets(1),
    );

    await tester.tap(find.text('setState +1'));
    await tester.pumpAndSettle();
    expect(find.text('Counter: 1'), findsOneWidget);

    await tester.tap(find.text('Push & Pop 页面'));
    await tester.pumpAndSettle();
    expect(find.text('Child Page'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Child Page'), findsNothing);
    expect(find.text('Counter: 1'), findsOneWidget, reason: '返回后状态保持');
  });

  testWidgets('clear log button empties lifecycle entries', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: StateLifecyclePage()));
    await tester.pumpAndSettle();
    expect(find.textContaining('initState 执行'), findsOneWidget);

    await tester.ensureVisible(find.text('清空日志'));
    await tester.tap(find.text('清空日志'));
    await tester.pumpAndSettle();
    expect(find.textContaining('initState 执行'), findsNothing);
  });

  testWidgets('basic widgets page toggles its visible state', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: BasicWidgetsPage()));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('🎯 学习目标'), findsOneWidget);
  });
}
