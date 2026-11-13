import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_forge_app/shared/learning/learning_slider.dart';
import 'package:flutter_test/flutter_test.dart';

const _nativeTargets = TargetPlatformVariant({
  TargetPlatform.android,
  TargetPlatform.iOS,
  TargetPlatform.macOS,
  TargetPlatform.windows,
});

void main() {
  testWidgets('native slider keeps pointer changes and gesture boundaries', (
    tester,
  ) async {
    var value = 0.5;
    final gestures = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => LearningSlider(
              value: value,
              divisions: 10,
              onChanged: (next) => setState(() => value = next),
              onChangeStart: (_) => gestures.add('start'),
              onChangeEnd: (_) => gestures.add('end'),
            ),
          ),
        ),
      ),
    );
    final windows = defaultTargetPlatform == TargetPlatform.windows;
    expect(
      find.byType(CupertinoSlider),
      windows ? findsOneWidget : findsNothing,
    );
    expect(find.byType(Slider), windows ? findsNothing : findsOneWidget);
    final control = find.byType(windows ? CupertinoSlider : Slider);
    await tester.drag(control, const Offset(150, 0));
    await tester.pumpAndSettle();
    expect(value, greaterThan(0.5));
    expect(value, lessThanOrEqualTo(1));
    expect(gestures, ['start', 'end']);
    expect(tester.takeException(), isNull);
  }, variant: _nativeTargets);

  testWidgets('disabled slider ignores pointer and exposes no adjustment', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: LearningSlider(value: 0.5, onChanged: null)),
      ),
    );
    await tester.drag(find.byType(LearningSlider), const Offset(150, 0));
    await tester.pumpAndSettle();
    final data = tester
        .getSemantics(find.byType(LearningSlider))
        .getSemanticsData();
    expect(data.hasAction(ui.SemanticsAction.increase), isFalse);
    expect(data.hasAction(ui.SemanticsAction.decrease), isFalse);
    expect(
      tester.widget<LearningSlider>(find.byType(LearningSlider)).value,
      0.5,
    );
    semantics.dispose();
    expect(tester.takeException(), isNull);
  }, variant: _nativeTargets);

  testWidgets('Windows RTL keys and endpoint semantics respect value bounds', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    var value = 0.5;
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => LearningSlider(
                value: value,
                divisions: 10,
                onChanged: (next) => setState(() => value = next),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(value, closeTo(0.4, 0.001));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    expect(value, closeTo(0.5, 0.001));
    for (final endpoint in [LogicalKeyboardKey.home, LogicalKeyboardKey.end]) {
      await tester.sendKeyEvent(endpoint);
      await tester.pump();
      final minimum = endpoint == LogicalKeyboardKey.home;
      expect(value, minimum ? 0 : 1);
      final data = tester
          .getSemantics(find.byType(LearningSlider))
          .getSemanticsData();
      expect(data.hasAction(ui.SemanticsAction.decrease), !minimum);
      expect(data.hasAction(ui.SemanticsAction.increase), minimum);
    }
    semantics.dispose();
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.windows));
}
