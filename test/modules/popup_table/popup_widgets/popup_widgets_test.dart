import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:main_app/modules/popup_table/popup_widgets/module_entry.dart';
import 'package:main_app/modules/popup_table/popup_widgets/module_root.dart';

void main() {
  testWidgets('PopWidgetEntry renders module page', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: PopWidgetEntry()));

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Flutter 弹窗学习'), findsOneWidget);
    expect(find.text('AlertDialog (普通对话框)'), findsOneWidget);
  });

  testWidgets('PopDemoHomePage renders teaching components', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: PopDemoHomePage(title: 'Flutter 弹窗学习')),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Flutter 弹窗学习'), findsOneWidget);
    expect(find.text('AlertDialog (普通对话框)'), findsOneWidget);
    expect(find.text('SimpleDialog (选项对话框)'), findsOneWidget);
    expect(find.text('Modal Bottom Sheet (模态底部弹窗)'), findsOneWidget);
    expect(find.text('自定义 Dialog'), findsOneWidget);
    expect(find.text('🎯 学习目标'), findsOneWidget);
  });

  testWidgets('PopDemoHomePage FAB toggles bottom bar', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: PopDemoHomePage(title: 'Flutter 弹窗学习')),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final fab = find.byType(FloatingActionButton);
    expect(fab, findsOneWidget);

    await tester.tap(fab);
    await tester.pump();

    expect(find.text('这是一个持久化底部工具条，你可以手动关闭。'), findsOneWidget);
  });

  testWidgets('PopDemoHomePage toolbar shows date/time picker menu', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: PopDemoHomePage(title: 'Flutter 弹窗学习')),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('日期/时间'), findsOneWidget);
  });
}
