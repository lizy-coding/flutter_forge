import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_forge_app/app/router/app_route_table.dart';
import 'package:flutter_forge_app/module_registry/app_platform_snapshot.dart';
import 'package:flutter_forge_app/modules/ui/shader_playground/module_entry.dart';
import 'package:flutter_forge_app/modules/ui/shader_playground/module_root.dart';
import 'package:flutter_forge_app/modules/ui/shader_playground/shader_preview.dart';
import 'package:flutter_forge_app/shared/learning/learning_scaffold.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

Future<ShaderLesson> loadLesson(WidgetTester tester) async =>
    (await tester.runAsync(ShaderLesson.load))!;

ShaderParameters parameters(WidgetTester tester) =>
    (tester
                .widget<CustomPaint>(find.byKey(const Key('shader-preview')))
                .painter!
            as ShaderPreviewPainter)
        .parameters;

void main() {
  testWidgets('loads real shader and controls update and reset parameters', (
    tester,
  ) async {
    final lesson = await loadLesson(tester);
    await tester.pumpWidget(
      MaterialApp(home: ShaderPlaygroundPage(loadLesson: () async => lesson)),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('shader-preview')), findsOneWidget);
    expect(find.text('UV 坐标与双色渐变'), findsOneWidget);
    expect(find.text(lesson.source), findsOneWidget);

    await tester.ensureVisible(find.text('纵向渐变'));
    await tester.tap(find.text('纵向渐变'));
    await tester.pump();
    expect(parameters(tester).vertical, isTrue);
    await tester.ensureVisible(find.byKey(const Key('shader-offset')));
    await tester.drag(
      find.byKey(const Key('shader-offset')),
      const Offset(120, 0),
    );
    await tester.pump();
    expect(parameters(tester).offset, greaterThan(0));
    await tester.ensureVisible(find.text('交换颜色'));
    await tester.tap(find.text('交换颜色'));
    await tester.pump();
    expect(parameters(tester).startColor, const ShaderParameters().endColor);

    await tester.tap(find.text('复位参数'));
    await tester.pump();
    expect(parameters(tester).vertical, isFalse);
    expect(parameters(tester).offset, 0);
    expect(parameters(tester).startColor, const ShaderParameters().startColor);
    await tester.pumpWidget(const SizedBox.shrink());
    expect(lesson.shader.debugDisposed, isTrue);
  });

  testWidgets('UV mode disables gradient controls and reset restores them', (
    tester,
  ) async {
    final lesson = await loadLesson(tester);
    await tester.pumpWidget(
      MaterialApp(home: ShaderPlaygroundPage(loadLesson: () async => lesson)),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('shader-uv-toggle')));
    await tester.tap(find.byKey(const Key('shader-uv-toggle')));
    await tester.pumpAndSettle();
    expect(parameters(tester).showUv, isTrue);
    expect(tester.widget<Slider>(find.byType(Slider)).onChanged, isNull);
    expect(
      tester
          .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '纵向渐变'))
          .onSelected,
      isNull,
    );
    await tester.ensureVisible(find.text('复位参数'));
    await tester.tap(find.text('复位参数'));
    await tester.pump();
    expect(parameters(tester).showUv, isFalse);
    expect(tester.widget<Slider>(find.byType(Slider)).onChanged, isNotNull);
  });

  testWidgets('loading failure can retry with the real shader', (tester) async {
    final lesson = await loadLesson(tester);
    var attempts = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: ShaderPlaygroundPage(
          loadLesson: () async {
            if (++attempts == 1) throw StateError('missing shader');
            return lesson;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('无法加载 Shader，请重试。'), findsOneWidget);
    expect(find.byKey(const Key('shader-preview')), findsNothing);
    await tester.tap(find.text('重试加载'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('shader-preview')), findsOneWidget);
    expect(attempts, 2);
  });

  testWidgets('late load completion releases shader after leaving the page', (
    tester,
  ) async {
    final lesson = await loadLesson(tester);
    final pending = Completer<ShaderLesson>();
    await tester.pumpWidget(
      MaterialApp(home: ShaderPlaygroundPage(loadLesson: () => pending.future)),
    );
    expect(find.text('正在加载 Shader…'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    pending.complete(lesson);
    await tester.pump();
    expect(lesson.shader.debugDisposed, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('late load error does not update an unmounted page', (
    tester,
  ) async {
    final pending = Completer<ShaderLesson>();
    await tester.pumpWidget(
      MaterialApp(home: ShaderPlaygroundPage(loadLesson: () => pending.future)),
    );
    await tester.pumpWidget(const SizedBox.shrink());
    pending.completeError(StateError('late failure'));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'compact large text layout scrolls to all controls and teaching',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 800);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final lesson = await loadLesson(tester);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1.6)),
            child: child!,
          ),
          home: ShaderPlaygroundPage(loadLesson: () async => lesson),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('复位参数'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('复位参数'));
      await tester.ensureVisible(find.byType(ExerciseCard));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('compiled GLSL outputs gradient, UV, and premultiplied alpha', (
    tester,
  ) async {
    final lesson = await loadLesson(tester);
    addTearDown(lesson.dispose);
    Future<List<int>> pixel(
      ShaderParameters values,
      Size size,
      int x,
      int y,
    ) async {
      final recorder = ui.PictureRecorder();
      ShaderPreviewPainter(
        shader: lesson.shader,
        parameters: values,
      ).paint(Canvas(recorder), size);
      final picture = recorder.endRecording();
      final image = (await tester.runAsync(
        () => picture.toImage(size.width.toInt(), size.height.toInt()),
      ))!;
      final bytes = (await tester.runAsync(image.toByteData))!;
      final index = (y * size.width.toInt() + x) * 4;
      final result = bytes.buffer.asUint8List(index, 4).toList();
      image.dispose();
      picture.dispose();
      return result;
    }

    const redBlue = ShaderParameters(
      startColor: Color(0xFFFF0000),
      endColor: Color(0xFF0000FF),
    );
    final left = await pixel(redBlue, const Size(100, 50), 0, 25);
    final right = await pixel(redBlue, const Size(100, 50), 99, 25);
    expect(left[0], greaterThan(245));
    expect(left[2], lessThan(10));
    expect(right[0], lessThan(10));
    expect(right[2], greaterThan(245));
    final vertical = await pixel(
      redBlue.copyWith(vertical: true),
      const Size(100, 50),
      0,
      49,
    );
    expect(vertical[2], greaterThan(245));
    final offset = await pixel(
      redBlue.copyWith(offset: 0.5),
      const Size(100, 50),
      0,
      25,
    );
    expect(offset[0], closeTo(128, 5));
    expect(offset[2], closeTo(128, 5));

    final uv = await pixel(
      redBlue.copyWith(showUv: true),
      const Size(50, 100),
      49,
      99,
    );
    expect(uv[0], greaterThan(245));
    expect(uv[1], greaterThan(245));
    expect(uv[2], 0);
    final transparent = await pixel(
      const ShaderParameters(
        startColor: Color(0x80FF0000),
        endColor: Color(0x80FF0000),
      ),
      const Size(100, 50),
      50,
      25,
    );
    expect(transparent[0], closeTo(128, 1));
    expect(transparent[3], closeTo(128, 1));
  });

  test('module has a stable route on all product targets', () {
    final module = AppRouteTable.modules.singleWhere(
      (m) => m.path == '/shader-playground',
    );
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

  testWidgets('stable route builds the shader entry', (tester) async {
    final module = AppRouteTable.modules.singleWhere(
      (m) => m.path == '/shader-playground',
    );
    final router = GoRouter(
      initialLocation: module.path,
      routes: [
        GoRoute(
          path: module.path,
          builder: (context, _) => module.builder(context),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    expect(find.byType(ShaderPlaygroundEntry), findsOneWidget);
    // The async asset load is allowed to complete after navigation away.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(
      () async => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    expect(tester.takeException(), isNull);
  });
}
