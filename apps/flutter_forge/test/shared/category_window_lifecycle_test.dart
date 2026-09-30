import 'package:flutter/material.dart';
import 'package:flutter_forge_app/app/category_window_app.dart';
import 'package:flutter_forge_app/module_registry/app_platform_snapshot.dart';
import 'package:flutter_forge_app/module_registry/module_category.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  const platform = AppPlatformSnapshot(platform: AppTargetPlatform.macOS);

  testWidgets(
    'category window rebuild preserves the active module and router',
    (tester) async {
      await tester.pumpWidget(
        const CategoryWindowApp(
          category: ModuleCategory.popupTable,
          platform: platform,
        ),
      );
      await tester.pumpAndSettle();
      final router =
          tester.widget<MaterialApp>(find.byType(MaterialApp)).routerConfig!
              as GoRouter;
      router.go('/popup-list-interaction/list');
      await tester.pumpAndSettle();
      expect(find.text('二维滚动表格演示'), findsOneWidget);

      await tester.pumpWidget(
        CategoryWindowApp(
          category: ModuleCategory.popupTable,
          platform: AppPlatformSnapshot(platform: platform.platform),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<MaterialApp>(find.byType(MaterialApp)).routerConfig,
        same(router),
      );
      expect(
        router.routeInformationProvider.value.uri.path,
        '/popup-list-interaction/list',
      );
      expect(find.text('二维滚动表格演示'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      expect(
        () => router.routeInformationProvider.addListener(() {}),
        throwsAssertionError,
      );
    },
  );

  testWidgets(
    'changing category replaces the router and disposes the previous one',
    (tester) async {
      await tester.pumpWidget(
        const CategoryWindowApp(
          category: ModuleCategory.popupTable,
          platform: platform,
        ),
      );
      await tester.pumpAndSettle();
      final previous =
          tester.widget<MaterialApp>(find.byType(MaterialApp)).routerConfig!
              as GoRouter;
      previous.go('/popup-widgets');
      await tester.pumpAndSettle();
      await tester.pumpWidget(
        const CategoryWindowApp(
          category: ModuleCategory.basic,
          platform: platform,
        ),
      );
      await tester.pumpAndSettle();
      final current =
          tester.widget<MaterialApp>(find.byType(MaterialApp)).routerConfig!
              as GoRouter;
      expect(current, isNot(same(previous)));
      expect(current.routeInformationProvider.value.uri.path, '/');
      expect(find.text('Flutter 弹窗学习'), findsNothing);
      expect(
        () => previous.routeInformationProvider.addListener(() {}),
        throwsAssertionError,
      );
    },
  );
}
