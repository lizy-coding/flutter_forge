import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_study_app/modules/ui/gcode_visualizer/pages/gcode_visualizer_page.dart';

void main() {
  testWidgets('GcodeVisualizerPage renders key elements', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: GcodeVisualizerPage()));

    await tester.pump();

    expect(find.text('G-code 解析与轨迹动画'), findsOneWidget);
    expect(find.text('G-code 编辑器'), findsOneWidget);
    expect(find.text('🎯 学习目标'), findsOneWidget);

    expect(find.byIcon(Icons.play_arrow), findsWidgets);
    expect(find.byIcon(Icons.refresh), findsOneWidget);
  });
}
