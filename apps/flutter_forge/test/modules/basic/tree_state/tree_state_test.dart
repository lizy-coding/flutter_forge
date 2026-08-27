import 'package:flutter/material.dart';
import 'package:flutter_forge_app/modules/basic/tree_state/module_entry.dart';
import 'package:flutter_forge_app/modules/basic/tree_state/pages/demo_home_page.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('module entry is constructible', () {
    expect(const TreeStateEntry(), isA<Widget>());
  });

  testWidgets('demo home keeps its scrollable entry list within bounds', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: DemoHomePage()));
    await tester.pump();

    expect(
      find.text('观察 Widget / Element / RenderObject 的关系以及生命周期日志'),
      findsOneWidget,
    );
    expect(find.byType(ListView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
