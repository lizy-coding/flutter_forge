import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_forge_app/modules/state/local_persistence/services/preferences_service.dart';
import 'package:flutter_forge_app/modules/state/local_persistence/state/persistence_demo_controller.dart';

void main() {
  late PersistenceDemoController controller;

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'local_persistence.count': 42,
      'local_persistence.sound_enabled': false,
      'local_persistence.note_text': '已保存',
    });
    controller = PersistenceDemoController(
      preferences: SharedPreferencesPreferencesService(),
    );
  });

  test('starts unloaded and restores persisted values', () async {
    expect(controller.isLoaded, isFalse);
    await controller.load();

    expect(controller.isLoaded, isTrue);
    expect(controller.count, 42);
    expect(controller.soundEnabled, isFalse);
    expect(controller.noteText, '已保存');
  });

  test('save operations are safe before load', () async {
    await controller.increment();
    expect(controller.count, 0);
    expect(controller.isLoaded, isFalse);
  });

  test('increment persists the updated count', () async {
    await controller.load();
    await controller.increment();

    final preferences = await SharedPreferences.getInstance();
    expect(controller.count, 43);
    expect(preferences.getInt('local_persistence.count'), 43);
  });

  test('clearAll removes values and restores defaults', () async {
    await controller.load();
    await controller.clearAll();

    expect(controller.count, 0);
    expect(controller.soundEnabled, isTrue);
    expect(controller.noteText, isEmpty);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getInt('local_persistence.count'), isNull);
  });
}
