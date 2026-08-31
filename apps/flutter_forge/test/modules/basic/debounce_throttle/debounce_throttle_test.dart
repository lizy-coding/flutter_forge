import 'package:flutter/material.dart';
import 'package:flutter_forge_app/modules/basic/debounce_throttle/module_entry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('module entry is constructible', () {
    expect(const DebounceThrottleEntry(), isA<Widget>());
  });

  testWidgets('comparison remains usable at 360x800', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MaterialApp(home: DebounceThrottleEntry()));
    await tester.pump();

    expect(find.text('普通点击'), findsOneWidget);
    expect(find.text('防抖点击'), findsOneWidget);
    expect(find.text('节流点击'), findsOneWidget);
    expect(find.text('普通: 0'), findsOneWidget);
    expect(find.text('防抖: 0'), findsOneWidget);
    expect(find.text('节流: 0'), findsOneWidget);
    expect(find.text('普通'), findsOneWidget);
    expect(find.text('防抖'), findsOneWidget);
    expect(find.text('节流'), findsOneWidget);

    await tester.tap(find.text('普通点击'));
    await tester.tap(find.text('防抖点击'));
    await tester.tap(find.text('节流点击'));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('普通: 1'), findsOneWidget);
    expect(find.text('防抖: 1'), findsOneWidget);
    expect(find.text('节流: 1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('scroll comparison remains usable at 360x800', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MaterialApp(home: DebounceThrottleEntry()));
    await tester.tap(find.text('滚动场景'));
    await tester.pumpAndSettle();

    expect(find.text('实时位置'), findsOneWidget);
    expect(find.text('防抖位置'), findsOneWidget);
    expect(find.text('节流位置'), findsOneWidget);
    expect(find.text('实时'), findsWidgets);
    expect(find.text('防抖'), findsWidgets);
    expect(find.text('节流'), findsWidgets);

    await tester.drag(find.byType(ListView), const Offset(0, -200));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('0px'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final viewport in const [
    (label: '600x900', size: Size(600, 900)),
    (label: '1024x768', size: Size(1024, 768)),
  ]) {
    testWidgets('comparison remains usable at ${viewport.label}', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(viewport.size);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(const MaterialApp(home: DebounceThrottleEntry()));
      await tester.pump();

      expect(find.text('普通点击'), findsOneWidget);
      expect(find.text('防抖点击'), findsOneWidget);
      expect(find.text('节流点击'), findsOneWidget);
      expect(find.text('普通: 0'), findsOneWidget);
      expect(find.text('防抖: 0'), findsOneWidget);
      expect(find.text('节流: 0'), findsOneWidget);
      expect(find.text('普通'), findsOneWidget);
      expect(find.text('防抖'), findsOneWidget);
      expect(find.text('节流'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('滚动场景'));
      await tester.pumpAndSettle();

      expect(find.text('实时位置'), findsOneWidget);
      expect(find.text('防抖位置'), findsOneWidget);
      expect(find.text('节流位置'), findsOneWidget);

      await tester.drag(find.byType(ListView), const Offset(0, -200));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('0px'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
