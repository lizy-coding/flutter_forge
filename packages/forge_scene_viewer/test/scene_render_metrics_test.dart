import 'package:flutter_test/flutter_test.dart';
import 'package:forge_scene_viewer/forge_scene_viewer.dart';

void main() {
  test(
    'CPU percentiles exclude captures and retain bounded ordered samples',
    () {
      final metrics = SceneRenderMetrics()..sampling = true;
      for (var i = 1; i <= 100; i++) {
        metrics.rendered(Duration(milliseconds: i), i, reason: 'animation');
      }
      metrics.rendered(
        const Duration(milliseconds: 101),
        999999,
        reason: 'capture',
        capture: true,
      );
      expect(metrics.sceneCpu.count, 100);
      expect(metrics.sceneCpu.p50, 50);
      expect(metrics.sceneCpu.p95, 95);
      expect(metrics.sceneCpu.max, 100);
      expect(metrics.captures, 1);
      for (var i = 102; i < 2000; i++) {
        metrics.rendered(Duration(milliseconds: i), i, reason: 'animation');
      }
      expect(metrics.renderSamples.length, SceneRenderMetrics.maxSamples);
      metrics.trim(const Duration(seconds: 15));
      expect(metrics.sceneCpu.count, 0);
    },
  );

  test('call rate expires without treating idle as missing frames', () {
    final metrics = SceneRenderMetrics();
    metrics.rendered(Duration.zero, null, reason: 'initial');
    metrics.rendered(const Duration(milliseconds: 200), null, reason: 'input');
    expect(metrics.callsInLastSecond(const Duration(milliseconds: 900)), 2);
    expect(metrics.callsInLastSecond(const Duration(milliseconds: 1100)), 1);
    expect(metrics.callsInLastSecond(const Duration(milliseconds: 1200)), 0);
    expect(metrics.sceneCpu.count, 0);
    expect(metrics.renderCalls, 2);
  });

  test(
    'window budget uses each stage and data is separate from scene calls',
    () {
      final metrics = SceneRenderMetrics()..sampling = true;
      metrics.windowFrame(
        const SceneWindowFrameSample(Duration.zero, 9000, 9000, 16667),
      );
      metrics.windowFrame(
        const SceneWindowFrameSample(Duration.zero, 1000, 17000, 16667),
      );
      expect(metrics.overBudgetRatio, .5);
      expect(metrics.renderCalls, 0);
      metrics.sampling = false;
      metrics.windowFrame(
        const SceneWindowFrameSample(Duration.zero, 99999, 99999, 16667),
      );
      expect(metrics.windowBuild.count, 2);
    },
  );

  test(
    'errors are bounded, unmeasured GPU values stay null, clear resets session',
    () {
      final metrics = SceneRenderMetrics();
      for (var i = 0; i < 100; i++) {
        metrics.rendered(
          Duration(milliseconds: i),
          null,
          reason: 'retry',
          error: StateError('failed'),
        );
      }
      expect(metrics.failures, 100);
      expect(metrics.returned, 0);
      expect(metrics.events.length, 32);
      expect(metrics.snapshot(Duration.zero)['gpu_duration_us'], isNull);
      metrics.clear();
      expect(metrics.renderCalls, 0);
      expect(metrics.lastError, isNull);
      expect(metrics.events, isEmpty);
    },
  );
}
