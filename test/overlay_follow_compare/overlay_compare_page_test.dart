import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:main_app/modules/popup_table/overlay_follow_compare/module_root.dart';

void main() {
  testWidgets('OverlayComparePage renders teaching components', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: OverlayComparePage(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Overlay 跟随方案对照组'), findsOneWidget);
    expect(find.text('🎯 学习目标'), findsOneWidget);
    expect(find.text('⚠️ 常见误区'), findsOneWidget);
    expect(find.text('Follower 自动跟随'), findsOneWidget);
    expect(find.text('onScroll 手动刷新'), findsOneWidget);
  });
}
