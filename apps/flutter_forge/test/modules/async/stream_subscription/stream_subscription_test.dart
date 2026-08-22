import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_forge_app/modules/async/stream_subscription/pages/stream_demo_page.dart';

void main() {
  testWidgets('StreamDemoPage renders teaching components', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: StreamDemoPage()));

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Stream 单订阅示例'), findsOneWidget);
    expect(find.text('🎯 学习目标'), findsOneWidget);
    expect(find.text('⚠️ 常见误区'), findsOneWidget);
    expect(find.text('开始推送'), findsOneWidget);
    expect(find.text('订阅'), findsOneWidget);
  });
}
