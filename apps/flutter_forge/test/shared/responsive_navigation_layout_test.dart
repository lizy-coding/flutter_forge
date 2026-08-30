import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_forge_app/app/category_window_app.dart';
import 'package:flutter_forge_app/app/module_home_page.dart';
import 'package:flutter_forge_app/app/router/app_route_table.dart';
import 'package:flutter_forge_app/module_registry/module_category.dart';

void main() {
  testWidgets('module home fits a 360dp viewport', (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(360, 800)),
        child: MaterialApp(
          home: ModuleHomePage(modules: AppRouteTable.modules),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Flutter 学习实验室'), findsOneWidget);
  });

  testWidgets('category home fits a 360dp viewport', (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(360, 800)),
        child: MaterialApp(
          home: CategoryHomePage(
            category: ModuleCategory.basic,
            modules: AppRouteTable.modules,
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('基础机制'), findsOneWidget);
  });
}
