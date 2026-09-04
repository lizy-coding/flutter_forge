import 'package:flutter/material.dart';
import 'package:flutter_forge_app/modules/basic/microtask/pages/home_page.dart';
import 'package:flutter_forge_app/modules/basic/microtask/module_entry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('module entry is constructible', () {
    expect(const MicrotaskEntry(), isA<Widget>());
  });

  testWidgets('microtask home fits supported viewports', (tester) async {
    for (final size in [
      const Size(360, 860),
      const Size(600, 860),
      const Size(1280, 860),
    ]) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(const MaterialApp(home: HomePage()));
      await tester.pump();
      expect(tester.takeException(), isNull, reason: 'viewport $size');
    }
    await tester.binding.setSurfaceSize(null);
  });
}
