import 'package:flutter/widgets.dart';

/// Resolves language preferences without owning persistence or window transport.
class LocaleController extends ChangeNotifier {
  LocaleController({
    required this.supportedLocales,
    required this.fallbackLocale,
    List<Locale> systemLocales = const [],
    String preference = 'system',
    this.save,
    this.loadError,
  }) : _systemLocales = List.of(systemLocales),
       _preference = preference {
    if (supportedLocales.isEmpty ||
        !supportedLocales.contains(fallbackLocale)) {
      throw ArgumentError('Fallback must be a supported locale');
    }
    _preference = _normalize(preference);
  }

  final List<Locale> supportedLocales;
  final Locale fallbackLocale;
  final Future<void> Function(String preference)? save;
  List<Locale> _systemLocales;
  String _preference;
  Future<void> _pending = Future.value();
  int _revision = 0;
  bool _disposed = false;
  Object? saveError;
  Object? loadError;

  String get preference => _preference;
  Locale get effectiveLocale {
    final candidates = _preference == 'system'
        ? _systemLocales
        : [Locale(_preference)];
    for (final candidate in candidates) {
      for (final supported in supportedLocales) {
        if (candidate.languageCode == supported.languageCode) return supported;
      }
    }
    return fallbackLocale;
  }

  String _normalize(String value) =>
      value == 'system' ||
          supportedLocales.any((locale) => locale.languageCode == value)
      ? value
      : 'system';

  void updateSystemLocales(List<Locale> locales) {
    _systemLocales = List.of(locales);
    if (!_disposed) notifyListeners();
  }

  Future<void> setPreference(String value) {
    _preference = _normalize(value);
    saveError = null;
    final revision = ++_revision;
    final selected = _preference;
    notifyListeners();
    _pending = _pending.then((_) async {
      try {
        await save?.call(selected);
        if (revision == _revision) {
          saveError = null;
          loadError = null;
        }
      } catch (error) {
        if (revision == _revision) saveError = error;
      }
      if (!_disposed && revision == _revision) notifyListeners();
    });
    return _pending;
  }

  /// Applies a host-provided preference without writing or broadcasting it again.
  void applyRemotePreference(String value) {
    _preference = _normalize(value);
    ++_revision;
    saveError = null;
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

class LocaleScope extends InheritedNotifier<LocaleController> {
  const LocaleScope({
    super.key,
    required LocaleController controller,
    required super.child,
  }) : super(notifier: controller);

  static LocaleController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LocaleScope>()?.notifier;

  static LocaleController of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LocaleScope>()!.notifier!;
}
