import 'package:flutter/material.dart';
import 'package:forge_localization/forge_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLocaleHost extends StatefulWidget {
  const AppLocaleHost({
    super.key,
    required this.controller,
    required this.child,
  });
  final LocaleController controller;
  final Widget child;
  static const preferenceKey = 'flutter_forge.locale';

  static Future<LocaleController> load({
    String? initialPreference,
    Future<void> Function(String)? persist,
    Future<void> Function(String)? onSaved,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    String preference = initialPreference ?? 'system';
    Object? loadError;
    if (initialPreference == null) {
      try {
        preference = preferences.getString(preferenceKey) ?? 'system';
      } catch (error) {
        loadError = error;
      }
    }
    return LocaleController(
      supportedLocales: const [Locale('zh'), Locale('en')],
      fallbackLocale: const Locale('zh'),
      systemLocales: WidgetsBinding.instance.platformDispatcher.locales,
      preference: preference,
      loadError: loadError,
      save:
          persist ??
          (value) async {
            if (!await preferences.setString(preferenceKey, value)) {
              throw StateError('Locale preference was not saved');
            }
            await onSaved?.call(value);
          },
    );
  }

  @override
  State<AppLocaleHost> createState() => _AppLocaleHostState();
}

class _AppLocaleHostState extends State<AppLocaleHost>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeLocales(List<Locale>? locales) =>
      widget.controller.updateSystemLocales(locales ?? []);

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      LocaleScope(controller: widget.controller, child: widget.child);
}
