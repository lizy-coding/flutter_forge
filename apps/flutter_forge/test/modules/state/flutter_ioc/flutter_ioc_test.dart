import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_forge_app/modules/state/flutter_ioc/module_entry.dart';
import 'package:flutter_forge_app/modules/state/flutter_ioc/model/counter_model.dart';
import 'package:flutter_forge_app/modules/state/flutter_ioc/module_root.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  test('module entry is constructible', () {
    expect(const FlutterIocEntry(), isA<Widget>());
  });

  test('counter model notifies on increment and rename', () {
    final model = CounterModel();
    final events = <String>[];
    model.addListener(() => events.add('${model.count}/${model.name}'));
    addTearDown(model.dispose);

    model.increment();
    model.setName('IoC');

    expect(events, ['1/Default Counter', '1/IoC']);
    expect(model.count, 1);
    expect(model.name, 'IoC');
  });

  test('counter model round-trips through map and json', () {
    final model = CounterModel(count: 7, name: '计数器');
    final restored = CounterModel.fromJson(model.toJson());

    expect(restored.count, 7);
    expect(restored.name, '计数器');
    expect(CounterModel.fromMap({}).count, 0, reason: '缺失字段回退默认值');
    expect(CounterModel.fromMap({}).name, 'Default Counter');
    expect(jsonDecode(model.toJson()), isA<Map<dynamic, dynamic>>());
  });

  testWidgets('counter screen increments and renames through Provider', (
    tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<CounterModel>(
        create: (_) => CounterModel(),
        child: const MaterialApp(home: CounterScreen()),
      ),
    );
    expect(find.text('Count: 0'), findsOneWidget);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump();
    expect(find.text('Count: 1'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '依赖注入');
    await tester.pump();
    expect(find.text('Name: 依赖注入'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
