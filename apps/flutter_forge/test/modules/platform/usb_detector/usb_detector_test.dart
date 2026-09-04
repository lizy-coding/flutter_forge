import 'package:flutter/material.dart';
import 'package:flutter_forge_app/modules/platform/usb_detector/module_entry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('module entry is constructible', () {
    expect(const UsbDetectorEntry(), isA<Widget>());
  });

  testWidgets('USB detector fits a compact Android viewport', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MaterialApp(home: UsbDetectorEntry()));
    await tester.pump(const Duration(milliseconds: 200));

    expect(tester.takeException(), isNull);
  });
}
