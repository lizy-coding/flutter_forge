import 'package:flutter/material.dart';
import 'package:flutter_forge_app/modules/state/local_persistence/module_root.dart';
import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_forge_app/modules/state/local_persistence/services/preferences_service.dart';
import 'package:flutter_forge_app/modules/state/local_persistence/state/persistence_demo_controller.dart';

class Store implements PreferencesService {
  final values = <String, Object>{'theme': 'keep'};
  bool failRead = false;
  bool failWrite = false;
  bool throwWrite = false;
  String? failRemove;
  Completer<void>? block;
  @override
  Future<int?> getInt(String key) async {
    if (failRead) throw StateError('read');
    return values[key] as int?;
  }

  @override
  Future<bool?> getBool(String key) async => values[key] as bool?;
  @override
  Future<String?> getString(String key) async => values[key] as String?;
  Future<bool> write(String key, Object value) async {
    await block?.future;
    if (throwWrite) throw StateError('write');
    if (failWrite) return false;
    values[key] = value;
    return true;
  }

  @override
  Future<bool> setInt(String key, int value) => write(key, value);
  @override
  Future<bool> setBool(String key, bool value) => write(key, value);
  @override
  Future<bool> setString(String key, String value) => write(key, value);
  @override
  Future<bool> remove(String key) async {
    if (key == failRemove) return false;
    values.remove(key);
    return true;
  }

  @override
  Future<bool> clear() async =>
      throw StateError('Must not clear unrelated preferences');
}

void main() {
  testWidgets('read retry and partial clear failure are visible in the demo', (
    tester,
  ) async {
    final store = Store()..failRead = true;
    await tester.pumpWidget(MaterialApp(home: HomePage(preferences: store)));
    await tester.pumpAndSettle();
    expect(find.text('读取本演示数据失败，请重试。'), findsOneWidget);
    store.failRead = false;
    await tester.tap(find.text('重试'));
    await tester.pumpAndSettle();
    store.failRemove = 'local_persistence.note_text';
    final clear = find.widgetWithText(OutlinedButton, '清除本演示数据');
    await tester.ensureVisible(clear);
    await tester.pumpAndSettle();
    await tester.tap(clear);
    await tester.pumpAndSettle();
    expect(find.text('清除未完成，请重试。'), findsOneWidget);
    expect(find.text('已清除本演示数据'), findsNothing);
    expect(store.values['theme'], 'keep');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  test(
    'load retries and failed saves remain observable without poisoning queue',
    () async {
      final store = Store()..failRead = true;
      final controller = PersistenceDemoController(preferences: store);
      await controller.load();
      expect(controller.failure, PersistenceFailure.load);
      expect(controller.isLoaded, false);
      store.failRead = false;
      await controller.load();
      expect(controller.isLoaded, true);
      store.failWrite = true;
      await controller.increment();
      expect(controller.failure, PersistenceFailure.save);
      store.failWrite = false;
      store.throwWrite = true;
      await controller.increment();
      expect(controller.failure, PersistenceFailure.save);
      store.throwWrite = false;
      await controller.increment();
      expect(controller.failure, isNull);
      expect(store.values['local_persistence.count'], 3);
      controller.dispose();
    },
  );
  test('clear waits for earlier writes and preserves unrelated keys', () async {
    final store = Store();
    final controller = PersistenceDemoController(preferences: store);
    await controller.load();
    final block = Completer<void>();
    store.block = block;
    final save = controller.updateNoteText('old');
    final clear = controller.clearAll();
    block.complete();
    await save;
    expect(await clear, true);
    expect(store.values, {'theme': 'keep'});
    expect(controller.noteText, '');
    controller.dispose();
  });
  test(
    'partial clear failure reloads remaining values rather than reporting success',
    () async {
      final store = Store()
        ..values['local_persistence.note_text'] = 'keep note'
        ..failRemove = 'local_persistence.note_text';
      final controller = PersistenceDemoController(preferences: store);
      await controller.load();
      expect(await controller.clearAll(), false);
      expect(controller.failure, PersistenceFailure.clear);
      expect(controller.noteText, 'keep note');
      store.failRemove = null;
      expect(await controller.clearAll(), true);
      expect(controller.failure, isNull);
      controller.dispose();
    },
  );
}
