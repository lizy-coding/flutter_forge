import 'package:flutter/material.dart';
import 'package:flutter_forge_app/app/module_home_page.dart';
import 'package:flutter_forge_app/app/router/app_route_table.dart';
import 'package:flutter_forge_app/module_registry/app_platform_snapshot.dart';
import 'package:flutter_forge_app/module_registry/module_category.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/support/automation/app_fixture.dart';
import '../test/support/automation/interactions.dart';
import '../test/support/automation/platform_adapter.dart';

// Extended traversal is explicit: it may start native, network or GPU modules.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final platform = AppPlatformSnapshot.detect();
  testWidgets('extended catalog opens every admitted module', (tester) async {
    await withApp(tester, platform, (app) async {
      final adapter = PlatformAdapter(platform);
      for (final module in AppRouteTable.modules.where(
        (m) => m.isSupportedOn(platform),
      )) {
        await app.go(tester, '/category/${module.category.name}');
        await adapter.openModule(tester, module);
        await pumpFrames(tester, const Duration(milliseconds: 600));
        expectNoFlutterErrors(
          tester,
          '${platform.platform.name}:${module.path}',
        );
      }
    });
  });
  testWidgets('extended mobile drawer visits all categories twice', (
    tester,
  ) async {
    await withApp(tester, platform, (app) async {
      ScaffoldState shell() => tester.state<ScaffoldState>(
        find.byKey(const ValueKey('adaptive-app-shell')),
      );

      Future<void> openDrawer() async {
        await tester.tap(find.byTooltip('Open navigation menu'));
        await tester.pumpAndSettle();
        expect(shell().isDrawerOpen, isTrue);
        expect(
          find.descendant(
            of: find.byType(NavigationDrawer),
            matching: find.byKey(const ValueKey('category-drawer:home')),
          ),
          findsOneWidget,
        );
      }

      for (final category in ModuleCategory.values) {
        final destination = find.descendant(
          of: find.byType(NavigationDrawer),
          matching: find.byKey(ValueKey('category-drawer:${category.name}')),
        );
        for (var visit = 0; visit < 2; visit++) {
          await openDrawer();
          await tester.ensureVisible(destination);
          await tester.tap(destination);
          await tester.pumpAndSettle();
          expect(shell().isDrawerOpen, isFalse);
          expect(app.location, '/category/${category.name}');
          expect(find.byType(CategoryHomePage), findsOneWidget);
          expect(
            find.byKey(ValueKey('category-page:${category.name}')),
            findsOneWidget,
          );
        }
      }

      // Exercise the framework's system-back dispatch while the drawer is open.
      await openDrawer();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(shell().isDrawerOpen, isFalse);
      expect(app.location, '/category/platform');
      expect(
        find.byKey(const ValueKey('category-page:platform')),
        findsOneWidget,
      );

      await openDrawer();
      await tester.tap(find.byKey(const ValueKey('category-drawer:home')));
      await tester.pumpAndSettle();
      expect(shell().isDrawerOpen, isFalse);
      expect(app.location, '/');
      expect(find.byKey(const ValueKey('learning-home')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }, skip: platform.hostFamily != AppHostFamily.mobile);
}
