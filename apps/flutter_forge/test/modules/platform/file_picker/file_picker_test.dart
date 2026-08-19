import 'package:file_picker_bridge/file_picker_bridge.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_forge_app/modules/platform/file_picker/module_root.dart';

void main() {
  testWidgets('picked file shows its name and path', (tester) async {
    final picker = FakeFilePickerService(
      result: const PickedFile(path: '/tmp/a.gcode', name: 'a.gcode'),
    );
    await _pumpModule(tester, picker);

    await tester.tap(find.byKey(const Key('pick-file-button')));
    await tester.pump();

    expect(find.text('a.gcode'), findsOneWidget);
    expect(find.text('/tmp/a.gcode'), findsOneWidget);
  });

  testWidgets('cancelled selection renders the cancel branch', (tester) async {
    final picker = FakeFilePickerService();
    await _pumpModule(tester, picker);

    await tester.tap(find.byKey(const Key('pick-file-button')));
    await tester.pump();

    expect(find.textContaining('未选择文件'), findsOneWidget);
  });

  testWidgets('missing plugin renders platform unsupported state', (
    tester,
  ) async {
    final picker = FakeFilePickerService(error: MissingPluginException());
    await _pumpModule(tester, picker);

    await tester.tap(find.byKey(const Key('pick-file-button')));
    await tester.pump();

    expect(find.text('当前平台暂未实现原生文件选择桥接'), findsOneWidget);
  });

  testWidgets('filter mode controls allowed extensions', (tester) async {
    final picker = FakeFilePickerService();
    await _pumpModule(tester, picker);

    await tester.tap(find.byKey(const Key('pick-file-button')));
    await tester.pump();
    expect(picker.allowedExtensions, contains('.gcode'));

    await tester.tap(find.text('文本'));
    await tester.pump();
    await tester.tap(find.byKey(const Key('pick-file-button')));
    await tester.pump();
    expect(picker.allowedExtensions, contains('.txt'));
  });
}

Future<void> _pumpModule(WidgetTester tester, FilePickerService picker) async {
  await tester.pumpWidget(MaterialApp(home: HomePage(filePicker: picker)));
}

class FakeFilePickerService implements FilePickerService {
  FakeFilePickerService({this.result, this.error});

  final PickedFile? result;
  final Object? error;
  List<String> allowedExtensions = const [];

  @override
  Future<PickedFile?> pickFile({
    List<String> allowedExtensions = const [],
    String? title,
    String? message,
  }) async {
    this.allowedExtensions = allowedExtensions;
    if (error != null) throw error!;
    return result;
  }
}
