import 'package:flutter/material.dart';
import 'package:flutter_forge_app/module_registry/module_category.dart';
import 'package:flutter_forge_app/modules/popup_table/popup_list_interaction/pages/popup_page.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_fixture.dart';
import 'interactions.dart';
import 'platform_adapter.dart';

// One mount, two deterministic modules, no network/device/GPU/model work.
Future<void> runCoreSmoke(WidgetTester tester, AppFixture app) async {
  final adapter = PlatformAdapter(app.platform);
  await waitForWidget(tester, adapter.home);
  final module = moduleByPath('/tree-state');
  await adapter.openCategory(tester, module.category);
  await adapter.openModule(tester, module);
  expect(app.location, module.path);
  await adapter.back(tester);
  await waitForWidget(
    tester,
    find.byKey(ValueKey('category-page:${module.category.name}')),
  );
  expect(app.location, '/category/${module.category.name}');

  if (adapter.hasDrawer(tester)) {
    await adapter.openDrawer(tester);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(
      tester
          .state<ScaffoldState>(
            find.byKey(const ValueKey('adaptive-app-shell')),
          )
          .isDrawerOpen,
      isFalse,
    );
    expect(app.location, '/category/${module.category.name}');
  }

  // Reset between independent scenarios without remounting the application.
  await app.go(tester, '/');
  await adapter.search(tester, module);
  expect(app.location, module.path);
  await adapter.back(tester);
  await adapter.closeSearch(tester);
  await waitForWidget(tester, adapter.home);
  expect(app.location, '/');

  await adapter.openCategory(tester, ModuleCategory.popupTable);
  final popup = moduleByPath('/popup-list-interaction');
  await adapter.openModule(tester, popup);
  await tapVisible(tester, find.widgetWithText(ListTile, '弹窗组件'));
  await waitForWidget(tester, find.byType(PopupPage));
  expect(app.location, '${popup.path}/popup');
  await tapVisible(
    tester,
    find.descendant(
      of: find.byType(PopupPage),
      matching: find.byType(BackButton),
    ),
  );

  await adapter.expectModule(tester, popup);
  await tapVisible(tester, find.widgetWithText(ListTile, '列表交互'));
  await waitForWidget(tester, find.text('二维滚动表格演示'));
  expect(app.location, '${popup.path}/list');
  expectNoFlutterErrors(tester, 'Core smoke ${app.platform.platform.name}');
}
