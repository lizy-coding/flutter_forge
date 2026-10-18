import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forge_scene_viewer/forge_scene_viewer.dart';
import 'package:flutter_forge_app/modules/ui/flutter_scene_3d/module_root.dart';
import 'package:flutter_forge_app/modules/ui/flutter_scene_3d/scene_runtime.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('real desktop scene drawing diagnostics and controlled redraw', (
    tester,
  ) async {
    expect({
      TargetPlatform.macOS,
      TargetPlatform.windows,
    }, contains(defaultTargetPlatform));
    final runtime = createDeviceSceneRuntime();
    final drawing = runtime.rendering;
    await tester.pumpWidget(
      MaterialApp(home: FlutterScene3dPage(runtime: runtime)),
    );
    await runtime.initialize();
    await frames(tester, const Duration(seconds: 1));
    expect(find.byKey(const Key('scene-error')), findsNothing);
    expect(drawing.metrics.renderCalls, greaterThan(0));
    expect(drawing.metrics.failures, 0);

    runtime.camera.pauseMotion();
    await frames(tester, const Duration(milliseconds: 200));
    final idleCalls = drawing.metrics.renderCalls;
    await frames(tester, const Duration(seconds: 5));
    expect(
      drawing.metrics.renderCalls,
      idleCalls,
      reason: 'A stable scene must not keep encoding frames.',
    );
    expect(drawing.callRate, 0);

    drawing.setMode(SceneRenderMode.manual);
    drawing.startSampling();
    await frames(tester, const Duration(milliseconds: 200));
    final beforeStep = drawing.metrics.renderCalls;
    final yaw = runtime.camera.yaw;
    drawing.redrawOnce();
    await frames(tester, const Duration(milliseconds: 200));
    expect(drawing.metrics.renderCalls, beforeStep + 1);
    expect(runtime.camera.yaw, yaw);
    expect(drawing.metrics.sceneCpu.count, 1);

    final captured = drawing.captureFrame();
    await frames(tester, const Duration(milliseconds: 500));
    await captured;
    expect(drawing.capture, isNotNull);
    expect(drawing.capture!.passes, isNotEmpty);
    expect(drawing.capture!.width, greaterThan(0));
    expect(drawing.mode, SceneRenderMode.manual);
    expect(
      drawing.metrics.sceneCpu.count,
      1,
      reason: 'Capture work is excluded from normal CPU statistics.',
    );

    drawing.setMode(SceneRenderMode.continuous);
    final beforeContinuous = drawing.metrics.renderCalls;
    await frames(tester, const Duration(milliseconds: 400));
    expect(drawing.metrics.renderCalls, greaterThan(beforeContinuous + 2));
    expect(runtime.camera.yaw, yaw);
    drawing.setMode(SceneRenderMode.manual);
    await frames(tester, const Duration(milliseconds: 200));

    await tester.ensureVisible(find.byKey(const Key('scene-diagnostics')));
    await tester.tap(find.text('绘制诊断'));
    await frames(tester, const Duration(milliseconds: 400));
    expect(find.byKey(const Key('render-capture-result')), findsOneWidget);
    expect(find.byKey(const Key('render-mode-manual')), findsOneWidget);
    final beforePanel = drawing.metrics.renderCalls;
    await frames(tester, const Duration(seconds: 2));
    expect(drawing.metrics.renderCalls, beforePanel);

    drawing.stopSampling();
    final frozenSamples = drawing.metrics.sceneCpu.count;
    drawing.redrawOnce();
    await frames(tester, const Duration(milliseconds: 200));
    expect(drawing.metrics.sceneCpu.count, frozenSamples);
    expect(drawing.metrics.failures, 0);
    final snapshot =
        jsonDecode(drawing.diagnosticJson()) as Map<String, dynamic>;
    binding.reportData = snapshot;
    debugPrint('SCENE_DIAGNOSTICS ${jsonEncode(snapshot)}');

    await tester.pumpWidget(const SizedBox());
    runtime.dispose();
    expect(drawing.isDisposed, isTrue);
  });
}

Future<void> frames(WidgetTester tester, Duration duration) async {
  final clock = Stopwatch()..start();
  while (clock.elapsed < duration) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}
