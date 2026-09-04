// 教学用途：用抽象接口隔离 shared_preferences，便于依赖注入和测试替身。
import 'package:shared_preferences/shared_preferences.dart';

abstract class PreferencesService {
  Future<int?> getInt(String key);
  Future<bool?> getBool(String key);
  Future<String?> getString(String key);
  Future<bool> setInt(String key, int value);
  Future<bool> setBool(String key, bool value);
  Future<bool> setString(String key, String value);
  Future<bool> remove(String key);
  Future<bool> clear();
}

class SharedPreferencesPreferencesService implements PreferencesService {
  SharedPreferencesPreferencesService({Future<SharedPreferences>? instance})
    : _instance = instance ?? SharedPreferences.getInstance();

  final Future<SharedPreferences> _instance;

  @override
  Future<int?> getInt(String key) async => (await _instance).getInt(key);

  @override
  Future<bool?> getBool(String key) async => (await _instance).getBool(key);

  @override
  Future<String?> getString(String key) async =>
      (await _instance).getString(key);

  @override
  Future<bool> setInt(String key, int value) async =>
      (await _instance).setInt(key, value);

  @override
  Future<bool> setBool(String key, bool value) async =>
      (await _instance).setBool(key, value);

  @override
  Future<bool> setString(String key, String value) async =>
      (await _instance).setString(key, value);

  @override
  Future<bool> remove(String key) async => (await _instance).remove(key);

  @override
  Future<bool> clear() async => (await _instance).clear();
}
