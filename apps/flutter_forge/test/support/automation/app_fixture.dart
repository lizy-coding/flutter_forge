import 'package:flutter/material.dart';
import 'package:flutter_forge_app/app/app.dart';
import 'package:flutter_forge_app/app/app_platform_provider.dart';
import 'package:flutter_forge_app/app/router/app_router.dart';
import 'package:flutter_forge_app/app/theme/app_theme_controller.dart';
import 'package:flutter_forge_app/app/workbench_history.dart';
import 'package:flutter_forge_app/module_registry/app_platform_snapshot.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'interactions.dart';

// Test ownership only: no native plugin mocks and no persistent preferences.
class AppFixture {
  AppFixture(this.platform)
    : router = AppRouter.create(platform),
      theme = AppThemeController.forTesting(),
      history = WorkbenchHistory();

  final AppPlatformSnapshot platform;
  final GoRouter router;
  final AppThemeController theme;
  final WorkbenchHistory history;
  String get location => router.routeInformationProvider.value.uri.path;

  Future<void> mount(WidgetTester tester) async {
    await tester.pumpWidget(
      WorkbenchHistoryScope(
        history: history,
        child: ProviderScope(
          overrides: [appPlatformProvider.overrideWithValue(platform)],
          child: App(router: router, themeController: theme),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> go(WidgetTester tester, String path) async {
    router.go(path);
    await waitForCondition(
      tester,
      () => location == path,
      reason: 'Route did not become $path',
    );
    await pumpFrames(tester, const Duration(milliseconds: 350));
  }

  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    router.dispose();
    theme.dispose();
    history.dispose();
  }
}

Future<void> withApp(
  WidgetTester tester,
  AppPlatformSnapshot platform,
  Future<void> Function(AppFixture app) run,
) async {
  final app = AppFixture(platform);
  try {
    await app.mount(tester);
    await run(app);
  } finally {
    await app.close(tester);
  }
}
