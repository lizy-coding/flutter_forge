import 'package:flutter/material.dart';
import 'package:flutter_forge_app/app/router/app_route_table.dart';
import 'package:flutter_forge_app/module_registry/module_category.dart';
import 'package:flutter_forge_app/modules/basic/graphics_background/module_entry.dart';
import 'package:flutter_forge_app/modules/basic/graphics_background/texture_sample.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> next(WidgetTester tester) =>
    tapVisible(tester, find.byKey(const Key('background-next')));

void main() {
  test(
    'sample centers identify four colors and grayscale leaves source intact',
    () {
      expect(TextureSample.values.map((s) => s.uv).toSet(), hasLength(4));
      for (final sample in TextureSample.values) {
        expect(sample.outputColor(grayscale: false), sample.color);
      }
      final expected = [76, 150, 29, 226];
      for (var index = 0; index < TextureSample.values.length; index++) {
        final sample = TextureSample.values[index];
        final output = sample.outputColor(grayscale: true);
        expect(
          output,
          Color.fromARGB(
            255,
            expected[index],
            expected[index],
            expected[index],
          ),
        );
        expect(sample.outputColor(grayscale: false), sample.color);
      }
    },
  );

  testWidgets('definitions precede UV and shader controls', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: GraphicsBackgroundEntry()));
    expect(find.text('像素 Pixel'), findsOneWidget);
    expect(find.text('矩形与 Canvas'), findsOneWidget);
    expect(find.byKey(const Key('background-uv')), findsNothing);
    expect(find.byKey(const Key('background-grayscale')), findsNothing);
    expect(
      tester.widget<InkWell>(find.byKey(const Key('texture-topRight'))).onTap,
      isNull,
    );
    await next(tester);
    expect(find.text('GPU：图形处理器'), findsOneWidget);
    expect(find.text('纹理 Texture'), findsOneWidget);
    expect(find.byKey(const Key('background-uv')), findsNothing);
    await next(tester);
    expect(find.text('UV：纹理位置的坐标'), findsOneWidget);
    expect(find.byKey(const Key('background-uv')), findsOneWidget);
    expect(find.byKey(const Key('background-grayscale')), findsNothing);
    await next(tester);
    expect(find.text('Shader：着色器程序'), findsOneWidget);
    expect(find.byKey(const Key('background-grayscale')), findsOneWidget);
  });

  testWidgets('UV selection and display size preserve the sampled color', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: GraphicsBackgroundEntry()));
    await next(tester);
    await next(tester);
    await tapVisible(tester, find.byKey(const Key('texture-bottomRight')));
    expect(find.text('取色位置：右下；UV = (0.75, 0.75)'), findsOneWidget);
    expect(find.text('选中位置输出：黄色'), findsOneWidget);
    final before = tester.getSize(find.byKey(const Key('texture-topLeft')));
    await tapVisible(tester, find.text('放大显示'));
    expect(
      tester.getSize(find.byKey(const Key('texture-topLeft'))).width,
      greaterThan(before.width),
    );
    expect(find.text('取色位置：右下；UV = (0.75, 0.75)'), findsOneWidget);
    expect(find.text('选中位置输出：黄色'), findsOneWidget);
  });

  testWidgets('grayscale changes only output and lesson reset restores state', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: GraphicsBackgroundEntry()));
    await next(tester);
    await next(tester);
    await next(tester);
    await tapVisible(tester, find.byKey(const Key('texture-bottomLeft')));
    await tapVisible(tester, find.byKey(const Key('background-grayscale')));
    expect(find.text('读到的纹理颜色：蓝色'), findsOneWidget);
    expect(find.text('取色位置：左下；UV = (0.25, 0.75)'), findsOneWidget);
    expect(find.text('选中位置输出：灰色（29 / 255）'), findsOneWidget);
    final output =
        tester
                .widget<Container>(find.byKey(const Key('background-output')))
                .decoration!
            as BoxDecoration;
    expect(output.color, const Color(0xFF1D1D1D));
    await tapVisible(tester, find.text('复位本节'));
    expect(find.text('第 4 节 / 共 4 节'), findsOneWidget);
    expect(find.text('选中位置输出：红色'), findsOneWidget);
    expect(
      tester.getTopLeft(find.byKey(const Key('background-chapter'))).dy,
      greaterThanOrEqualTo(0),
    );
    await tapVisible(tester, find.text('从第一节重新学习'));
    expect(find.text('第 1 节 / 共 4 节'), findsOneWidget);
    expect(find.byKey(const Key('background-uv')), findsNothing);
    expect(
      tester.getTopLeft(find.byKey(const Key('background-chapter'))).dy,
      greaterThanOrEqualTo(0),
    );
  });

  for (final size in [const Size(360, 800), const Size(800, 600)]) {
    testWidgets(
      'chapters remain readable and usable at $size with large text',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(1.6)),
              child: child!,
            ),
            home: const GraphicsBackgroundEntry(),
          ),
        );
        await next(tester);
        await next(tester);
        await next(tester);
        await tapVisible(tester, find.byKey(const Key('texture-topRight')));
        await tapVisible(tester, find.byKey(const Key('background-grayscale')));
        await tapVisible(tester, find.text('从第一节重新学习'));
        expect(tester.takeException(), isNull);
        expect(find.text('第 1 节 / 共 4 节'), findsOneWidget);
      },
    );
  }

  testWidgets(
    'background entry belongs to basic and continues to drawing lesson',
    (tester) async {
      final background = AppRouteTable.modules.singleWhere(
        (m) => m.path == '/graphics-background',
      );
      final drawing = AppRouteTable.modules.singleWhere(
        (m) => m.path == '/pixel-shader-intro',
      );
      expect(background.category, ModuleCategory.basic);
      expect(background.platformSupport.excludedPlatforms, isEmpty);
      final router = GoRouter(
        initialLocation: background.path,
        routes: [
          GoRoute(
            path: background.path,
            builder: (context, _) => background.builder(context),
          ),
          GoRoute(
            path: drawing.path,
            builder: (context, _) => drawing.builder(context),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
      await next(tester);
      await next(tester);
      await next(tester);
      await tapVisible(tester, find.text('继续学习：从画形状到算颜色'));
      expect(find.text('绘制入门：从画形状到算颜色'), findsOneWidget);
      router.pop();
      await tester.pumpAndSettle();
      expect(find.text('第 4 节 / 共 4 节'), findsOneWidget);
    },
  );
}
