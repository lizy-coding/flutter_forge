import 'package:flutter/widgets.dart';
import 'package:flutter_forge_app/modules/ui/gcode_visualizer/state/gcode_player_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gcode_core/gcode_core.dart';

void main() {
  testWidgets('playback does not notify the page or replace geometry', (
    tester,
  ) async {
    final parsed = GcodeParser().parse('G1 X10 F600\nG1 X20');
    final segments = ToolpathBuilder.build(parsed.commands);
    final controller = GcodePlayerController(
      vsync: const TestVSync(),
      loadSnapshots: (_) => Stream.value(
        GcodeLoadSnapshot(
          stage: GcodeLoadStage.ready,
          commands: parsed.commands,
          errors: parsed.errors,
          segments: segments,
          linesRead: 2,
        ),
      ),
    );
    addTearDown(controller.dispose);
    await tester.runAsync(controller.parse);
    var pageNotifications = 0;
    var playbackNotifications = 0;
    controller.addListener(() => pageNotifications++);
    controller.playback.addListener(() => playbackNotifications++);
    controller.play();
    pageNotifications = 0;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(playbackNotifications, greaterThan(0));
    expect(pageNotifications, 0);
    expect(identical(controller.segments, segments), isTrue);
    expect(controller.currentCommandIndex, 0);
    controller.pause();
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
    'seek coalesces per frame and does not notify the page or unchanged selection',
    (tester) async {
      final parsed = GcodeParser().parse('G1 X10 F600\nG1 X20');
      final controller = GcodePlayerController(
        vsync: const TestVSync(),
        loadSnapshots: (_) => Stream.value(
          GcodeLoadSnapshot(
            stage: GcodeLoadStage.ready,
            commands: parsed.commands,
            errors: parsed.errors,
            segments: ToolpathBuilder.build(parsed.commands),
            linesRead: 2,
          ),
        ),
      );
      addTearDown(controller.dispose);
      await tester.runAsync(controller.parse);
      controller.seek(.1);
      await tester.pump();
      var page = 0, progress = 0, selection = 0;
      controller.addListener(() => page++);
      controller.playback.addListener(() => progress++);
      controller.commandSelection.addListener(() => selection++);
      controller.seek(.15);
      controller.seek(.2);
      controller.seek(.25);
      expect(controller.progress, .1);
      await tester.pump();
      expect(controller.progress, .25);
      expect(controller.currentSegmentProgress, .5);
      expect(progress, 1);
      expect(page, 0);
      expect(selection, 0);
      controller.seek(.8);
      await tester.pump();
      expect(controller.currentCommandIndex, 1);
      expect(selection, 1);
      expect(page, 0);
      controller.seek(.9);
      controller.reset();
      await tester.pump();
      expect(controller.progress, 0);
      controller.seek(.9);
      await tester.runAsync(controller.parse);
      await tester.pump();
      expect(controller.progress, 0);
    },
  );

  testWidgets('pending seek is cancelled on disposal', (tester) async {
    final controller = GcodePlayerController(vsync: const TestVSync());
    controller.seek(.8);
    controller.dispose();
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
