import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_forge_app/app/router/app_route_table.dart';
import 'package:flutter_forge_app/module_registry/app_platform_snapshot.dart';
import 'package:flutter_forge_app/modules/ui/shader_playground/module_entry.dart';
import 'package:flutter_forge_app/modules/ui/shader_playground/lesson_steps.dart';
import 'package:flutter_forge_app/modules/basic/pixel_shader_intro/module_entry.dart';
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

Future<void> tapVisible(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> advanceTo(WidgetTester tester, int step) async {
  for (var i = 0; i < step; i++) {
    await tapVisible(tester, find.byKey(const Key('shader-next')));
  }
}

void main() {
  testWidgets('guided steps bridge the rule and parameter controls', (
    tester,
  ) async {
    final lesson = await loadLesson(tester);
    await tester.pumpWidget(
      MaterialApp(home: ShaderPlaygroundPage(loadLesson: () async => lesson)),
    );
    await tester.pumpAndSettle();
    expect(parameters(tester).effect, ShaderEffect.solid);
    expect(find.byKey(const Key('shader-answer')), findsNothing);
    await tapVisible(tester, find.byKey(const Key('shader-reveal')));
    expect(find.byKey(const Key('shader-answer')), findsOneWidget);
    await advanceTo(tester, 1);
    expect(parameters(tester).effect, ShaderEffect.split);
    expect(find.byKey(const Key('shader-answer')), findsNothing);
    await tapVisible(tester, find.text('选点 U=0.75'));
    expect(find.textContaining('0.75 < 0.5 为假'), findsOneWidget);
    expect(find.textContaining('起始色 0%，结束色 100%'), findsOneWidget);
    await tapVisible(tester, find.byKey(const Key('shader-next')));
    expect(parameters(tester).effect, ShaderEffect.gradient);
    await tapVisible(tester, find.byKey(const Key('shader-next')));
    expect(parameters(tester).vertical, isTrue);
    await tapVisible(tester, find.text('横向渐变'));
    expect(parameters(tester).vertical, isFalse);
    await tapVisible(tester, find.byKey(const Key('shader-next')));
    await tester.ensureVisible(find.byKey(const Key('shader-offset')));
    await tester.drag(
      find.byKey(const Key('shader-offset')),
      const Offset(120, 0),
    );
    await tester.pump();
    expect(parameters(tester).offset, greaterThan(0));
    await tapVisible(tester, find.text('交换颜色'));
    expect(parameters(tester).startColor, const ShaderParameters().endColor);
    await tapVisible(tester, find.text('复位本步'));
    expect(parameters(tester).offset, 0);
    await tapVisible(tester, find.text('展开完整 GLSL 源码'));
    expect(find.text(lesson.source), findsOneWidget);
    for (final step in shaderSteps) {
      for (final pattern in step.lines) {
        expect(lesson.source, contains(pattern));
      }
    }
    await tester.pumpWidget(const SizedBox.shrink());
    expect(lesson.shader.debugDisposed, isTrue);
  });

  testWidgets('UV mode disables controls without changing lesson progress', (
    tester,
  ) async {
    final lesson = await loadLesson(tester);
    await tester.pumpWidget(
      MaterialApp(home: ShaderPlaygroundPage(loadLesson: () async => lesson)),
    );
    await tester.pumpAndSettle();
    await advanceTo(tester, 4);
    await tapVisible(tester, find.byKey(const Key('shader-uv-toggle')));
    expect(parameters(tester).showUv, isTrue);
    expect(
      tester.widget<Slider>(find.byKey(const Key('shader-offset'))).onChanged,
      isNull,
    );
    await tapVisible(tester, find.text('复位本步'));
    expect(parameters(tester).showUv, isFalse);
    expect(
      tester.widget<Slider>(find.byKey(const Key('shader-offset'))).onChanged,
      isNotNull,
    );
  });

  testWidgets(
    'sweep is explicit, tunable, and stops on lifecycle and step changes',
    (tester) async {
      final lesson = await loadLesson(tester);
      await tester.pumpWidget(
        MaterialApp(home: ShaderPlaygroundPage(loadLesson: () async => lesson)),
      );
      await tester.pumpAndSettle();
      await advanceTo(tester, 5);
      expect(parameters(tester).phase, 0.5);
      await tester.pump(const Duration(seconds: 1));
      expect(parameters(tester).phase, 0.5);
      await tester.ensureVisible(find.byKey(const Key('shader-play')));
      await tester.tap(find.byKey(const Key('shader-play')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(parameters(tester).phase, isNot(0.5));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      final paused = parameters(tester).phase;
      await tester.pump(const Duration(seconds: 1));
      expect(parameters(tester).phase, paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tapVisible(tester, find.text('对照：窄而柔和'));
      expect(parameters(tester).bandWidth, 0.15);
      expect(parameters(tester).softness, 0.9);
      expect(parameters(tester).phase, 0.5);
      await tapVisible(tester, find.text('对照：宽而清晰'));
      expect(parameters(tester).bandWidth, 0.4);
      await tapVisible(tester, find.byKey(const Key('shader-previous')));
      expect(parameters(tester).effect, ShaderEffect.gradient);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('reduced motion keeps sweep manual', (tester) async {
    final lesson = await loadLesson(tester);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        home: ShaderPlaygroundPage(loadLesson: () async => lesson),
      ),
    );
    await tester.pumpAndSettle();
    await advanceTo(tester, 5);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('shader-play')))
          .onPressed,
      isNull,
    );
    await tester.ensureVisible(find.byKey(const Key('shader-phase')));
    await tester.drag(
      find.byKey(const Key('shader-phase')),
      const Offset(60, 0),
    );
    await tester.pumpAndSettle();
    expect(parameters(tester).phase, isNot(0.5));
  });

  testWidgets('intro and actual shader lessons link through stable routes', (
    tester,
  ) async {
    final lesson = await loadLesson(tester);
    final router = GoRouter(
      initialLocation: '/pixel-shader-intro',
      routes: [
        GoRoute(
          path: '/pixel-shader-intro',
          builder: (_, __) => const PixelShaderIntroEntry(),
        ),
        GoRoute(
          path: '/shader-playground',
          builder: (_, __) =>
              ShaderPlaygroundPage(loadLesson: () async => lesson),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    for (var i = 0; i < 2; i++) {
      await tapVisible(tester, find.byKey(const Key('intro-next')));
    }
    await tapVisible(tester, find.byKey(const Key('intro-continue-shader')));
    expect(find.text('先输出一种颜色'), findsOneWidget);
    await tapVisible(tester, find.text('返回基础：从画形状到算颜色'));
    expect(find.text('第 1 步 / 共 3 步'), findsOneWidget);
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
      await advanceTo(tester, 5);
      await tester.ensureVisible(find.text('复位本步'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('复位本步'));
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
    for (final effect in ShaderEffect.values) {
      for (final phase in [0.0, 0.5, 1.0]) {
        for (final softness in [0.05, 1.0]) {
          final values = redBlue.copyWith(
            effect: effect,
            phase: phase,
            softness: softness,
            bandWidth: 0.25,
          );
          for (final x in [10, 32, 49, 50, 75, 90]) {
            final rendered = await pixel(values, const Size(100, 50), x, 25);
            final explained = values.colorAt(
              Offset((x + 0.5) / 100, 25.5 / 50),
            );
            expect(
              rendered[0],
              closeTo(explained.r * 255, 2),
              reason: '$effect/$phase/$softness/$x',
            );
            expect(rendered[2], closeTo(explained.b * 255, 2));
          }
        }
      }
    }
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
