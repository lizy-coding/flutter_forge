import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_forge_app/app/desktop_window_host.dart';
import 'package:flutter_forge_app/app/theme/app_theme_selection.dart';
import 'package:flutter_forge_app/app/theme/forge_glass.dart';
import 'package:flutter_forge_app/app/theme/forge_theme_tokens.dart';
import 'package:flutter_forge_app/module_registry/app_platform_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../test/support/desktop_material_contract.dart';
import '../test/support/automation/app_fixture.dart';
import '../test/support/automation/interactions.dart';
import '../test/support/automation/platform_adapter.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'real desktop material, teaching, appearance and fullscreen round trip',
    (tester) async {
      final platform = AppPlatformSnapshot.detect();
      await withApp(tester, platform, (app) async {
        final router = app.router;
        final theme = app.theme;
        try {
          await tester.pumpAndSettle();
          final initial = await _state();
          debugPrint('NATIVE_ACCEPTANCE initial=$initial');
          expectDesktopMaterial(initial, macOS: Platform.isMacOS);
          if (Platform.isMacOS) {
            expect(
              initial['inputSurfaceOpaque'],
              isTrue,
              reason: 'Native material must not make the window click-through',
            );
            expect(initial['materialInsideContent'], isTrue);
            expect(initial['materialIgnoresPointer'], isTrue);
          }
          expect(find.byKey(const ValueKey('workbench-home')), findsOneWidget);

          router.go('/category/basic');
          await tester.pumpAndSettle();
          expect(
            tester
                .widget<ForgeSurfaceScope>(find.byType(ForgeSurfaceScope))
                .teaching,
            isFalse,
          );
          await PlatformAdapter(
            platform,
          ).search(tester, moduleByPath('/tree-state'), query: 'RenderObject');
          expect(router.routeInformationProvider.value.uri.path, '/tree-state');
          expect(
            tester
                .element(find.byKey(const ValueKey('desktop-workbench-shell')))
                .forgeColors
                .glass,
            isFalse,
          );

          await theme.setPalette(AppThemePalette.graphiteForge);
          await tester.pumpAndSettle();
          expect((await _state())['materialActive'], isFalse);
          expect(router.routeInformationProvider.value.uri.path, '/tree-state');
          await theme.setSelection(
            const AppThemeSelection(mode: AppThemeModePreference.dark),
          );
          await tester.pumpAndSettle();
          expectDesktopMaterial(await _state(), macOS: Platform.isMacOS);

          await tester.tap(find.byKey(const ValueKey('workbench-back')));
          await tester.pumpAndSettle();
          expect(find.text('RenderObject'), findsOneWidget);
          await tester.tap(find.byTooltip('关闭快速打开'));
          await tester.pumpAndSettle();
          expect(
            router.routeInformationProvider.value.uri.path,
            '/category/basic',
          );

          await tester.tap(
            find.byKey(const ValueKey('window:toggleFullscreen')),
          );
          await _waitFullscreen(tester, true);
          await tester.tap(
            find.byKey(const ValueKey('window:toggleFullscreen')),
          );
          await _waitFullscreen(tester, false);
          expect(tester.takeException(), isNull);
          debugPrint(
            'NATIVE_ACCEPTANCE PASS material_teaching_theme_search_return_fullscreen',
          );
        } finally {
          if ((await _state())['fullscreen'] == true) {
            await DesktopWindowHost.channel.invokeMethod<void>(
              'toggleFullscreen',
            );
            await _waitFullscreen(tester, false);
          }
        }
      });
    },
    skip: !Platform.isMacOS && !Platform.isWindows,
  );
}

Future<Map<dynamic, dynamic>> _state() async =>
    await DesktopWindowHost.channel.invokeMapMethod('getState') ?? {};

Future<void> _waitFullscreen(WidgetTester tester, bool expected) async {
  await waitForCondition(
    tester,
    () async => (await _state())['fullscreen'] == expected,
    reason: 'Native fullscreen did not become $expected',
  );
  await pumpFrames(tester, const Duration(milliseconds: 500));
}
