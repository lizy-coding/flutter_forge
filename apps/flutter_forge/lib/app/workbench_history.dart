import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WorkbenchHistory extends ChangeNotifier {
  WorkbenchHistory({SharedPreferences? preferences})
    : _preferences = preferences {
    _recent.addAll(preferences?.getStringList(preferenceKey) ?? const []);
  }

  static const preferenceKey = 'flutter_forge.workbench.recent';
  final SharedPreferences? _preferences;
  final List<String> _recent = [];
  List<String> get recent => List.unmodifiable(_recent);
  Future<void> _pendingWrite = Future.value();

  void record(String path) {
    if (_recent.isNotEmpty && _recent.first == path) return;
    _recent.remove(path);
    _recent.insert(0, path);
    if (_recent.length > 8) _recent.removeRange(8, _recent.length);
    final snapshot = List<String>.of(_recent);
    _pendingWrite = _pendingWrite
        .then((_) async {
          await _preferences?.setStringList(preferenceKey, snapshot);
        })
        .catchError((Object error) {
          debugPrint('Recent module preference could not be saved: $error');
        });
    unawaited(_pendingWrite);
    notifyListeners();
  }
}

class WorkbenchHistoryScope extends InheritedNotifier<WorkbenchHistory> {
  const WorkbenchHistoryScope({
    super.key,
    required WorkbenchHistory history,
    required super.child,
  }) : super(notifier: history);

  static WorkbenchHistory? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<WorkbenchHistoryScope>()
      ?.notifier;
}
