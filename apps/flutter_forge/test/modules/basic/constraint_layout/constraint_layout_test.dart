import 'package:flutter/material.dart';
import 'package:flutter_forge_app/module_registry/module_category.dart';
import 'package:flutter_forge_app/module_registry/module_manifest.dart';
import 'package:flutter_forge_app/modules/basic/constraint_layout/module_entry.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _mount(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(const MaterialApp(home: ConstraintLayoutEntry()));
}

Future<void> _choose(WidgetTester tester, String label) async {
  final chip = find.widgetWithText(ChoiceChip, label);
  await tester.ensureVisible(chip);
  await tester.tap(chip);
  await tester.pumpAndSettle();
}

void _changeSlider(WidgetTester tester, String key, double value) {
  tester.widget<Slider>(find.byKey(ValueKey(key))).onChanged!(value);
}

Finder _item(String label) => find.byKey(ValueKey('layout-item-$label'));

void main() {
  testWidgets(
    'drag updates constraints continuously and stops on cancellation',
    (tester) async {
      await _mount(tester, const Size(800, 1200));
      final parent = find.byKey(const ValueKey('constraint-parent'));
      final child = find.byKey(const ValueKey('constrained-child'));
      final handle = find.byKey(const ValueKey('parent-resize-handle'));
      await tester.ensureVisible(handle);
      final initialSize = tester.getSize(parent);
      final gesture = await tester.startGesture(tester.getCenter(handle));
      await gesture.moveBy(const Offset(-30, -20));
      await tester.pump();
      await gesture.moveBy(const Offset(-80, -30));
      await tester.pump();
      final middleSize = tester.getSize(parent);
      expect(middleSize.width, lessThan(initialSize.width));
      expect(middleSize.height, lessThan(initialSize.height));
      expect(tester.getSize(child), const Size(120, 80));
      expect(find.text('拖动中：父约束 → 子组件尺寸 → 布局更新'), findsOneWidget);
      await gesture.moveBy(const Offset(-50, -10));
      await tester.pump();
      expect(tester.getSize(parent).width, lessThan(middleSize.width));
      await gesture.cancel();
      await tester.pumpAndSettle();
      expect(find.text('拖动中：父约束 → 子组件尺寸 → 布局更新'), findsNothing);

      await _choose(tester, '紧约束');
      await tester.ensureVisible(handle);
      await tester.drag(handle, const Offset(120, 50));
      await tester.pumpAndSettle();
      expect(tester.getSize(child), tester.getSize(parent));
      expect(
        tester
            .widget<Slider>(find.byKey(const ValueKey('parent-height')))
            .value,
        tester.getSize(parent).height,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('drag bounds remain valid and width handle triggers wrap', (
    tester,
  ) async {
    await _mount(tester, const Size(800, 1200));
    final handle = find.byKey(const ValueKey('parent-resize-handle'));
    await tester.ensureVisible(handle);
    await tester.drag(handle, const Offset(-2000, -1000));
    await tester.pumpAndSettle();
    expect(
      tester.widget<Slider>(find.byKey(const ValueKey('parent-width'))).value,
      0.4,
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('constraint-parent'))).height,
      80,
    );
    await tester.ensureVisible(handle);
    await tester.drag(handle, const Offset(2000, 1000));
    await tester.pumpAndSettle();
    expect(
      tester.widget<Slider>(find.byKey(const ValueKey('parent-width'))).value,
      1,
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('constraint-parent'))).height,
      240,
    );

    await _choose(tester, 'Wrap');
    expect(tester.getTopLeft(_item('A')).dy, tester.getTopLeft(_item('C')).dy);
    final widthHandle = find.byKey(const ValueKey('layout-width-handle'));
    await tester.ensureVisible(widthHandle);
    await tester.pumpAndSettle();
    await tester.drag(widthHandle, const Offset(-600, 0));
    await tester.pumpAndSettle();
    expect(
      tester.widget<Slider>(find.byKey(const ValueKey('parent-width'))).value,
      0.4,
    );
    expect(
      tester.getTopLeft(_item('C')).dy,
      greaterThan(tester.getTopLeft(_item('A')).dy),
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('constraint-parent'))).height,
      240,
    );
    final reset = find.byKey(const ValueKey('reset-layout'));
    await tester.ensureVisible(reset);
    await tester.tap(reset);
    await tester.pumpAndSettle();
    expect(
      tester.getSize(find.byKey(const ValueKey('constraint-parent'))).height,
      160,
    );
    expect(tester.takeException(), isNull);
  });

  for (final reducedMotion in [false, true]) {
    testWidgets('layout transition respects reduced motion: $reducedMotion', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(disableAnimations: reducedMotion),
            child: child!,
          ),
          home: const ConstraintLayoutEntry(),
        ),
      );
      final animation = find.byKey(const ValueKey('layout-size-transition'));
      final initialHeight = tester.getSize(animation).height;
      final chip = find.widgetWithText(ChoiceChip, 'Column');
      await tester.ensureVisible(chip);
      await tester.tap(chip);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final intermediateHeight = tester.getSize(animation).height;
      await tester.pumpAndSettle();
      final finalHeight = tester.getSize(animation).height;
      expect(finalHeight, greaterThan(initialHeight));
      if (reducedMotion) {
        expect(intermediateHeight, finalHeight);
      } else {
        expect(intermediateHeight, greaterThan(initialHeight));
        expect(intermediateHeight, lessThan(finalHeight));
      }
      expect(tester.takeException(), isNull);
    });
  }

  test('module is registered in basic with an unrestricted stable route', () {
    final module = moduleManifest.singleWhere(
      (entry) => entry.path == '/constraint-layout',
    );
    expect(module.category, ModuleCategory.basic);
    expect(module.platformSupport.excludedPlatforms, isEmpty);
    expect(module.title, '约束与声明式布局');
  });

  testWidgets(
    'loose constraints clamp requested size and tight constraints fill parent',
    (tester) async {
      await _mount(tester, const Size(800, 1000));
      final child = find.byKey(const ValueKey('constrained-child'));
      expect(tester.getSize(child), const Size(120, 80));

      _changeSlider(tester, 'parent-width', 0.4);
      _changeSlider(tester, 'requested-width', 360);
      _changeSlider(tester, 'requested-height', 200);
      await tester.pump();
      final looseSize = tester.getSize(child);
      expect(looseSize.width, lessThan(360));
      expect(looseSize.height, 160);

      _changeSlider(tester, 'requested-width', 60);
      _changeSlider(tester, 'requested-height', 40);
      await tester.pump();
      expect(tester.getSize(child), const Size(60, 40));
      await _choose(tester, '紧约束');
      expect(tester.getSize(child), looseSize);
      expect(
        find.text('子组件实际尺寸\n${looseSize.width.round()} × 160 dp'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('declared layout changes positions while preserving data', (
    tester,
  ) async {
    await _mount(tester, const Size(800, 1200));
    expect(tester.getTopLeft(_item('A')).dy, tester.getTopLeft(_item('B')).dy);
    expect(tester.getSize(_item('A')).width, tester.getSize(_item('B')).width);

    await _choose(tester, 'Column');
    expect(tester.getTopLeft(_item('A')).dx, tester.getTopLeft(_item('B')).dx);
    expect(
      tester.getTopLeft(_item('B')).dy,
      greaterThan(tester.getTopLeft(_item('A')).dy),
    );

    await _choose(tester, 'Wrap');
    expect(tester.getSize(_item('A')).width, 96);
    expect(tester.getTopLeft(_item('A')).dy, tester.getTopLeft(_item('C')).dy);
    _changeSlider(tester, 'parent-width', 0.4);
    await tester.pump();
    expect(
      tester.getTopLeft(_item('C')).dy,
      greaterThan(tester.getTopLeft(_item('A')).dy),
    );
    for (final label in ['A', 'B', 'C']) {
      expect(_item(label), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'slider gestures update dimensions and reset restores experiment',
    (tester) async {
      await _mount(tester, const Size(800, 1000));
      final slider = find.byKey(const ValueKey('requested-width'));
      await tester.drag(slider, const Offset(200, 0));
      await tester.pumpAndSettle();
      expect(
        tester.getSize(find.byKey(const ValueKey('constrained-child'))).width,
        greaterThan(120),
      );
      await _choose(tester, '紧约束');
      await _choose(tester, 'Column');
      final reset = find.byKey(const ValueKey('reset-layout'));
      await tester.ensureVisible(reset);
      await tester.tap(reset);
      await tester.pumpAndSettle();
      expect(
        tester.getSize(find.byKey(const ValueKey('constrained-child'))),
        const Size(120, 80),
      );
      expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Row'))
            .selected,
        isTrue,
      );
      expect(
        tester.widget<Slider>(find.byKey(const ValueKey('parent-width'))).value,
        1,
      );
    },
  );

  for (final width in [320.0, 600.0, 1200.0]) {
    testWidgets('all modes fit ${width.round()}dp with enlarged text', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1.5)),
            child: child!,
          ),
          home: const ConstraintLayoutEntry(),
        ),
      );
      _changeSlider(tester, 'parent-width', 0.4);
      for (final mode in ['Row', 'Column', 'Wrap']) {
        await _choose(tester, mode);
        expect(tester.takeException(), isNull);
      }
      await _choose(tester, '紧约束');
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('💪 练习任务'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
