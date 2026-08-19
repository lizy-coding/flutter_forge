import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_forge_app/modules/ui/download_animation/pages/download_animation_page.dart';

void main() {
  testWidgets('DownloadAnimationPage renders teaching components', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: DownloadAnimationPage()));

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('下载飞入动画'), findsOneWidget);
    expect(find.text('🎯 学习目标'), findsOneWidget);
    expect(find.text('⚠️ 常见误区'), findsOneWidget);
    expect(find.text('下载'), findsWidgets);
  });
}
