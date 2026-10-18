import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forge_scene_viewer/forge_scene_viewer.dart';

Widget harness(SceneRenderController controller, {bool active = true}) =>
    MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            TickerMode(
              enabled: active,
              child: SizedBox(
                width: 240,
                height: 100,
                child: SceneRenderSurface(
                  controller: controller,
                  render: (canvas, size, dpr) {
                    controller.measureRender(
                      () => canvas.drawRect(
                        Offset.zero & size,
                        Paint()..color = Colors.blue,
                      ),
                      specification: {
                        'logical_width': size.width,
                        'pixel_width': (size.width * dpr).ceil(),
                      },
                    );
                  },
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: SceneDiagnosticsPanel(controller: controller),
              ),
            ),
          ],
        ),
      ),
    );

Future<void> press(WidgetTester tester, String key) async {
  final finder = find.byKey(Key(key));
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pump();
}

void main() {
  testWidgets(
    'idle diagnostics, sampling and clear never repaint scene; single frame draws once',
    (tester) async {
      final camera = SceneCameraController()..pauseMotion();
      final controller = SceneRenderController(
        camera: camera,
        now: () => tester.binding.clock.now().difference(DateTime(2026)),
      )..markReady();
      await tester.pumpWidget(harness(controller));
      final initial = controller.metrics.renderCalls;
      expect(initial, 1);
      await tester.pump(const Duration(seconds: 5));
      expect(controller.metrics.renderCalls, initial);
      await tester.tap(find.text('绘制诊断'));
      await tester.pumpAndSettle();
      await press(tester, 'render-sampling');
      await tester.pump(const Duration(seconds: 2));
      expect(controller.metrics.renderCalls, initial);
      expect(controller.metrics.sceneCpu.count, 0);
      await press(tester, 'render-mode-manual');
      await tester.pumpAndSettle();
      final before = controller.metrics.renderCalls;
      await press(tester, 'render-once');
      await tester.pump();
      expect(controller.metrics.renderCalls, before + 1);
      expect(controller.metrics.sceneCpu.count, 1);
      final pose = camera.yaw;
      await press(tester, 'render-sampling');
      final samples = controller.metrics.sceneCpu.count;
      await press(tester, 'render-once');
      expect(controller.metrics.sceneCpu.count, samples);
      expect(camera.yaw, pose);
      await press(tester, 'render-clear');
      await tester.pump(const Duration(seconds: 2));
      expect(controller.metrics.renderCalls, 0);
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
      camera.dispose();
    },
  );

  testWidgets(
    'continuous rendering leaves paused camera fixed, manual mode stops it',
    (tester) async {
      final camera = SceneCameraController()..pauseMotion();
      final controller = SceneRenderController(
        camera: camera,
        now: () => tester.binding.clock.now().difference(DateTime(2026)),
      )..markReady();
      await tester.pumpWidget(harness(controller));
      controller.setMode(SceneRenderMode.continuous);
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(controller.metrics.renderCalls, greaterThan(3));
      expect(camera.yaw, 0);
      controller.setMode(SceneRenderMode.manual);
      await tester.pump();
      final stopped = controller.metrics.renderCalls;
      await tester.pump(const Duration(seconds: 5));
      expect(controller.metrics.renderCalls, stopped);
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
      camera.dispose();
    },
  );

  testWidgets('hidden and detached surfaces stop their drivers and sampling', (
    tester,
  ) async {
    final camera = SceneCameraController();
    final controller = SceneRenderController(
      camera: camera,
      now: () => tester.binding.clock.now().difference(DateTime(2026)),
    )..markReady();
    await tester.pumpWidget(harness(controller));
    await tester.pump(const Duration(milliseconds: 16));
    expect(controller.ticking.value, isTrue);
    controller.startSampling();
    await tester.pumpWidget(harness(controller, active: false));
    expect(controller.ticking.value, isFalse);
    final yaw = camera.yaw;
    await tester.pump(const Duration(seconds: 5));
    expect(camera.yaw, yaw);
    await tester.pumpWidget(harness(controller));
    await tester.pump();
    expect(camera.yaw, yaw);
    await tester.pump(const Duration(milliseconds: 16));
    expect(camera.yaw - yaw, lessThan(.02));
    await tester.pumpWidget(const SizedBox());
    expect(controller.metrics.sampling, isFalse);
    controller.dispose();
    camera.dispose();
  });
}
