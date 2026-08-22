import 'package:file_picker_bridge/file_picker_bridge.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_forge_app/modules/ui/font_picker/data/font_catalog.dart';
import 'package:flutter_forge_app/modules/ui/font_picker/pages/font_picker_page.dart';
import 'package:flutter_forge_app/modules/ui/font_picker/pages/weight_compare_page.dart';
import 'package:flutter_forge_app/modules/ui/font_picker/state/font_loader_service.dart';

void main() {
  test('catalog exposes platform fonts and a fallback', () {
    expect(
      FontCatalog.fontsFor(TargetPlatform.macOS).map((font) => font.family),
      containsAll(['PingFang SC', 'Monaco']),
    );
    expect(
      FontCatalog.fontsFor(TargetPlatform.windows).map((font) => font.family),
      containsAll(['Microsoft YaHei', 'Consolas']),
    );
    expect(FontCatalog.fontsFor(TargetPlatform.android), isNotEmpty);
  });

  testWidgets('selecting a font updates the selected row and preview', (
    tester,
  ) async {
    await _pumpFontPicker(tester);
    final options = FontCatalog.fontsFor(TargetPlatform.android);

    for (final option in options) {
      expect(find.text(option.displayName), findsWidgets);
    }
    final target = options[1];
    await tester.tap(find.byKey(Key('font-option-${target.id}')));
    await tester.pump();

    final card = tester.widget<Card>(
      find.byKey(Key('font-option-${target.id}')),
    );
    expect(card.color, isNotNull);
    expect(
      find.descendant(
        of: find.byKey(const Key('font-preview-panel')),
        matching: find.text(target.displayName),
      ),
      findsOneWidget,
    );
  });

  testWidgets('loading a local font inserts and selects a custom option', (
    tester,
  ) async {
    final loader = FakeFontLoaderService();
    await _pumpFontPicker(
      tester,
      picker: FakeFilePickerService(
        result: const PickedFile(path: '/tmp/custom.ttf', name: 'custom.ttf'),
      ),
      loader: loader,
      fileReader: (_) async => Uint8List.fromList([1, 2, 3]),
    );

    await tester.tap(find.byKey(const Key('load-local-font')));
    await tester.pump();

    expect(find.text('custom.ttf'), findsWidgets);
    expect(find.text('本地'), findsOneWidget);
    expect(find.text('本地字体'), findsWidgets);
    expect(loader.familyName, startsWith('custom_font_'));
    expect(loader.bytes, isNotEmpty);
  });

  testWidgets('cancelled local font selection leaves list unchanged', (
    tester,
  ) async {
    await _pumpFontPicker(tester);

    await tester.tap(find.byKey(const Key('load-local-font')));
    await tester.pump();

    expect(find.text('本地'), findsNothing);
  });

  testWidgets('weight comparison exposes controls and toggles italic', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: WeightComparePage()));

    expect(find.byKey(const Key('weight-100')), findsOneWidget);
    expect(find.byKey(const Key('weight-900')), findsOneWidget);
    expect(find.byKey(const Key('letter-spacing-slider')), findsOneWidget);
    await tester.tap(find.byKey(const Key('italic-toggle')));
    await tester.pump();

    final preview = tester.widget<Text>(
      find.byKey(const Key('live-style-preview')),
    );
    expect(preview.style?.fontStyle, FontStyle.italic);
  });
}

Future<void> _pumpFontPicker(
  WidgetTester tester, {
  FilePickerService? picker,
  FontLoaderService? loader,
  FontBytesReader? fileReader,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: FontPickerPage(
        filePicker: picker ?? FakeFilePickerService(),
        loader: loader ?? FakeFontLoaderService(),
        fileReader: fileReader ?? (_) async => Uint8List(0),
      ),
    ),
  );
}

class FakeFilePickerService implements FilePickerService {
  FakeFilePickerService({this.result});

  final PickedFile? result;

  @override
  Future<PickedFile?> pickFile({
    List<String> allowedExtensions = const [],
    String? title,
    String? message,
  }) async => result;
}

class FakeFontLoaderService implements FontLoaderService {
  String? familyName;
  Uint8List bytes = Uint8List(0);

  @override
  Future<void> loadFont({
    required String familyName,
    required Uint8List bytes,
  }) async {
    this.familyName = familyName;
    this.bytes = bytes;
  }
}
