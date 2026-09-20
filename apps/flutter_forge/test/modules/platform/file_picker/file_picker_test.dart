import 'package:file_picker_bridge/file_picker_bridge.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_forge_app/app/router/app_route_table.dart';
import 'package:flutter_forge_app/module_registry/module_catalog_utils.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_forge_app/modules/platform/file_picker/module_root.dart';

void main() {
  test('catalog admits file picker on Android, macOS, and Windows', () {
    final module = AppRouteTable.modules.singleWhere(
      (item) => item.path == '/file-picker',
    );

    expect(module.platformSupport.nativePlatforms, {
      TargetPlatform.android,
      TargetPlatform.macOS,
      TargetPlatform.windows,
    });
    for (final platform in [
      TargetPlatform.android,
      TargetPlatform.macOS,
      TargetPlatform.windows,
    ]) {
      expect(isModuleAvailable(module, platform, false), isTrue);
    }
    expect(isModuleAvailable(module, TargetPlatform.iOS, false), isFalse);
  });

  testWidgets('picked file shows its name and path', (tester) async {
    final picker = FakeFilePickerService(
      result: const PickedFile(path: '/tmp/a.gcode', name: 'a.gcode'),
    );
    await _pumpModule(tester, picker);

    await tester.tap(find.byKey(const Key('pick-file-button')));
    await tester.pump();

    expect(find.text('a.gcode'), findsOneWidget);
    if (kIsWeb) {
      expect(find.text('/tmp/a.gcode'), findsNothing);
      expect(find.textContaining('大小：'), findsNothing);
    } else {
      expect(find.text('/tmp/a.gcode'), findsOneWidget);
      expect(find.textContaining('大小：'), findsOneWidget);
    }
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

    if (kIsWeb) {
      expect(find.text('文本'), findsNothing);
      return;
    }

    await tester.tap(find.text('文本'));
    await tester.pump();
    await tester.tap(find.byKey(const Key('pick-file-button')));
    await tester.pump();
    expect(picker.allowedExtensions, contains('.txt'));
  });

  testWidgets('file picker fits a compact Android viewport', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpModule(tester, FakeFilePickerService());

    expect(find.byKey(const Key('pick-file-button')), findsOneWidget);
    expect(tester.takeException(), isNull);
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
