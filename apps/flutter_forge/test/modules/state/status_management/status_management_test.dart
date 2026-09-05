import 'package:flutter/material.dart';
import 'package:flutter_forge_app/modules/state/status_management/pages/riverpod/riverpod_lifting_route.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_forge_app/modules/state/status_management/module_entry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('module entry is constructible', () {
    expect(const StatusManageEntry(), isA<Widget>());
  });

  testWidgets('riverpod lifting controls fit a compact Android viewport', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(size: Size(320, 640)),
        child: ProviderScope(child: MaterialApp(home: RiverpodLiftingRoute())),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('status management home fits a compact Android viewport', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MaterialApp(home: StatusManageEntry()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
