import 'package:shared_preferences/shared_preferences.dart';
import '../support/app_info_fixture.dart';
import 'package:flutter/material.dart';
import 'package:flutter_forge_app/app/app.dart';
import 'package:flutter_forge_app/app/localization/language_selector.dart';
import 'package:flutter_forge_app/app/module_search.dart';
import 'package:flutter_forge_app/app/router/app_router.dart';
import 'package:flutter_forge_app/app/theme/app_theme_controller.dart';
import 'package:flutter_forge_app/app/app_platform_provider.dart';
import 'package:flutter_forge_app/module_registry/app_platform_snapshot.dart';
import 'package:flutter_forge_app/module_registry/module_manifest.dart';
import 'package:flutter_forge_app/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forge_localization/forge_localization.dart';

void main() {
  setUp(useAppInfoFixture);
  LocaleController controller({Future<void> Function(String)? save}) =>
      LocaleController(
        supportedLocales: const [Locale('zh'), Locale('en')],
        fallbackLocale: const Locale('zh'),
        systemLocales: const [Locale('en', 'US')],
        save: save,
      );

  test('English catalog metadata is searchable with stable module paths', () {
    final module = moduleManifest.singleWhere((m) => m.path == '/tree-state');
    expect(matchesModule(module, 'lifecycle'), isTrue);
    expect(matchesModule(module, 'Fundamentals'), isTrue);
    final graphics = moduleManifest.singleWhere(
      (m) => m.path == '/graphics-background',
    );
    expect(matchesModule(graphics, 'Fragment shader'), isTrue);
    expect(matchesModule(module, '三棵树'), isTrue);
    expect(module.path, '/tree-state');
  });

  testWidgets('locale changes keep router and current module mounted', (
    tester,
  ) async {
    const platform = AppPlatformSnapshot(platform: AppTargetPlatform.android);
    final locale = controller();
    final theme = AppThemeController.forTesting();
    final router = AppRouter.create(platform);
    await tester.pumpWidget(
      LocaleScope(
        controller: locale,
        child: ProviderScope(
          overrides: [appPlatformProvider.overrideWithValue(platform)],
          child: App(router: router, themeController: theme),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Explore and learn'), findsOneWidget);
    router.go('/tree-state');
    await tester.pumpAndSettle();
    final before = router.routeInformationProvider.value.uri;
    await locale.setPreference('zh');
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri, before);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    router.dispose();
    theme.dispose();
    locale.dispose();
  });

  testWidgets(
    'Chinese experiments cover nested routes and root dialogs without resetting state',
    (tester) async {
      const platform = AppPlatformSnapshot(platform: AppTargetPlatform.android);
      final locale = controller();
      final theme = AppThemeController.forTesting();
      final router = AppRouter.create(platform);
      await tester.pumpWidget(
        LocaleScope(
          controller: locale,
          child: ProviderScope(
            overrides: [appPlatformProvider.overrideWithValue(platform)],
            child: App(router: router, themeController: theme),
          ),
        ),
      );
      await tester.pumpAndSettle();
      router.go('/tree-state/state_lifecycle');
      await tester.pumpAndSettle();
      expect(find.text('Chinese experiment'), findsOneWidget);
      expect(find.text('🎯 学习目标'), findsOneWidget);
      expect(find.text('🎯 Learning objectives'), findsNothing);
      expect(find.byTooltip('Back'), findsOneWidget);
      await tester.tap(find.text('setState +1'));
      await tester.pumpAndSettle();
      expect(find.text('Counter: 1'), findsOneWidget);
      final lessonContext = tester.element(find.text('setState +1'));
      final dialog = showDialog<void>(
        context: lessonContext,
        builder: (context) => AlertDialog(
          title: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('关闭实验弹窗'),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('取消'), findsOneWidget);
      await tester.tap(find.text('关闭实验弹窗'));
      await tester.pumpAndSettle();
      await dialog;
      final sheet = showModalBottomSheet<void>(
        context: lessonContext,
        builder: (context) =>
            Text(MaterialLocalizations.of(context).cancelButtonLabel),
      );
      await tester.pumpAndSettle();
      expect(find.text('取消'), findsOneWidget);
      Navigator.of(lessonContext).pop();
      await tester.pumpAndSettle();
      await sheet;
      await locale.setPreference('zh');
      await tester.pumpAndSettle();
      await locale.setPreference('en');
      await tester.pumpAndSettle();
      expect(find.text('Counter: 1'), findsOneWidget);
      expect(
        router.routeInformationProvider.value.uri.path,
        '/tree-state/state_lifecycle',
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      router.dispose();
      theme.dispose();
      locale.dispose();
    },
  );

  testWidgets(
    'actual language menu stays on About when selecting English and Chinese',
    (tester) async {
      const platform = AppPlatformSnapshot(platform: AppTargetPlatform.android);
      final locale = controller();
      await locale.setPreference('zh');
      final theme = AppThemeController.forTesting();
      final router = AppRouter.create(platform)..go('/about');
      await tester.pumpWidget(
        LocaleScope(
          controller: locale,
          child: ProviderScope(
            overrides: [appPlatformProvider.overrideWithValue(platform)],
            child: App(router: router, themeController: theme),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('language-selector')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('English').last);
      await tester.pumpAndSettle();
      expect(locale.preference, 'en');
      expect(router.routeInformationProvider.value.uri.path, '/about');
      expect(find.text('About Flutter Forge'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('language-selector')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('简体中文').last);
      await tester.pumpAndSettle();
      expect(locale.preference, 'zh');
      expect(router.routeInformationProvider.value.uri.path, '/about');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      router.dispose();
      theme.dispose();
      locale.dispose();
    },
  );

  testWidgets('popping a Chinese demo restores English category metadata', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    const platform = AppPlatformSnapshot(platform: AppTargetPlatform.android);
    final locale = controller();
    final theme = AppThemeController.forTesting();
    final router = AppRouter.create(platform)..go('/category/state');
    await tester.pumpWidget(
      LocaleScope(
        controller: locale,
        child: ProviderScope(
          overrides: [appPlatformProvider.overrideWithValue(platform)],
          child: App(router: router, themeController: theme),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Architecture and state'), findsOneWidget);
    final opened = router.push<void>('/local-persistence');
    await tester.pumpAndSettle();
    expect(find.text('Chinese experiment'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await opened;
    expect(find.text('Architecture and state'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Local persistence'),
      200,
      scrollable: find
          .descendant(
            of: find.byKey(const ValueKey('category-page:state')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Local persistence'), findsOneWidget);
    expect(find.text('架构与状态'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    router.dispose();
    theme.dispose();
    locale.dispose();
  });

  testWidgets('save failure is visible and retryable in language selector', (
    tester,
  ) async {
    final locale = controller(save: (_) async => throw StateError('disk'));
    await tester.pumpWidget(
      LocaleScope(
        controller: locale,
        child: ListenableBuilder(
          listenable: locale,
          builder: (_, _) => MaterialApp(
            locale: locale.effectiveLocale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(body: LanguageSelector()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await locale.setPreference('en');
    await tester.pumpAndSettle();
    expect(
      find.text('Language preference was not saved. Please try again.'),
      findsOneWidget,
    );
    expect(find.text('Lesson content is in Chinese'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    locale.dispose();
  });
}
