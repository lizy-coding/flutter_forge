import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_forge_app/modules/ui/gcode_visualizer/pages/gcode_visualizer_page.dart';

void main() {
  // The parse pipeline is an async* stream: drive it with real async like
  // the integration host does, then settle the resulting frames. The
  // previous single-pump coverage never saw the parsed timeline, inspector
  // and playback row that the overflow regression lives in.
  testWidgets('parsed gcode page does not overflow at 800x600', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: GcodeVisualizerPage()));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.textContaining('指令列表'), findsOneWidget);
  });

  testWidgets('parsed gcode page does not overflow at 360 width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: GcodeVisualizerPage()));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.textContaining('指令列表'), findsOneWidget);
  });

  // The desktop shell can hand the demo far less than the window width;
  // a mid-size content area must fall back to the stacked layout instead
  // of squeezing the playback panel below its control row minimum.
  testWidgets('mid-size content width stacks canvas and panel', (tester) async {
    tester.view.physicalSize = const Size(520, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: GcodeVisualizerPage()));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final canvas = tester.getTopLeft(find.byType(CustomPaint).first);
    final editor = tester.getTopLeft(find.text('G-code 编辑器'));
    expect(editor.dy, greaterThan(canvas.dy));
  });
}
