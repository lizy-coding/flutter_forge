library file_picker_bridge;

export 'src/file_picker_service.dart';
export 'src/file_selector_file_picker.dart';
export 'src/method_channel_file_picker.dart';

import 'package:flutter/foundation.dart';

import 'src/file_picker_service.dart';
import 'src/file_selector_file_picker.dart';
import 'src/method_channel_file_picker.dart';

FilePickerService createFilePickerService({TargetPlatform? platform}) {
  final targetPlatform = platform ?? defaultTargetPlatform;
  return switch (targetPlatform) {
    TargetPlatform.windows ||
    TargetPlatform.linux =>
      const FileSelectorFilePicker(),
    _ => const MethodChannelFilePicker(),
  };
}
