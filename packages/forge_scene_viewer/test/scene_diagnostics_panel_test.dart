import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forge_scene_viewer/forge_scene_viewer.dart';

void main() {
  testWidgets('initialization errors publish before a scene view can mount', (
    tester,
  ) async {
    final camera = SceneCameraController();
    final controller = SceneRenderController(camera: camera);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SceneDiagnosticsPanel(controller: controller),
          ),
        ),
      ),
    );
    controller.reportError(StateError('shader initialization failed'));
    await tester.pump();
    await tester.tap(find.text('绘制诊断'));
    await tester.pumpAndSettle();
    expect(find.textContaining('shader initialization failed'), findsOneWidget);
    expect(controller.metrics.renderCalls, 0);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
    camera.dispose();
  });

  testWidgets(
    'capture UI reports passes, recovers after failure and copies scoped snapshot',
    (tester) async {
      final camera = SceneCameraController()..pauseMotion();
      final controller = SceneRenderController(camera: camera)
        ..markReady()
        ..setMode(SceneRenderMode.manual);
      var attempts = 0;
      controller.captureDelegate = () async {
        attempts++;
        if (attempts == 1) throw TimeoutException('no visible view');
        return SceneCaptureSnapshot(
          width: 480,
          height: 200,
          passes: const [ScenePassTiming('ScenePass', 230)],
        );
      };
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String;
          }
          return null;
        },
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SceneDiagnosticsPanel(controller: controller),
            ),
          ),
        ),
      );
      await tester.tap(find.text('绘制诊断'));
      await tester.pumpAndSettle();
      final capture = find.byKey(const Key('render-capture'));
      await tester.ensureVisible(capture);
      await tester.tap(capture);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('render-error')), findsOneWidget);
      expect(controller.capturing, isFalse);
      await tester.ensureVisible(capture);
      await tester.tap(capture);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('render-capture-result')), findsOneWidget);
      expect(find.textContaining('ScenePass · CPU 0.23 ms'), findsOneWidget);
      final copy = find.byKey(const Key('render-copy'));
      await tester.ensureVisible(copy);
      await tester.tap(copy);
      await tester.pumpAndSettle();
      final snapshot = jsonDecode(copied!) as Map;
      expect(snapshot['render_mode'], 'manual');
      expect((snapshot['metrics'] as Map)['gpu_duration_us'], isNull);
      expect(controller.metrics.renderCalls, 0);
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
      camera.dispose();
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
    },
  );

  testWidgets('read-only diagnostics exposes no scene or sampling actions', (
    tester,
  ) async {
    final camera = SceneCameraController();
    final controller = SceneRenderController(camera: camera)..markReady();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SceneDiagnosticsPanel(
              controller: controller,
              readOnly: true,
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('绘制诊断'));
    await tester.pumpAndSettle();
    for (final key in [
      'render-once',
      'render-capture',
      'render-sampling',
      'render-clear',
      'render-copy',
    ]) {
      expect(find.byKey(Key(key)), findsNothing);
    }
    expect(controller.mode, SceneRenderMode.onDemand);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
    camera.dispose();
  });

  test(
    'runtime validates scene ownership before allocating GPU resources',
    () async {
      const part = ScenePartDefinition(
        id: 'duplicate',
        label: '部件',
        shape: ScenePartShape.cuboid,
      );
      final runtime = FlutterSceneViewerRuntime(parts: const [part, part]);
      await expectLater(runtime.initialize(), throwsArgumentError);
      expect(runtime.rendering.metrics.renderCalls, 0);
      expect(runtime.rendering.metrics.lastError, contains('unique'));
      runtime.dispose();
      runtime.dispose();
      await expectLater(runtime.initialize(), throwsStateError);
    },
  );
}
