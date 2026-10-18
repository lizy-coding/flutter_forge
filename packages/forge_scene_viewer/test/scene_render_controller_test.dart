import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:forge_scene_viewer/forge_scene_viewer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('ticker requests coalesce and never count as render invocations', () {
    final camera = SceneCameraController();
    final controller = SceneRenderController(camera: camera)
      ..markReady()
      ..attachDriver();
    controller.onTick(Duration.zero);
    controller.onTick(const Duration(milliseconds: 16));
    controller.onTick(const Duration(milliseconds: 32));
    expect(controller.metrics.renderCalls, 0);
    expect(controller.metrics.requests, greaterThan(1));
    expect(controller.metrics.coalesced, greaterThan(0));
    controller.measureRender(() {}, specification: const {});
    expect(controller.metrics.renderCalls, 1);
    expect(controller.metrics.returned, 1);
    controller.dispose();
    camera.dispose();
  });

  test(
    'manual mode freezes motion, single redraw preserves pose, resume resets clock',
    () {
      final camera = SceneCameraController();
      final controller = SceneRenderController(camera: camera)
        ..markReady()
        ..attachDriver();
      controller.onTick(Duration.zero);
      controller.onTick(const Duration(milliseconds: 100));
      final yaw = camera.yaw;
      controller.setMode(SceneRenderMode.manual);
      controller.onTick(const Duration(seconds: 30));
      controller.redrawOnce();
      controller.measureRender(() {}, specification: const {});
      expect(camera.yaw, yaw);
      expect(controller.canManipulate, isFalse);
      controller.setMode(SceneRenderMode.onDemand);
      expect(
        controller.ticking.value,
        isFalse,
        reason: 'Returning to demand mode does not override user pause.',
      );
      camera.togglePaused();
      controller.onTick(const Duration(seconds: 30));
      expect(camera.yaw, yaw);
      controller.onTick(const Duration(milliseconds: 30016));
      expect(camera.yaw - yaw, closeTo(.35 * .016, .00001));
      controller.dispose();
      camera.dispose();
    },
  );

  test(
    'capture is single-flight, restores state on errors and ignores late disposal result',
    () async {
      final camera = SceneCameraController()..pauseMotion();
      final controller = SceneRenderController(camera: camera)
        ..markReady()
        ..setMode(SceneRenderMode.manual);
      final pending = Completer<SceneCaptureSnapshot>();
      var starts = 0;
      controller.captureDelegate = () {
        starts++;
        return pending.future;
      };
      final capture = controller.captureFrame();
      await controller.captureFrame();
      expect(starts, 1);
      pending.completeError(TimeoutException('no frame'));
      await capture;
      expect(controller.capturing, isFalse);
      expect(controller.mode, SceneRenderMode.manual);
      expect(controller.metrics.lastError, contains('no frame'));
      final lateResult = Completer<SceneCaptureSnapshot>();
      controller.captureDelegate = () => lateResult.future;
      final lateCapture = controller.captureFrame();
      controller.dispose();
      lateResult.complete(
        SceneCaptureSnapshot(width: 1, height: 1, passes: const []),
      );
      await lateCapture;
      expect(controller.capture, isNull);
      camera.dispose();
    },
  );

  test(
    'snapshot keeps window scope explicit and render failures stop continuous ticking',
    () {
      final camera = SceneCameraController();
      final controller = SceneRenderController(camera: camera)
        ..markReady()
        ..attachDriver();
      controller.measureRender(
        () => throw StateError('GPU unavailable'),
        specification: const {'pixel_width': 200},
      );
      expect(controller.ticking.value, isFalse);
      expect(controller.metrics.failures, 1);
      final snapshot = jsonDecode(controller.diagnosticJson()) as Map;
      expect(snapshot['scope'], contains('GPU completion is not measured'));
      expect(snapshot['render_failed'], isTrue);
      expect(snapshot['driver_active'], isFalse);
      controller.dispose();
      camera.dispose();
    },
  );
}
