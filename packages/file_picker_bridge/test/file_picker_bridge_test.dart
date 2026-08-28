import 'package:file_picker_bridge/file_picker_bridge.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('createFilePickerService', () {
    test('selects the file selector implementation on Windows', () {
      expect(
        createFilePickerService(platform: TargetPlatform.windows),
        isA<FileSelectorFilePicker>(),
      );
    });

    test('keeps the MethodChannel implementation on macOS', () {
      expect(
        createFilePickerService(platform: TargetPlatform.macOS),
        isA<MethodChannelFilePicker>(),
      );
    });
  });

  group('fileSelectorTypeGroupForExtensions', () {
    test('uses no type group when all file types are allowed', () {
      expect(fileSelectorTypeGroupForExtensions(const []), isNull);
    });

    test('maps allowed extensions to one XTypeGroup', () {
      final group = fileSelectorTypeGroupForExtensions(
        const ['gcode', 'nc'],
      );

      expect(group, isNotNull);
      expect(group!.extensions, equals(['gcode', 'nc']));
    });
  });
}
