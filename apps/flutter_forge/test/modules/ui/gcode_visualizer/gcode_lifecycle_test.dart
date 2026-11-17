import 'dart:async';

import 'package:file_picker_bridge/file_picker_bridge.dart';
import 'package:flutter/services.dart';
import 'package:flutter_forge_app/modules/ui/gcode_visualizer/state/gcode_player_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gcode_core/gcode_core.dart';

class _PendingPicker implements FilePickerService {
  final pending = Completer<PickedFile?>();
  int calls = 0;

  @override
  Future<PickedFile?> pickFile({
    List<String> allowedExtensions = const [],
    String? title,
    String? message,
  }) {
    calls++;
    return pending.future;
  }
}

GcodeLoadSnapshot _snapshot(int lines) => GcodeLoadSnapshot(
  stage: GcodeLoadStage.ready,
  commands: const [],
  errors: const [],
  segments: const [],
  linesRead: lines,
  message: 'loaded $lines',
);

void main() {
  for (final outcome in [
    'success',
    'cancel',
    'missingPlugin',
    'platformError',
    'error',
  ]) {
    test('G-code ignores picker $outcome after disposal', () async {
      final picker = _PendingPicker();
      var loads = 0;
      final controller = GcodePlayerController(
        vsync: const TestVSync(),
        filePicker: picker,
        loadSnapshots: (_) {
          loads++;
          return Stream.value(_snapshot(1));
        },
      );
      final pending = controller.pickFilePathAndLoad();
      controller.dispose();
      switch (outcome) {
        case 'success':
          picker.pending.complete(const PickedFile(path: '/tmp/a.nc'));
        case 'cancel':
          picker.pending.complete(null);
        case 'missingPlugin':
          picker.pending.completeError(MissingPluginException());
        case 'platformError':
          picker.pending.completeError(PlatformException(code: 'failed'));
        case 'error':
          picker.pending.completeError(StateError('failed'));
      }
      expect(await pending, isNull);
      await controller.parse();
      await controller.loadFilePath('/tmp/new.nc');
      expect(await controller.pickFilePathAndLoad(), isNull);
      expect(loads, 0);
      expect(picker.calls, 1);
    });
  }

  test(
    'dispose cancels a silent stream and settles the pending load',
    () async {
      var cancellations = 0;
      final stream = StreamController<GcodeLoadSnapshot>(
        onCancel: () => cancellations++,
      );
      final controller = GcodePlayerController(
        vsync: const TestVSync(),
        loadSnapshots: (_) => stream.stream,
      );
      final pending = controller.parse();
      controller.dispose();
      await pending;
      expect(cancellations, 1);
      stream.add(_snapshot(99));
      await stream.close();
      expect(controller.linesRead, 0);
    },
  );

  test(
    'replacement cancels the old load without waiting for another event',
    () async {
      var cancellations = 0;
      final old = StreamController<GcodeLoadSnapshot>(
        onCancel: () => cancellations++,
      );
      final next = StreamController<GcodeLoadSnapshot>();
      var calls = 0;
      final controller = GcodePlayerController(
        vsync: const TestVSync(),
        loadSnapshots: (_) => calls++ == 0 ? old.stream : next.stream,
      );
      addTearDown(controller.dispose);
      final first = controller.parse();
      final second = controller.parse();
      await first;
      expect(cancellations, 1);
      old.add(_snapshot(99));
      next.add(_snapshot(2));
      await next.close();
      await second;
      await old.close();
      expect(controller.linesRead, 2);
      expect(controller.loadStage, GcodeLoadStage.ready);
    },
  );

  test(
    'parse supersedes an open picker and duplicate picker calls are ignored',
    () async {
      final picker = _PendingPicker();
      var loads = 0;
      final controller = GcodePlayerController(
        vsync: const TestVSync(),
        filePicker: picker,
        loadSnapshots: (_) => Stream.value(_snapshot(++loads)),
      );
      addTearDown(controller.dispose);
      final pending = controller.pickFilePathAndLoad();
      expect(await controller.pickFilePathAndLoad(), isNull);
      await controller.parse();
      picker.pending.complete(const PickedFile(path: '/tmp/old.nc'));
      expect(await pending, isNull);
      expect(loads, 1);
      expect(picker.calls, 1);
    },
  );

  test(
    'stream failure is visible, closes the stream, and permits retry',
    () async {
      var cancelled = 0;
      final stream = StreamController<GcodeLoadSnapshot>(
        onCancel: () => cancelled++,
      );
      var calls = 0;
      final controller = GcodePlayerController(
        vsync: const TestVSync(),
        loadSnapshots: (_) =>
            calls++ == 0 ? stream.stream : Stream.value(_snapshot(3)),
      );
      addTearDown(controller.dispose);
      final first = controller.parse();
      stream.addError(StateError('read failed'));
      await first;
      expect(controller.loadStage, GcodeLoadStage.failed);
      expect(controller.loadMessage, contains('read failed'));
      expect(cancelled, 1);
      await stream.close();
      await controller.parse();
      expect(controller.linesRead, 3);
    },
  );

  test(
    'default pipeline supports replacement and disposal during parsing',
    () async {
      final controller = GcodePlayerController(vsync: const TestVSync());
      controller.updateSource(List.filled(1000, 'G1 X1 F100').join('\n'));
      final first = controller.parse();
      controller.updateSource('G0 X0\nG1 X2 F100');
      final second = controller.parse();
      await Future.wait([first, second]);
      expect(controller.linesRead, 2);
      expect(controller.totalCommands, 2);
      final pending = controller.parse();
      controller.dispose();
      await pending;
    },
  );

  test(
    'reader creation failure remains observable and retry succeeds',
    () async {
      var calls = 0;
      final controller = GcodePlayerController(
        vsync: const TestVSync(),
        loadSnapshots: (_) {
          if (calls++ == 0) throw StateError('reader unavailable');
          return Stream.value(_snapshot(4));
        },
      );
      addTearDown(controller.dispose);
      await controller.parse();
      expect(controller.loadStage, GcodeLoadStage.failed);
      expect(controller.loadMessage, contains('reader unavailable'));
      await controller.parse();
      expect(controller.linesRead, 4);
    },
  );
}
