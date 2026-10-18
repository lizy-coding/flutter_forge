import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_forge_app/app/module_home_page.dart';
import 'package:flutter_forge_app/module_registry/app_platform_snapshot.dart';
import 'package:flutter_forge_app/module_registry/module_category.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('opening disables the action until the window is ready', (
    tester,
  ) async {
    final opened = Completer<String?>();
    final categories = <ModuleCategory>[];
    await _pumpCategory(tester, (category) {
      categories.add(category);
      return opened.future;
    });
    final action = find.byKey(const ValueKey('open-window:basic'));

    // Both callbacks can arrive before Flutter rebuilds the disabled button.
    await tester.tap(action);
    await tester.tap(action);
    await tester.pump();

    expect(categories, [ModuleCategory.basic]);
    expect(tester.widget<FilledButton>(action).onPressed, isNull);
    expect(find.text('正在打开…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    opened.complete('window-1');
    await tester.pumpAndSettle();

    expect(tester.widget<FilledButton>(action).onPressed, isNotNull);
    expect(find.text('在新窗口打开'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('opening errors are visible and the action can retry', (
    tester,
  ) async {
    var attempts = 0;
    await _pumpCategory(tester, (_) async {
      if (++attempts == 1) throw StateError('native create failed');
      return 'window-2';
    });
    final action = find.byKey(const ValueKey('open-window:basic'));

    await tester.tap(action);
    await tester.pumpAndSettle();

    expect(find.text('打开分类窗口失败，请重试。'), findsOneWidget);
    expect(tester.widget<FilledButton>(action).onPressed, isNotNull);
    expect(tester.takeException(), isNull);

    await tester.tap(action);
    await tester.pumpAndSettle();
    expect(attempts, 2);
    expect(tester.widget<FilledButton>(action).onPressed, isNotNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('leaving while opening does not update a disposed header', (
    tester,
  ) async {
    final opened = Completer<String?>();
    await _pumpCategory(tester, (_) => opened.future);
    await tester.tap(find.byKey(const ValueKey('open-window:basic')));
    await tester.pump();
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));

    opened.completeError(StateError('window failed after navigation'));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('changing category starts with an independent window action', (
    tester,
  ) async {
    final first = Completer<String?>();
    final categories = <ModuleCategory>[];
    Future<String?> open(ModuleCategory category) {
      categories.add(category);
      return category == ModuleCategory.basic
          ? first.future
          : Future.value('state-window');
    }

    await _pumpCategory(tester, open);
    await tester.tap(find.byKey(const ValueKey('open-window:basic')));
    await tester.pump();
    await _pumpCategory(tester, open, category: ModuleCategory.state);

    final action = find.byKey(const ValueKey('open-window:state'));
    expect(tester.widget<FilledButton>(action).onPressed, isNotNull);
    await tester.tap(action);
    await tester.pumpAndSettle();
    expect(categories, [ModuleCategory.basic, ModuleCategory.state]);

    first.complete('basic-window');
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(action).onPressed, isNotNull);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpCategory(
  WidgetTester tester,
  Future<String?> Function(ModuleCategory) open, {
  ModuleCategory category = ModuleCategory.basic,
}) async {
  await tester.binding.setSurfaceSize(const Size(1100, 800));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: CategoryHomePage(
          category: category,
          modules: const [],
          platform: const AppPlatformSnapshot(
            platform: AppTargetPlatform.macOS,
          ),
          openCategoryWindow: open,
        ),
      ),
    ),
  );
}
