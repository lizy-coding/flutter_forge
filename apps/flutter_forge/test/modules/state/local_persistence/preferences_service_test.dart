import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_forge_app/modules/state/local_persistence/services/preferences_service.dart';

void main() {
  late PreferencesService service;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    service = SharedPreferencesPreferencesService();
  });

  test('reads and writes an int', () async {
    expect(await service.getInt('count'), isNull);
    expect(await service.setInt('count', 42), isTrue);
    expect(await service.getInt('count'), 42);
  });

  test('reads and writes a bool', () async {
    expect(await service.setBool('sound', false), isTrue);
    expect(await service.getBool('sound'), isFalse);
  });

  test('reads and writes a string', () async {
    expect(await service.setString('note', 'hello'), isTrue);
    expect(await service.getString('note'), 'hello');
  });

  test('removes a key', () async {
    await service.setString('note', 'hello');
    expect(await service.remove('note'), isTrue);
    expect(await service.getString('note'), isNull);
  });

  test('clears all keys', () async {
    await service.setInt('count', 1);
    await service.setBool('sound', true);
    expect(await service.clear(), isTrue);
    expect(await service.getInt('count'), isNull);
    expect(await service.getBool('sound'), isNull);
  });
}
