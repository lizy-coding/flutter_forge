import 'package:flutter/foundation.dart';

import '../services/preferences_service.dart';

class PersistenceDemoController extends ChangeNotifier {
  PersistenceDemoController({required PreferencesService preferences})
    : _preferences = preferences;

  static const _countKey = 'local_persistence.count';
  static const _soundEnabledKey = 'local_persistence.sound_enabled';
  static const _noteTextKey = 'local_persistence.note_text';

  final PreferencesService _preferences;

  int count = 0;
  bool soundEnabled = true;
  String noteText = '';
  bool isLoaded = false;
  bool _loadStarted = false;

  Future<void> load() async {
    if (_loadStarted) return;
    _loadStarted = true;
    count = await _preferences.getInt(_countKey) ?? 0;
    soundEnabled = await _preferences.getBool(_soundEnabledKey) ?? true;
    noteText = await _preferences.getString(_noteTextKey) ?? '';
    isLoaded = true;
    notifyListeners();
  }

  Future<void> increment() async {
    if (!isLoaded) return;
    count++;
    await _preferences.setInt(_countKey, count);
    notifyListeners();
  }

  Future<void> decrement() async {
    if (!isLoaded) return;
    count--;
    await _preferences.setInt(_countKey, count);
    notifyListeners();
  }

  Future<void> reset() async {
    if (!isLoaded) return;
    count = 0;
    await _preferences.setInt(_countKey, count);
    notifyListeners();
  }

  Future<void> updateSoundEnabled(bool value) async {
    if (!isLoaded) return;
    soundEnabled = value;
    await _preferences.setBool(_soundEnabledKey, value);
    notifyListeners();
  }

  Future<void> updateNoteText(String value) async {
    if (!isLoaded) return;
    noteText = value;
    await _preferences.setString(_noteTextKey, value);
    notifyListeners();
  }

  Future<void> clearAll() async {
    if (!isLoaded) return;
    await _preferences.remove(_countKey);
    await _preferences.remove(_soundEnabledKey);
    await _preferences.remove(_noteTextKey);
    count = 0;
    soundEnabled = true;
    noteText = '';
    notifyListeners();
  }
}
