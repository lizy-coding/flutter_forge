import 'dart:async';

import 'package:file_picker_bridge/file_picker_bridge.dart';
import 'package:flutter/services.dart';
import 'package:flutter_forge_app/modules/platform/file_picker/state/file_picker_controller.dart';
import 'package:flutter_test/flutter_test.dart';

class _PendingPicker implements FilePickerService {
  final requests = <Completer<PickedFile?>>[];

  @override
  Future<PickedFile?> pickFile({
    List<String> allowedExtensions = const [],
    String? title,
    String? message,
  }) {
    final request = Completer<PickedFile?>();
    requests.add(request);
    return request.future;
  }
}

void main() {
  for (final outcome in ['success', 'cancel', 'missingPlugin', 'error']) {
    test(
      'disposed picker ignores late $outcome and rejects new operations',
      () async {
        final picker = _PendingPicker();
        final controller = FilePickerController(filePicker: picker);
        var notifications = 0;
        controller.addListener(() => notifications++);
        final pending = controller.pickFile();
        controller.dispose();
        final before = notifications;
        switch (outcome) {
          case 'success':
            picker.requests.single.complete(
              const PickedFile(path: '/tmp/a.nc'),
            );
          case 'cancel':
            picker.requests.single.complete(null);
          case 'missingPlugin':
            picker.requests.single.completeError(MissingPluginException());
          case 'error':
            picker.requests.single.completeError(StateError('picker failed'));
        }
        await pending;
        await controller.pickFile();
        controller.setFilterMode('text');
        expect(notifications, before);
        expect(controller.pickedFile, isNull);
        expect(controller.errorMessage, isNull);
        expect(controller.filterMode, 'gcode');
        expect(picker.requests, hasLength(1));
      },
    );
  }

  test('pending selection is exclusive and failure allows retry', () async {
    final picker = _PendingPicker();
    final controller = FilePickerController(filePicker: picker);
    addTearDown(controller.dispose);
    final first = controller.pickFile();
    await controller.pickFile();
    expect(picker.requests, hasLength(1));
    picker.requests.first.completeError(StateError('failed'));
    await first;
    expect(controller.state, FilePickerState.error);
    final retry = controller.pickFile();
    picker.requests.last.complete(const PickedFile(path: '/tmp/b.nc'));
    await retry;
    expect(controller.state, FilePickerState.picked);
    expect(controller.pickedFile?.path, '/tmp/b.nc');
  });
}
