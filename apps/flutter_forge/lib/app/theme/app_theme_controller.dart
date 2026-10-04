import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_theme_selection.dart';

class AppThemeController extends ChangeNotifier {
  AppThemeController._(
    this._selection, {
    SharedPreferences? preferences,
    Future<void> Function(String payload)? onChanged,
  }) : _preferences = preferences,
       _onChanged = onChanged;

  static const preferenceKey = 'flutter_forge.theme_mode';

  final SharedPreferences? _preferences;
  Future<void> Function(String payload)? _onChanged;
  AppThemeSelection _selection;

  AppThemeSelection get selection => _selection;
  AppThemeModePreference get mode => _selection.mode;
  AppThemePalette get palette => _selection.palette;
  ThemeMode get themeMode => _selection.themeMode;

  static Future<AppThemeController> load({
    String? initialSelectionPayload,
    Future<void> Function(String payload)? onChanged,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    final saved = preferences.getString(preferenceKey);
    return AppThemeController._(
      AppThemeSelection.decode(initialSelectionPayload ?? saved),
      preferences: preferences,
      onChanged: onChanged,
    );
  }

  @visibleForTesting
  AppThemeController.forTesting([
    AppThemeSelection selection = const AppThemeSelection(),
  ]) : this._(selection);

  void setChangeHandler(Future<void> Function(String payload)? handler) {
    _onChanged = handler;
  }

  Future<void> setMode(AppThemeModePreference mode) =>
      setSelection(_selection.copyWith(mode: mode));

  Future<void> setPalette(AppThemePalette palette) =>
      setSelection(_selection.copyWith(palette: palette));

  Future<void> setSelection(AppThemeSelection selection) async {
    if (_selection == selection) return;
    _selection = selection;
    notifyListeners();
    final payload = selection.encode();
    await _preferences?.setString(preferenceKey, payload);
    await _onChanged?.call(payload);
  }

  void applyRemoteSelection(String? payload) {
    final selection = AppThemeSelection.decode(payload);
    if (_selection == selection) return;
    _selection = selection;
    notifyListeners();
  }
}

class AppThemeScope extends InheritedNotifier<AppThemeController> {
  const AppThemeScope({
    super.key,
    required AppThemeController controller,
    required super.child,
  }) : super(notifier: controller);

  static AppThemeController of(BuildContext context) {
    final scope = maybeOf(context);
    assert(scope != null, 'AppThemeScope is missing above this context');
    return scope!;
  }

  static AppThemeController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppThemeScope>()?.notifier;
}
