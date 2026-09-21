import 'package:flutter/material.dart';
import 'package:flutter_forge_app/app/category_window_app.dart';
import 'package:flutter_forge_app/app/module_home_page.dart';
import 'package:flutter_forge_app/app/app_platform_provider.dart';
import 'package:flutter_forge_app/app/router/app_route_table.dart';
import 'package:flutter_forge_app/module_registry/app_platform_snapshot.dart';
import 'package:flutter_forge_app/module_registry/module_category.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('module home fits a 360dp viewport', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appPlatformProvider.overrideWithValue(
            const AppPlatformSnapshot(platform: AppTargetPlatform.android),
          ),
        ],
        child: MediaQuery(
          data: const MediaQueryData(
            size: Size(360, 800),
            padding: EdgeInsets.only(top: 24, bottom: 24),
          ),
          child: MaterialApp(
            home: ModuleHomePage(modules: AppRouteTable.modules),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Flutter 学习实验室'), findsOneWidget);
  });

  testWidgets('mobile category drawer opens a top-level category', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appPlatformProvider.overrideWithValue(
            const AppPlatformSnapshot(platform: AppTargetPlatform.android),
          ),
        ],
        child: MediaQuery(
          data: const MediaQueryData(size: Size(360, 800)),
          child: MaterialApp(
            home: ModuleHomePage(modules: AppRouteTable.modules),
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();

    expect(find.text('学习目录'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('category-drawer:platform')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('category-drawer:platform')));
    await tester.pumpAndSettle();

    expect(find.byType(CategoryHomePage), findsOneWidget);
    expect(find.text('网络与平台'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('category home fits a 360dp viewport', (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(360, 800),
          padding: EdgeInsets.only(top: 24, bottom: 24),
        ),
        child: MaterialApp(
          home: CategoryHomePage(
            category: ModuleCategory.basic,
            modules: AppRouteTable.modules,
            platform: const AppPlatformSnapshot(
              platform: AppTargetPlatform.android,
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('基础机制'), findsOneWidget);
  });
}
