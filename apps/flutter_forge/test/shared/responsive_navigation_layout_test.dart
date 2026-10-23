import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter_forge_app/app/adaptive_app_shell.dart';
import 'package:flutter_forge_app/app/learning_home_page.dart';
import 'package:flutter_forge_app/app/module_home_page.dart';
import 'package:flutter_forge_app/app/router/app_route_table.dart';
import 'package:flutter_forge_app/module_registry/app_platform_snapshot.dart';
import 'package:flutter_forge_app/module_registry/module_category.dart';
import 'package:flutter_test/flutter_test.dart';

const _android = AppPlatformSnapshot(platform: AppTargetPlatform.android);

void main() {
  testWidgets('compact layout uses a drawer and learning home', (tester) async {
    await _pumpShell(tester, size: const Size(360, 800));

    expect(find.byType(NavigationRail), findsNothing);
    expect(find.byKey(const ValueKey('expanded-sidebar')), findsNothing);
    expect(find.byKey(const ValueKey('learning-home')), findsOneWidget);
    expect(find.byKey(const ValueKey('discovery-question')), findsOneWidget);
    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationDrawer), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(NavigationDrawer),
        matching: find.text('架构与状态'),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('learning home stays overflow-free at 320dp', (tester) async {
    await _pumpShell(tester, size: const Size(320, 700));

    expect(find.byKey(const ValueKey('learning-home')), findsOneWidget);
    expect(find.byKey(const ValueKey('discovery-question')), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('learning-category:platform')),
      250,
      scrollable: find
          .descendant(
            of: find.byKey(const ValueKey('learning-home')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(
      find.byKey(const ValueKey('learning-category:platform')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('medium layout uses a navigation rail', (tester) async {
    await _pumpShell(tester, size: const Size(800, 700));

    expect(find.byKey(const ValueKey('navigation-rail')), findsOneWidget);
    expect(find.byKey(const ValueKey('expanded-sidebar')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('expanded layout uses a searchable sidebar', (tester) async {
    await _pumpShell(tester, size: const Size(1200, 800));

    expect(find.byKey(const ValueKey('expanded-sidebar')), findsOneWidget);
    expect(find.byKey(const ValueKey('sidebar-search')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('sidebar-search')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '三棵树');
    await tester.pump();
    expect(find.text('三棵树与生命周期'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('slash opens title search from the web shell', (tester) async {
    await _pumpShell(tester, size: const Size(1200, 800));

    await tester.sendKeyEvent(LogicalKeyboardKey.slash);
    await tester.pumpAndSettle();

    expect(find.text('搜索模块、概念或分类'), findsOneWidget);
    expect(find.byTooltip('返回'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('category content changes from one to two columns', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(700, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: CategoryHomePage(
          category: ModuleCategory.basic,
          modules: AppRouteTable.modules,
          platform: _android,
        ),
      ),
    );
    expect(find.byKey(const ValueKey('category-page:basic')), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.binding.setSurfaceSize(const Size(1100, 800));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'desktop category window action is available only on native hosts',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1100, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          home: CategoryHomePage(
            category: ModuleCategory.basic,
            modules: AppRouteTable.modules,
            platform: const AppPlatformSnapshot(
              platform: AppTargetPlatform.macOS,
            ),
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey('category-header:basic')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('open-window:basic')),
        kIsWeb ? findsNothing : findsOneWidget,
      );
      expect(find.text('在新窗口打开'), kIsWeb ? findsNothing : findsOneWidget);
      expect(find.byType(FilledButton), kIsWeb ? findsNothing : findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('focused category window omits the open-window action', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1100, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: CategoryHomePage(
          category: ModuleCategory.basic,
          modules: AppRouteTable.modules,
          platform: const AppPlatformSnapshot(
            platform: AppTargetPlatform.macOS,
          ),
          focusedWindow: true,
        ),
      ),
    );

    expect(find.byKey(const ValueKey('open-window:basic')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('web module cards offer an explicit new-tab action', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1100, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: CategoryHomePage(
          category: ModuleCategory.basic,
          modules: AppRouteTable.modules,
          platform: const AppPlatformSnapshot(platform: AppTargetPlatform.web),
        ),
      ),
    );

    expect(find.byTooltip('在新标签页打开'), findsWidgets);
    expect(find.byKey(const ValueKey('open-window:basic')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpShell(WidgetTester tester, {required Size size}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      home: AdaptiveAppShell(
        modules: AppRouteTable.modules,
        location: '/',
        child: LearningHomePage(modules: AppRouteTable.modules),
      ),
    ),
  );
  await tester.pump();
}
