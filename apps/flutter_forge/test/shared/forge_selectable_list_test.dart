import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_forge_app/app/forge_nav_tile.dart';
import 'package:flutter_forge_app/app/forge_selectable_list.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final activated = <int>[];
  Widget list(int selectedIndex, List<int> activated) => MaterialApp(
    home: Scaffold(
      body: ForgeSelectableList(
        itemCount: 5,
        selectedIndex: selectedIndex,
        onActivate: activated.add,
        itemBuilder: (context, index, keyboardActive) => ForgeNavTile(
          label: '模块 $index',
          keyboardActive: keyboardActive,
          onTap: () => activated.add(index),
        ),
      ),
    ),
  );

  tearDown(activated.clear);

  testWidgets('pointer interaction arms keyboard navigation', (tester) async {
    await tester.binding.setSurfaceSize(const Size(300, 400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(list(1, activated));

    await tester.tap(find.text('模块 0'));
    await tester.pump();
    expect(activated, [0]);
    // The ring only appears once arrow navigation actually starts.
    expect(
      tester
          .widgetList<ForgeNavTile>(find.byType(ForgeNavTile))
          .any((tile) => tile.keyboardActive),
      isFalse,
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(
      tester
          .widget<ForgeNavTile>(find.byType(ForgeNavTile).at(2))
          .keyboardActive,
      isTrue,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(activated, [0, 2]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('home and end jump the cursor and re-sync on selection change', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(300, 400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(list(1, activated));

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.end);
    await tester.pump();
    expect(
      tester
          .widget<ForgeNavTile>(find.byType(ForgeNavTile).at(4))
          .keyboardActive,
      isTrue,
    );

    // A route-driven selection change re-anchors the cursor.
    await tester.pumpWidget(list(2, activated));
    await tester.pump();
    expect(
      tester
          .widgetList<ForgeNavTile>(find.byType(ForgeNavTile))
          .any((tile) => tile.keyboardActive),
      isFalse,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(
      tester
          .widget<ForgeNavTile>(find.byType(ForgeNavTile).at(3))
          .keyboardActive,
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });
}
