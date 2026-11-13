import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forge_localization/forge_localization.dart';

void main() {
  LocaleController create({
    List<Locale> system = const [],
    Future<void> Function(String)? save,
  }) => LocaleController(
    supportedLocales: const [Locale('zh'), Locale('en')],
    fallbackLocale: const Locale('zh'),
    systemLocales: system,
    save: save,
  );
  test('system priorities, Chinese variants and explicit override', () async {
    final controller = create(
      system: [const Locale('fr'), const Locale('en', 'GB')],
    );
    expect(controller.effectiveLocale, const Locale('en'));
    await controller.setPreference('zh');
    controller.updateSystemLocales([const Locale('en')]);
    expect(controller.effectiveLocale, const Locale('zh'));
    controller.updateSystemLocales([const Locale('zh', 'TW')]);
    await controller.setPreference('system');
    expect(controller.effectiveLocale, const Locale('zh'));
    controller.updateSystemLocales([const Locale('fr')]);
    expect(controller.effectiveLocale, const Locale('zh'));
    controller.dispose();
  });
  test(
    'writes are serialized, failure observable, retry clears failure',
    () async {
      final first = Completer<void>();
      final values = <String>[];
      final controller = create(
        save: (value) async {
          values.add(value);
          if (values.length == 1) await first.future;
          if (values.length == 2) throw StateError('disk');
        },
      );
      final a = controller.setPreference('en');
      await Future<void>.delayed(Duration.zero);
      final b = controller.setPreference('zh');
      expect(values, ['en']);
      expect(controller.effectiveLocale, const Locale('zh'));
      first.complete();
      await a;
      await b;
      expect(values, ['en', 'zh']);
      expect(controller.saveError, isNotNull);
      await controller.setPreference('zh');
      expect(controller.saveError, isNull);
      controller.applyRemotePreference('en');
      expect(values.length, 3);
      controller.dispose();
    },
  );
}
