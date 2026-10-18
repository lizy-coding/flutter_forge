import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_forge_app/app/router/app_route_table.dart';
import 'package:flutter_forge_app/module_registry/app_platform_snapshot.dart';
import 'package:flutter_forge_app/module_registry/module_category.dart';
import 'package:flutter_forge_app/modules/basic/pixel_shader_intro/drawing_canvas.dart';
import 'package:flutter_forge_app/modules/basic/pixel_shader_intro/drawing_model.dart';
import 'package:flutter_forge_app/modules/basic/pixel_shader_intro/module_entry.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> nextStep(WidgetTester tester) =>
    tapVisible(tester, find.byKey(const Key('intro-next')));

void main() {
  test('fixed coordinates and UV differ when the canvas becomes wider', () {
    const fixed = DrawingRule(width: 400);
    const proportional = DrawingRule(width: 400, proportional: true);
    const point = Offset(150, 50);
    expect(fixed.sample(point).blue, isFalse);
    expect(proportional.sample(point).blue, isTrue);
    expect(fixed.blueBoundary, 100);
    expect(proportional.blueBoundary, 200);
    expect(proportional.sample(point).uv, const Offset(0.375, 0.5));
    expect(const DrawingRule().sample(point).uv, const Offset(0.75, 0.5));
  });

  test('boundary is white and positions outside the canvas stay bounded', () {
    const rule = DrawingRule(width: 400, proportional: true);
    expect(rule.sample(const Offset(199.9, 50)).blue, isTrue);
    expect(rule.sample(const Offset(200, 50)).blue, isFalse);
    expect(rule.sample(const Offset(-20, -30)).uv, Offset.zero);
    final outside = rule.sample(const Offset(900, 300));
    expect(outside.position, const Offset(400, 100));
    expect(outside.uv, const Offset(1, 1));
    expect(rule.sampleFromDisplay(Offset.zero, Size.zero).uv, Offset.zero);
  });

  test('display scaling preserves lesson coordinates and UV', () {
    const rule = DrawingRule(width: 400, proportional: true);
    final small = rule.sampleFromDisplay(
      const Offset(75, 25),
      const Size(200, 50),
    );
    final large = rule.sampleFromDisplay(
      const Offset(150, 50),
      const Size(400, 100),
    );
    expect(small.position, const Offset(150, 50));
    expect(small.uv, large.uv);
    expect(small.blue, large.blue);
  });

  testWidgets(
    'three steps reveal concepts progressively and reset the current step',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: PixelShaderIntroEntry()));
      expect(find.text('第 1 步 / 共 3 步'), findsOneWidget);
      expect(find.text('宽 400'), findsNothing);
      expect(find.byKey(const Key('intro-uv')), findsNothing);
      expect(
        tester
            .widget<OutlinedButton>(find.byKey(const Key('intro-previous')))
            .onPressed,
        isNull,
      );
      await tapVisible(tester, find.text('选择右侧位置'));
      expect(find.text('这个位置不在蓝色矩形内 → 白色'), findsOneWidget);

      await nextStep(tester);
      expect(find.text('第 2 步 / 共 3 步'), findsOneWidget);
      expect(find.text('直接画矩形'), findsOneWidget);
      expect(find.text('逐位置算颜色'), findsOneWidget);
      expect(find.text('宽 400'), findsNothing);
      await tapVisible(tester, find.text('选择右侧位置'));
      expect(find.text('x < 100：不成立 → 输出白色'), findsOneWidget);

      await nextStep(tester);
      expect(find.text('第 3 步 / 共 3 步'), findsOneWidget);
      await tapVisible(tester, find.text('宽 400'));
      expect(
        find.text('U = 50 ÷ 400 = 0.125\nV = 50 ÷ 100 = 0.5'),
        findsOneWidget,
      );
      expect(find.text('画布：400 × 100；蓝色区域宽 200'), findsOneWidget);
      await tapVisible(tester, find.text('选择左侧位置'));
      expect(find.text('U < 0.5：成立 → 输出蓝色'), findsOneWidget);
      await tapVisible(tester, find.text('固定坐标 x < 100'));
      expect(find.text('画布：400 × 100；蓝色区域宽 100'), findsOneWidget);
      expect(find.text('x < 100：不成立 → 输出白色'), findsOneWidget);
      await tapVisible(tester, find.text('复位本步'));
      expect(find.text('第 3 步 / 共 3 步'), findsOneWidget);
      expect(find.text('画布：200 × 100；蓝色区域宽 100'), findsOneWidget);
      expect(
        find.text('U = 50 ÷ 200 = 0.25\nV = 50 ÷ 100 = 0.5'),
        findsOneWidget,
      );
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('intro-next')))
            .onPressed,
        isNull,
      );
      await tapVisible(tester, find.text('从第一步重新学习'));
      expect(find.text('第 1 步 / 共 3 步'), findsOneWidget);
      expect(
        tester.getTopLeft(find.byKey(const Key('intro-step'))).dy,
        greaterThanOrEqualTo(0),
      );
    },
  );

  testWidgets(
    'click and drag report the canvas position rather than screen position',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: PixelShaderIntroEntry()));
      final canvas = find.byKey(const Key('intro-canvas'));
      await tester.ensureVisible(canvas);
      final bounds = tester.getRect(canvas);
      await tester.tapAt(
        bounds.topLeft + Offset(bounds.width * 0.75, bounds.height / 2),
      );
      await tester.pumpAndSettle();
      expect(find.text('选中位置：x = 150，y = 50'), findsOneWidget);
      expect(find.text('这个位置不在蓝色矩形内 → 白色'), findsOneWidget);
      await tester.dragFrom(
        bounds.topLeft + Offset(bounds.width * 0.75, bounds.height / 2),
        Offset(-bounds.width / 2, 0),
      );
      await tester.pumpAndSettle();
      expect(find.text('选中位置：x = 50，y = 50'), findsOneWidget);
      expect(find.text('这个位置在蓝色矩形内 → 蓝色'), findsOneWidget);
      await tester.tapAt(
        bounds.topLeft + Offset(bounds.width * 0.498, bounds.height / 2),
      );
      await tester.pumpAndSettle();
      expect(find.text('选中位置：x = 100，y = 50'), findsOneWidget);
      expect(find.text('这个位置不在蓝色矩形内 → 白色'), findsOneWidget);
    },
  );

  testWidgets(
    'switching descriptions keeps the blue region and selection unchanged',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: PixelShaderIntroEntry()));
      await nextStep(tester);
      await tapVisible(tester, find.text('选择右侧位置'));
      final before = tester
          .widget<Text>(find.byKey(const Key('intro-position')))
          .data;
      await tapVisible(tester, find.text('直接画矩形'));
      expect(
        tester.widget<DrawingCanvas>(find.byType(DrawingCanvas)).method,
        DrawingMethod.rectangle,
      );
      expect(
        tester.widget<Text>(find.byKey(const Key('intro-position'))).data,
        before,
      );
      await tapVisible(tester, find.text('逐位置算颜色'));
      expect(
        tester.widget<DrawingCanvas>(find.byType(DrawingCanvas)).method,
        DrawingMethod.samples,
      );
      expect(
        tester.widget<Text>(find.byKey(const Key('intro-position'))).data,
        before,
      );
      expect(find.text('x < 100：不成立 → 输出白色'), findsOneWidget);
    },
  );

  for (final viewport in [const Size(360, 800), const Size(800, 600)]) {
    testWidgets('all steps fit $viewport with large text', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = viewport;
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
          home: const PixelShaderIntroEntry(),
        ),
      );
      await nextStep(tester);
      await nextStep(tester);
      await tapVisible(tester, find.text('宽 400'));
      await tapVisible(tester, find.text('固定坐标 x < 100'));
      await tapVisible(tester, find.text('选择右侧位置'));
      await tapVisible(tester, find.text('复位本步'));
      await tapVisible(tester, find.text('从第一步重新学习'));
      expect(tester.takeException(), isNull);
      expect(find.text('第 1 步 / 共 3 步'), findsOneWidget);
      expect(
        tester.getTopLeft(find.byKey(const Key('intro-step'))).dy,
        greaterThanOrEqualTo(0),
      );
    });
  }

  testWidgets('actual painted colors agree for rectangle and teaching grid', (
    tester,
  ) async {
    Future<List<int>> pixel(
      DrawingRule rule,
      DrawingMethod method,
      int x,
    ) async {
      final recorder = ui.PictureRecorder();
      DrawingCanvasPainter(
        rule: rule,
        method: method,
        position: const Offset(50, 50),
      ).paint(Canvas(recorder), const Size(200, 50));
      final picture = recorder.endRecording();
      final image = (await tester.runAsync(() => picture.toImage(200, 50)))!;
      final bytes = (await tester.runAsync(image.toByteData))!;
      final index = (37 * 200 + x) * 4;
      final result = bytes.buffer
          .asUint8List(bytes.offsetInBytes + index, 4)
          .toList();
      image.dispose();
      picture.dispose();
      return result;
    }

    for (final method in DrawingMethod.values) {
      expect(await pixel(const DrawingRule(), method, 37), [37, 99, 235, 255]);
      expect(await pixel(const DrawingRule(), method, 137), [
        255,
        255,
        255,
        255,
      ]);
      expect(await pixel(const DrawingRule(width: 400), method, 77), [
        255,
        255,
        255,
        255,
      ]);
      expect(
        await pixel(
          const DrawingRule(width: 400, proportional: true),
          method,
          77,
        ),
        [37, 99, 235, 255],
      );
    }
  });

  test('entry belongs to basic and has a stable route on product targets', () {
    final module = AppRouteTable.modules.singleWhere(
      (m) => m.path == '/pixel-shader-intro',
    );
    expect(module.category, ModuleCategory.basic);
    expect(module.platformSupport.excludedPlatforms, isEmpty);
    for (final platform in AppTargetPlatform.values.where(
      (p) => p != AppTargetPlatform.unsupported,
    )) {
      final routes = AppRouteTable.moduleRoutesFor(
        AppPlatformSnapshot(platform: platform),
      );
      expect(routes.where((r) => r.path == module.path), hasLength(1));
    }
  });

  testWidgets(
    'stable route starts at the first lesson and reentry resets progress',
    (tester) async {
      final module = AppRouteTable.modules.singleWhere(
        (m) => m.path == '/pixel-shader-intro',
      );
      final router = GoRouter(
        initialLocation: module.path,
        routes: [
          GoRoute(path: '/', builder: (_, __) => const Text('目录')),
          GoRoute(
            path: module.path,
            builder: (context, _) => module.builder(context),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
      expect(find.byType(PixelShaderIntroEntry), findsOneWidget);
      await nextStep(tester);
      router.go('/');
      await tester.pumpAndSettle();
      router.go(module.path);
      await tester.pumpAndSettle();
      expect(find.text('第 1 步 / 共 3 步'), findsOneWidget);
    },
  );
}
