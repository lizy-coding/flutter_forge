import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter_forge_app/modules/ui/gcode_visualizer/state/gcode_player_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gcode_core/gcode_core.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('G-code native GPU load seek replace and dispose', (
    tester,
  ) async {
    expect(defaultTargetPlatform, TargetPlatform.macOS);
    final errors = <Object>[];
    var ready = 0;
    final stats = GcodeRenderStats();
    final boundary = GlobalKey();
    final controller = GcodePlayerController(vsync: tester);
    try {
      controller.updateSource(
        List.generate(
          10000,
          (i) => 'G1 X${i % 100} Y${i ~/ 100} F600',
        ).join('\n'),
      );
      await controller.parse();
      expect(controller.segments.length, 9999);
      Widget buildHost() => MaterialApp(
        home: Scaffold(
          body: ListenableBuilder(
            listenable: Listenable.merge([controller, controller.playback]),
            builder: (context, _) => RepaintBoundary(
              key: boundary,
              child: GcodeCanvas(
                stats: stats,
                showLegend: false,
                segments: controller.segments,
                bounds: controller.bounds,
                progress: controller.progress,
                onReady: () => ready++,
                onError: errors.add,
              ),
            ),
          ),
        ),
      );
      await tester.pumpWidget(buildHost());
      Future<void> waitForReady(int count) async {
        for (var i = 0; i < 100 && ready < count && errors.isEmpty; i++) {
          await tester.pump(const Duration(milliseconds: 50));
        }
        expect(errors, isEmpty);
        expect(ready, count);
      }

      await waitForReady(1);
      Future<int> greenPixelCount() async {
        final render =
            boundary.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final image = await render.toImage(pixelRatio: 1);
        try {
          final data = await image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          );
          final bytes = data!.buffer.asUint8List(
            data.offsetInBytes,
            data.lengthInBytes,
          );
          var count = 0;
          for (var i = 0; i < bytes.length; i += 4) {
            if (bytes[i + 1] > bytes[i] + 25 &&
                bytes[i + 1] > bytes[i + 2] + 25) {
              count++;
            }
          }
          return count;
        } finally {
          image.dispose();
        }
      }

      final builds = stats.geometryBuilds;
      final uploads = stats.vertexUploadBytes;
      final frames = stats.compositedFrames;
      expect(builds, 1);
      expect(uploads, greaterThan(0));
      expect(stats.activeResourceSets, 1);
      final beforeSeek = await greenPixelCount();
      controller.seek(.5);
      await tester.pump();
      expect(controller.progress, .5);
      expect(controller.currentCommandIndex, 5000);
      expect(controller.currentSegmentProgress, .5);
      final afterSeek = await greenPixelCount();
      expect(afterSeek, greaterThan(beforeSeek + 100));
      await binding.watchPerformance(() async {
        controller.play();
        await tester.pump();
        for (var frame = 0; frame < 60; frame++) {
          await tester.pump(const Duration(milliseconds: 16));
        }
        controller.pause();
      }, reportKey: 'gcodePlayback');
      expect(controller.progress, greaterThan(.5));
      expect(stats.compositedFrames, greaterThan(frames));
      expect(stats.geometryBuilds, builds);
      expect(stats.vertexUploadBytes, uploads);
      controller.seek(1);
      await tester.pump();
      expect(controller.progress, 1);
      expect(controller.currentSegmentProgress, 1);
      controller.updateSource('G1 X20 Y20\nG1 X50 Y10');
      await controller.parse();
      await tester.pump();
      await waitForReady(2);
      expect(controller.totalCommands, 2);
      final rssSamples = <int>[];
      for (var cycle = 0; cycle < 3; cycle++) {
        await tester.pumpWidget(const SizedBox());
        expect(stats.activeResourceSets, 0);
        await tester.pumpWidget(buildHost());
        await waitForReady(cycle + 3);
        expect(stats.activeResourceSets, 1);
        rssSamples.add(ProcessInfo.currentRss);
      }
      await tester.pumpWidget(const SizedBox());
      expect(errors, isEmpty);
      expect(stats.activeResourceSets, 0);
      expect(stats.resourceSetsCreated, stats.resourceSetsCleared);
      // These are CPU submissions and cleanup calls, not GPU memory readings.
      final workMetrics = <String, Object>{
        'geometryBuilds': stats.geometryBuilds,
        'vertexUploadBytes': stats.vertexUploadBytes,
        'frames': stats.compositedFrames,
        'surfaces': stats.surfaceCreations,
        'resourceSetsCreated': stats.resourceSetsCreated,
        'resourceSetsCleared': stats.resourceSetsCleared,
        'greenBeforeSeek': beforeSeek,
        'greenAfterSeek': afterSeek,
        'remountRssSamples': rssSamples,
        'rssAtEnd': ProcessInfo.currentRss,
      };
      binding.reportData!['gcodeWork'] = workMetrics;
      debugPrint('GCODE_REFRESH_METRICS ${jsonEncode(workMetrics)}');
    } finally {
      controller.dispose();
    }
  });
}
