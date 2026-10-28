import 'package:flutter/material.dart';
import 'package:flutter_forge_app/app/router/app_route_table.dart';
import 'package:flutter_forge_app/module_registry/app_platform_snapshot.dart';
import 'package:flutter_forge_app/module_registry/module_category.dart';
import 'package:flutter_forge_app/module_registry/module_entry.dart';
import 'package:flutter_test/flutter_test.dart';

import 'interactions.dart';

// Differences live here; scenarios express the same user intent on each host.
// No per-module platform table: admission still belongs to module_registry.
class PlatformAdapter {
  const PlatformAdapter(this.platform);
  final AppPlatformSnapshot platform;
  bool get desktop => platform.hostFamily == AppHostFamily.desktop;
  Finder get home =>
      find.byKey(ValueKey(desktop ? 'workbench-home' : 'learning-home'));
  Finder get searchField => desktop
      ? find.byKey(const ValueKey('quick-open-query'))
      : find.byType(TextField).last;

  bool hasDrawer(WidgetTester tester) =>
      !desktop &&
      tester
              .widget<Scaffold>(
                find.byKey(const ValueKey('adaptive-app-shell')),
              )
              .drawer !=
          null;

  Future<void> openDrawer(WidgetTester tester) =>
      tapVisible(tester, find.byTooltip('Open navigation menu'));

  Future<void> openCategory(
    WidgetTester tester,
    ModuleCategory category,
  ) async {
    if (hasDrawer(tester)) {
      await openDrawer(tester);
      final destination = find.descendant(
        of: find.byType(NavigationDrawer),
        matching: find.byKey(ValueKey('category-drawer:${category.name}')),
      );
      await tapVisible(tester, destination);
    } else {
      final tile = find.byKey(
        ValueKey(
          '${desktop ? 'workbench' : 'learning'}-category:${category.name}',
        ),
      );
      await tester.scrollUntilVisible(
        tile,
        200,
        scrollable: find
            .descendant(of: home, matching: find.byType(Scrollable))
            .first,
      );
      await tapVisible(tester, tile);
    }
    await waitForWidget(
      tester,
      find.byKey(ValueKey('category-page:${category.name}')),
    );
  }

  Future<void> openModule(WidgetTester tester, ModuleEntry module) async {
    expect(module.isSupportedOn(platform), isTrue, reason: module.path);
    final page = find.byKey(ValueKey('category-page:${module.category.name}'));
    final tile = find.byKey(ValueKey('module:${module.path}'));
    await tester.scrollUntilVisible(
      tile,
      400,
      scrollable: find
          .descendant(of: page, matching: find.byType(Scrollable))
          .first,
    );
    await tapVisible(tester, tile);
    await expectModule(tester, module);
  }

  Future<void> expectModule(WidgetTester tester, ModuleEntry module) async {
    // Verify the registered entry mounted, not an unrelated shell Scaffold.
    final entry = module.builder(
      tester.element(find.byType(MaterialApp).first),
    );
    await waitForWidget(tester, find.byType(entry.runtimeType));
    expectNoFlutterErrors(
      tester,
      'Open ${platform.platform.name}:${module.path}',
    );
  }

  Future<void> back(WidgetTester tester) async {
    if (desktop) {
      await tapVisible(tester, find.byKey(const ValueKey('workbench-back')));
    } else {
      await tester.pageBack();
      await pumpFrames(tester, const Duration(milliseconds: 450));
    }
  }

  Future<void> search(
    WidgetTester tester,
    ModuleEntry module, {
    String? query,
  }) async {
    await tapVisible(
      tester,
      desktop
          ? find.byKey(const ValueKey('workbench-search'))
          : find.byKey(const ValueKey('learning-home-search')),
    );
    await waitForWidget(tester, searchField);
    await tester.enterText(searchField, query ?? module.title);
    await tester.pump();
    await tapVisible(
      tester,
      desktop
          ? find.byKey(ValueKey('quick-open:${module.path}'))
          : find.descendant(
              of: find.byKey(
                PageStorageKey(
                  'module-search:${(query ?? module.title).trim().toLowerCase()}',
                ),
              ),
              matching: find.widgetWithText(ListTile, module.title),
            ),
    );
    await expectModule(tester, module);
  }

  Future<void> closeSearch(WidgetTester tester) async {
    await waitForWidget(tester, searchField);
    if (desktop) {
      await tapVisible(tester, find.byTooltip('关闭快速打开'));
    } else {
      await tapVisible(tester, find.byTooltip('返回'));
    }
  }
}

ModuleEntry moduleByPath(String path) =>
    AppRouteTable.modules.singleWhere((module) => module.path == path);
