import 'package:flutter_forge_app/app/app.dart';
import 'package:flutter_forge_app/app/app_platform_provider.dart';
import 'package:flutter_forge_app/app/router/app_router.dart';
import 'package:flutter_forge_app/app/theme/app_theme_controller.dart';
import 'package:flutter_forge_app/app/unsupported_module_page.dart';
import 'package:flutter_forge_app/module_registry/app_platform_snapshot.dart';
import 'package:flutter_forge_app/modules/platform/network_diagnostics/module_entry.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final platform in AppTargetPlatform.values.where(
    (p) => [
      AppTargetPlatform.macOS,
      AppTargetPlatform.windows,
      AppTargetPlatform.android,
      AppTargetPlatform.iOS,
      AppTargetPlatform.web,
    ].contains(p),
  )) {
    testWidgets('stable diagnostic route on ${platform.name}', (tester) async {
      final snapshot = AppPlatformSnapshot(platform: platform);
      final router = AppRouter.create(snapshot)..go('/network-diagnostics');
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [appPlatformProvider.overrideWithValue(snapshot)],
          child: App(
            router: router,
            themeController: AppThemeController.forTesting(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final supported =
          platform == AppTargetPlatform.macOS ||
          platform == AppTargetPlatform.windows;
      expect(
        find.byType(NetworkDiagnosticsEntry),
        supported ? findsOneWidget : findsNothing,
      );
      expect(
        find.byType(UnsupportedModulePage),
        supported ? findsNothing : findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
