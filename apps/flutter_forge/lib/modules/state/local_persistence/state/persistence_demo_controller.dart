import 'package:flutter/foundation.dart';

import '../services/preferences_service.dart';

class PersistenceDemoController extends ChangeNotifier {
  PersistenceDemoController({required PreferencesService preferences})
    : _preferences = preferences;

  static const _countKey = 'local_persistence.count';
  static const _soundEnabledKey = 'local_persistence.sound_enabled';
  static const _noteTextKey = 'local_persistence.note_text';

  final PreferencesService _preferences;

  int _count = 0;
  bool _soundEnabled = true;
  String _noteText = '';
  bool _isLoaded = false;
  bool _loadStarted = false;

  int get count => _count;

  bool get soundEnabled => _soundEnabled;

  String get noteText => _noteText;

  bool get isLoaded => _isLoaded;

  Future<void> load() async {
    if (_loadStarted) return;
    _loadStarted = true;
    _count = await _preferences.getInt(_countKey) ?? 0;
    _soundEnabled = await _preferences.getBool(_soundEnabledKey) ?? true;
    _noteText = await _preferences.getString(_noteTextKey) ?? '';
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> increment() async {
    if (!isLoaded) return;
    _count++;
    await _preferences.setInt(_countKey, _count);
    notifyListeners();
  }

  Future<void> decrement() async {
    if (!isLoaded) return;
    _count--;
    await _preferences.setInt(_countKey, _count);
    notifyListeners();
  }

  Future<void> reset() async {
    if (!isLoaded) return;
    _count = 0;
    await _preferences.setInt(_countKey, _count);
    notifyListeners();
  }

  Future<void> updateSoundEnabled(bool value) async {
    if (!isLoaded) return;
    _soundEnabled = value;
    await _preferences.setBool(_soundEnabledKey, value);
    notifyListeners();
  }

  Future<void> updateNoteText(String value) async {
    if (!isLoaded) return;
    _noteText = value;
    await _preferences.setString(_noteTextKey, value);
    notifyListeners();
  }

  Future<void> clearAll() async {
    if (!isLoaded) return;
    await _preferences.remove(_countKey);
    await _preferences.remove(_soundEnabledKey);
    await _preferences.remove(_noteTextKey);
    _count = 0;
    _soundEnabled = true;
    _noteText = '';
    notifyListeners();
  }
}
