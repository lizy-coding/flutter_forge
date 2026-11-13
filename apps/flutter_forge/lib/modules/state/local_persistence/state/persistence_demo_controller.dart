import 'package:flutter/foundation.dart';
import '../services/preferences_service.dart';

enum PersistenceFailure { load, save, clear }

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
  bool _isLoading = false;
  bool _disposed = false;
  bool _isClearing = false;
  bool get isClearing => _isClearing;
  int _pending = 0;
  Future<void> _tail = Future.value();
  final Set<String> _failedWrites = {};
  PersistenceFailure? failure;
  int get count => _count;
  bool get soundEnabled => _soundEnabled;
  String get noteText => _noteText;
  bool get isLoaded => _isLoaded;
  bool get isLoading => _isLoading;
  bool get isBusy => _pending > 0;
  void _emit() {
    if (!_disposed) notifyListeners();
  }

  Future<void> _enqueue(Future<void> Function() action) {
    _pending++;
    _emit();
    final work = _tail.then((_) async {
      try {
        await action();
      } finally {
        _pending--;
        _emit();
      }
    });
    _tail = work;
    return work;
  }

  Future<void> _restore() async {
    final count = await _preferences.getInt(_countKey) ?? 0;
    final sound = await _preferences.getBool(_soundEnabledKey) ?? true;
    final note = await _preferences.getString(_noteTextKey) ?? '';
    _count = count;
    _soundEnabled = sound;
    _noteText = note;
  }

  Future<void> load() async {
    if (_isLoaded || _isLoading) return;
    _isLoading = true;
    await _enqueue(() async {
      try {
        await _restore();
        _isLoaded = true;
        _failedWrites.clear();
        failure = null;
      } catch (_) {
        failure = PersistenceFailure.load;
      } finally {
        _isLoading = false;
      }
    });
  }

  Future<void> _save(String key, Future<bool> Function() write) =>
      _enqueue(() async {
        try {
          if (await write()) {
            _failedWrites.remove(key);
          } else {
            _failedWrites.add(key);
          }
        } catch (_) {
          _failedWrites.add(key);
        }
        failure = _failedWrites.isEmpty ? null : PersistenceFailure.save;
      });

  Future<void> _setCount(int value) async {
    if (!_isLoaded || _isClearing) return;
    _count = value;
    await _save(_countKey, () => _preferences.setInt(_countKey, value));
  }

  Future<void> increment() => _setCount(_count + 1);
  Future<void> decrement() => _setCount(_count - 1);
  Future<void> reset() => _setCount(0);
  Future<void> updateSoundEnabled(bool value) async {
    if (!_isLoaded || _isClearing) return;
    _soundEnabled = value;
    await _save(
      _soundEnabledKey,
      () => _preferences.setBool(_soundEnabledKey, value),
    );
  }

  Future<void> updateNoteText(String value) async {
    if (!_isLoaded || _isClearing) return;
    _noteText = value;
    await _save(
      _noteTextKey,
      () => _preferences.setString(_noteTextKey, value),
    );
  }

  Future<bool> clearAll() async {
    if (!_isLoaded || _isClearing) return false;
    _isClearing = true;
    var success = true;
    await _enqueue(() async {
      for (final key in [_countKey, _soundEnabledKey, _noteTextKey]) {
        try {
          if (!await _preferences.remove(key)) success = false;
        } catch (_) {
          success = false;
        }
      }
      try {
        await _restore();
      } catch (_) {
        success = false;
      }
      _failedWrites.clear();
      failure = success ? null : PersistenceFailure.clear;
      _isClearing = false;
    });
    return success;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
