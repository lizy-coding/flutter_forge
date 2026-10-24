import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_forge_app/app/forge_pressable_card.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('hover lifts the stroke and elevation for tappable cards', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: ForgePressableCard(
              radius: 12,
              onTap: () => taps++,
              child: const SizedBox(
                height: 80,
                width: 300,
                child: Text('卡片内容'),
              ),
            ),
          ),
        ),
      ),
    );

    BoxDecoration strokeOf(Finder finder) =>
        tester.widget<AnimatedContainer>(finder).foregroundDecoration!
            as BoxDecoration;
    final card = find.byType(ForgePressableCard);
    final container = find
        .descendant(of: card, matching: find.byType(AnimatedContainer))
        .first;
    final idle = strokeOf(container).border!.top.color;
    expect(idle.a, lessThan(0.2));

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: tester.getCenter(card));
    addTearDown(gesture.removePointer);
    await tester.pumpAndSettle();

    final primary = Theme.of(tester.element(card)).colorScheme.primary;
    expect(
      strokeOf(container).border!.top.color,
      primary.withValues(alpha: 0.65),
    );
    final shadow =
        (tester.widget<AnimatedContainer>(container).decoration!
                as BoxDecoration)
            .boxShadow;
    expect(shadow, isNotNull);
    expect(shadow, isNotEmpty);

    await gesture.moveTo(Offset.zero);
    await tester.pumpAndSettle();
    await tester.tap(card);
    expect(taps, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('non-tappable surfaces highlight without elevation', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: ForgePressableCard(
              highlighted: true,
              child: SizedBox(height: 80, width: 300),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(InkWell), findsNothing);
    final card = find.byType(ForgePressableCard);
    final container = find
        .descendant(of: card, matching: find.byType(AnimatedContainer))
        .first;
    final primary = Theme.of(tester.element(card)).colorScheme.primary;
    final decoration = tester.widget<AnimatedContainer>(container);
    expect(
      (decoration.foregroundDecoration! as BoxDecoration).border!.top.color,
      primary.withValues(alpha: 0.65),
    );
    expect(
      (decoration.decoration! as BoxDecoration).boxShadow ?? const [],
      isEmpty,
    );
    expect(tester.takeException(), isNull);
  });
}
