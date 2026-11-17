import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_forge_app/modules/ui/gcode_visualizer/state/gcode_player_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gcode_core/gcode_core.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('G-code native GPU load seek replace and dispose', (
    tester,
  ) async {
    expect(defaultTargetPlatform, TargetPlatform.macOS);
    final errors = <Object>[];
    var ready = 0;
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
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListenableBuilder(
              listenable: Listenable.merge([controller, controller.playback]),
              builder: (context, _) => GcodeCanvas(
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
      Future<void> waitForReady(int count) async {
        for (var i = 0; i < 100 && ready < count && errors.isEmpty; i++) {
          await tester.pump(const Duration(milliseconds: 50));
        }
        expect(errors, isEmpty);
        expect(ready, count);
      }

      await waitForReady(1);
      controller.seek(.5);
      await tester.pump();
      controller.play();
      await tester.pump(const Duration(milliseconds: 250));
      controller.pause();
      controller.updateSource('G1 X20 Y20\nG1 X50 Y10');
      await controller.parse();
      await tester.pump();
      await waitForReady(2);
      expect(controller.totalCommands, 2);
      await tester.pumpWidget(const SizedBox());
      expect(errors, isEmpty);
    } finally {
      controller.dispose();
    }
  });
}
