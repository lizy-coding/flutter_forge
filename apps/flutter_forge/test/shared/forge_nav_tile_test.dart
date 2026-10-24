import 'package:flutter/material.dart';
import 'package:flutter_forge_app/app/forge_nav_tile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('selected tile taps and exposes the full-label tooltip', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(220, 120));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final semantics = tester.ensureSemantics();
    try {
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ForgeNavTile(
              label: '图形绘制背景：认识 GPU、纹理与 Shader',
              icon: Icons.dashboard_outlined,
              selected: true,
              onTap: () => taps++,
            ),
          ),
        ),
      );

      final selected = find
          .ancestor(
            of: find.text('图形绘制背景：认识 GPU、纹理与 Shader'),
            matching: find.byType(Semantics),
          )
          .evaluate()
          .any(
            (element) =>
                (element.widget as Semantics).properties.selected == true,
          );
      expect(selected, isTrue);
      expect(find.byTooltip('图形绘制背景：认识 GPU、纹理与 Shader'), findsOneWidget);
      await tester.tap(find.text('图形绘制背景：认识 GPU、纹理与 Shader'));
      expect(taps, 1);
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('keyboard cursor renders a ring independent of selection', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(300, 200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ForgeNavTile(
            label: '三棵树与生命周期',
            selected: false,
            keyboardActive: true,
          ),
        ),
      ),
    );

    final tile = tester.widget<ForgeNavTile>(find.byType(ForgeNavTile));
    expect(tile.keyboardActive, isTrue);
    expect(tile.selected, isFalse);
    expect(tester.takeException(), isNull);
  });
}
