import 'package:flutter/material.dart';
import 'package:flutter_forge_app/modules/popup_table/popup_widgets/module_root.dart';
import 'package:flutter_forge_app/modules/popup_table/popup_widgets/widgets/demo_section.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pumpHome(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(1200, 1000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    const MaterialApp(home: PopDemoHomePage(title: 'Flutter 弹窗学习')),
  );
  await tester.pumpAndSettle();
}

Future<void> _scrollTo(WidgetTester tester, Finder target) async {
  final scrollable = find
      .descendant(
        of: find.byType(PopupDemoInteractiveDemo),
        matching: find.byType(Scrollable),
      )
      .first;
  await tester.scrollUntilVisible(target, 300, scrollable: scrollable);
  await Scrollable.ensureVisible(tester.element(target), alignment: 0.5);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('alert dialog opens from the tile and closes on cancel', (
    tester,
  ) async {
    await _pumpHome(tester);
    final tile = find.text('AlertDialog (普通对话框)');
    await _scrollTo(tester, tile);
    await tester.tap(tile);
    await tester.pumpAndSettle();
    expect(find.text('提示'), findsOneWidget);
    expect(find.text('这是一个 AlertDialog 示例。'), findsOneWidget);

    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(find.text('提示'), findsNothing);
  });

  testWidgets('simple dialog opens from the trailing icon and picks B', (
    tester,
  ) async {
    await _pumpHome(tester);
    final tile = find.text('SimpleDialog (选项对话框)');
    await _scrollTo(tester, tile);
    await tester.tap(find.byIcon(Icons.open_in_new));
    await tester.pumpAndSettle();
    expect(find.text('选择一个选项'), findsOneWidget);

    await tester.tap(find.text('选项 B'));
    await tester.pumpAndSettle();
    expect(find.text('选择一个选项'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('modal bottom sheet opens on long press and pops', (
    tester,
  ) async {
    await _pumpHome(tester);
    final tile = find.text('Modal Bottom Sheet (模态底部弹窗)');
    await _scrollTo(tester, tile);
    await tester.longPress(tile);
    await tester.pumpAndSettle();
    expect(find.text('这是一个模态底部弹窗'), findsOneWidget);

    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();
    expect(find.text('这是一个模态底部弹窗'), findsNothing);
  });

  testWidgets('custom dialog ignores outside taps and closes on submit', (
    tester,
  ) async {
    await _pumpHome(tester);
    final button = find.widgetWithText(ElevatedButton, '打开');
    await _scrollTo(tester, button);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(find.text('自定义内容'), findsOneWidget);

    // barrierDismissible is false for the custom dialog.
    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();
    expect(find.text('自定义内容'), findsOneWidget);

    await tester.tap(find.text('提交'));
    await tester.pumpAndSettle();
    expect(find.text('自定义内容'), findsNothing);
  });
}
