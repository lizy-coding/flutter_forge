import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_forge_app/modules/state/local_persistence/module_root.dart';
import 'package:flutter_forge_app/modules/state/local_persistence/services/preferences_service.dart';

void main() {
  testWidgets('shows loading while preferences are being restored', (
    tester,
  ) async {
    final preferences = BlockingPreferencesService();
    await tester.pumpWidget(
      MaterialApp(home: HomePage(preferences: preferences)),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    preferences.complete();
    await tester.pumpAndSettle();
    expect(find.text('本地持久化'), findsOneWidget);
    expect(find.text('计数器：0'), findsOneWidget);
  });
}

class BlockingPreferencesService implements PreferencesService {
  final Completer<void> _loadGate = Completer<void>();

  void complete() => _loadGate.complete();

  Future<void> get _ready => _loadGate.future;

  @override
  Future<bool> clear() async {
    await _ready;
    return true;
  }

  @override
  Future<bool?> getBool(String key) async {
    await _ready;
    return null;
  }

  @override
  Future<int?> getInt(String key) async {
    await _ready;
    return null;
  }

  @override
  Future<String?> getString(String key) async {
    await _ready;
    return null;
  }

  @override
  Future<bool> remove(String key) async {
    await _ready;
    return true;
  }

  @override
  Future<bool> setBool(String key, bool value) async {
    await _ready;
    return true;
  }

  @override
  Future<bool> setInt(String key, int value) async {
    await _ready;
    return true;
  }

  @override
  Future<bool> setString(String key, String value) async {
    await _ready;
    return true;
  }
}
