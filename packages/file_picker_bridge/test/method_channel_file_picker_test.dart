import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:file_picker_bridge/file_picker_bridge.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MethodChannelFilePicker', () {
    const channel = MethodChannel('test/file_picker');

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('returns picked file from platform response', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        expect(call.method, 'pickFile');
        expect(call.arguments, <String, Object?>{
          'allowedExtensions': ['nc', 'gcode'],
          'title': '选择文件',
          'message': '导入刀路',
        });

        return <String, Object?>{
          'path': '/tmp/sample.nc',
          'name': 'sample.nc',
        };
      });

      const picker = MethodChannelFilePicker(channel: channel);
      final file = await picker.pickFile(
        allowedExtensions: ['nc', 'gcode'],
        title: '选择文件',
        message: '导入刀路',
      );

      expect(file?.path, '/tmp/sample.nc');
      expect(file?.name, 'sample.nc');
    });

    test('returns null when user cancels', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async => null);

      const picker = MethodChannelFilePicker(channel: channel);

      expect(await picker.pickFile(), isNull);
    });
  });
}
