import 'package:flutter/material.dart';
import 'package:flutter_forge_app/modules/state/flutter_ioc/model/counter_model.dart';
import 'package:flutter_forge_app/modules/state/flutter_ioc/module_root.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  group('CounterModel', () {
    test('increment updates count and notifies listeners', () {
      final model = CounterModel();
      addTearDown(model.dispose);
      var notifications = 0;
      model.addListener(() => notifications++);

      model.increment();
      expect(model.count, 1);
      expect(notifications, 1);
    });

    test('rename notifies and keeps count', () {
      final model = CounterModel(count: 7);
      addTearDown(model.dispose);
      model.setName('demo');
      expect(model.name, 'demo');
      expect(model.count, 7);
    });

    test('json round-trip preserves state', () {
      final model = CounterModel(count: 5, name: 'A');
      addTearDown(model.dispose);
      final restored = CounterModel.fromJson(model.toJson());
      addTearDown(restored.dispose);
      expect(restored.count, 5);
      expect(restored.name, 'A');
    });

    test('fromMap falls back to defaults for missing fields', () {
      final model = CounterModel.fromMap({});
      addTearDown(model.dispose);
      expect(model.count, 0);
      expect(model.name, 'Default Counter');
    });
  });

  testWidgets('counter screen increments through the provider', (tester) async {
    final model = CounterModel();
    addTearDown(model.dispose);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: model,
        child: const MaterialApp(home: CounterScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Count: 0'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    expect(find.text('Count: 1'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '学习计数器');
    await tester.pumpAndSettle();
    expect(find.text('Name: 学习计数器'), findsOneWidget);
  });
}
