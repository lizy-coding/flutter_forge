import 'package:flutter_forge_app/app/router/app_route_table.dart';
import 'package:flutter_forge_app/module_registry/app_platform_snapshot.dart';
import 'package:flutter_forge_app/modules/popup_table/popup_widgets/widgets/context_menu_demo.dart';
import 'package:flutter_forge_app/modules/popup_table/popup_widgets/widgets/demo_section.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_forge_app/modules/popup_table/popup_widgets/module_entry.dart';
import 'package:flutter_forge_app/modules/popup_table/popup_widgets/module_root.dart';

void main() {
  testWidgets('PopWidgetEntry renders module page', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: PopWidgetEntry()));

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Flutter 弹窗学习'), findsOneWidget);
    expect(find.text('AlertDialog (普通对话框)'), findsOneWidget);
  });

  testWidgets('PopDemoHomePage renders teaching components', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: PopDemoHomePage(title: 'Flutter 弹窗学习')),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Flutter 弹窗学习'), findsOneWidget);
    expect(find.text('AlertDialog (普通对话框)'), findsOneWidget);
    expect(find.text('SimpleDialog (选项对话框)'), findsOneWidget);
    expect(find.text('Modal Bottom Sheet (模态底部弹窗)'), findsOneWidget);
    expect(find.text('自定义 Dialog'), findsOneWidget);
    expect(find.text('🎯 学习目标'), findsOneWidget);
  });

  testWidgets('PopDemoHomePage FAB toggles bottom bar', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: PopDemoHomePage(title: 'Flutter 弹窗学习')),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final fab = find.byType(FloatingActionButton);
    expect(fab, findsOneWidget);

    await tester.tap(fab);
    await tester.pump();

    expect(find.text('这是一个持久化底部工具条，你可以手动关闭。'), findsOneWidget);
  });

  testWidgets('PopDemoHomePage toolbar shows date/time picker menu', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: PopDemoHomePage(title: 'Flutter 弹窗学习')),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('日期/时间'), findsOneWidget);
  });

  for (final overlay in [false, true]) {
    testWidgets(
      'leaving during ${overlay ? 'overlay' : 'dialog'} chain opening cleans up the module',
      (tester) async {
        final router = GoRouter(
          initialLocation: '/popup-widgets',
          routes: AppRouteTable.routesFor(
            const AppPlatformSnapshot(platform: AppTargetPlatform.macOS),
          ),
        );
        addTearDown(router.dispose);
        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        await tester.pumpAndSettle();
        final button = find.text(overlay ? 'Overlay 打开 A→B→C' : '打开 A→B→C');
        final scrollable = find
            .descendant(
              of: find.byType(PopupDemoInteractiveDemo),
              matching: find.byType(Scrollable),
            )
            .first;
        await tester.scrollUntilVisible(button, 300, scrollable: scrollable);
        await Scrollable.ensureVisible(tester.element(button), alignment: 0.5);
        await tester.pump();
        await tester.tap(button);
        await tester.pump();
        router.go('/');
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpAndSettle();
        expect(find.textContaining('弹窗 A'), findsNothing);
        expect(find.textContaining('弹窗 B'), findsNothing);
        expect(find.textContaining('弹窗 C'), findsNothing);
        expect(find.text('Lizy'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('context menu disappears when its anchor leaves the page', (
    tester,
  ) async {
    final showMenu = ValueNotifier(true);
    addTearDown(showMenu.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ValueListenableBuilder<bool>(
            valueListenable: showMenu,
            builder: (_, show, __) => show
                ? ContextMenuTile(onSelected: (_) {})
                : const Text('destination'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Context Menu (MenuAnchor)'));
    await tester.pumpAndSettle();
    expect(find.text('编辑'), findsOneWidget);
    showMenu.value = false;
    await tester.pumpAndSettle();
    expect(find.text('编辑'), findsNothing);
    expect(find.text('destination'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
