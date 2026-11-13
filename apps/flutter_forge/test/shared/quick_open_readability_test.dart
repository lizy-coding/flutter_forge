import 'package:flutter/material.dart';
import 'package:flutter_forge_app/app/module_quick_open.dart';
import 'package:flutter_forge_app/app/router/app_route_table.dart';
import 'package:flutter_forge_app/app/theme/app_theme.dart';
import 'package:flutter_forge_app/app/theme/app_theme_selection.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('quick open keeps title and category readable with large text', (
    tester,
  ) async {
    final module = AppRouteTable.modules.first;
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, _) => Scaffold(
            body: TextButton(
              onPressed: () => showModuleQuickOpen(context, [module]),
              child: const Text('Open'),
            ),
          ),
        ),
        GoRoute(path: module.path, builder: (_, _) => const SizedBox()),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        theme: AppTheme.light(AppThemePalette.graphiteForge),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    final tile = find.byKey(ValueKey('quick-open:${module.path}'));
    final title = find.descendant(of: tile, matching: find.text(module.title));
    final category = find.descendant(
      of: tile,
      matching: find.text('${module.category.label} · 中文实验'),
    );
    final tileRect = tester.getRect(tile);
    final titleRect = tester.getRect(title);
    final categoryRect = tester.getRect(category);
    expect(titleRect.top, greaterThanOrEqualTo(tileRect.top));
    expect(categoryRect.top, greaterThanOrEqualTo(titleRect.bottom));
    expect(categoryRect.bottom, lessThanOrEqualTo(tileRect.bottom));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
