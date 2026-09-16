import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_forge_app/app/router/app_route_table.dart';
import 'package:flutter_forge_app/module_registry/module_catalog_utils.dart';
import 'package:flutter_forge_app/module_registry/module_category.dart';
import 'package:flutter_forge_app/modules/ui/flutter_scene_3d/module_root.dart';
import 'package:flutter_forge_app/modules/ui/flutter_scene_3d/scene_camera_controller.dart';
import 'package:flutter_forge_app/modules/ui/flutter_scene_3d/scene_runtime.dart';
import 'package:flutter_forge_app/modules/ui/flutter_scene_3d/scene_selection_controller.dart';

void main() {
  testWidgets('shows title, learning content, and semantic controls', (
    tester,
  ) async {
    final runtime = FakeSceneRuntime();
    await tester.pumpWidget(
      MaterialApp(home: FlutterScene3dPage(runtime: runtime)),
    );
    await tester.pump();

    expect(find.text('教学型 3D 查看器'), findsOneWidget);
    expect(find.text('设备部件检查'), findsOneWidget);
    expect(find.textContaining('Scene、Node、Mesh'), findsOneWidget);
    for (final label in ['向左环绕', '向右环绕', '拉近相机', '拉远相机', '暂停环绕', '重置相机']) {
      expect(find.byTooltip(label), findsOneWidget);
    }

    await tester.tap(find.byTooltip('暂停环绕'));
    await tester.pump();
    expect(find.byTooltip('继续环绕'), findsOneWidget);
    expect(find.textContaining('状态：已暂停'), findsOneWidget);
  });

  testWidgets('enhanced mode supports drag takeover and mode comparison', (
    tester,
  ) async {
    final runtime = FakeSceneRuntime();
    await tester.pumpWidget(
      MaterialApp(home: FlutterScene3dPage(runtime: runtime)),
    );
    await tester.pump();

    await tester.fling(
      find.byKey(const Key('scene-interaction-surface')),
      const Offset(80, -40),
      1200,
    );
    await tester.pump();
    expect(runtime.camera.motionState, SceneMotionState.coasting);
    expect(find.textContaining('状态：惯性滑行'), findsOneWidget);

    await tester.tap(find.byKey(const Key('basic-mode')));
    await tester.pump();
    expect(runtime.camera.enhancedMode, isFalse);
    expect(find.textContaining('离散控制效果'), findsOneWidget);
  });

  testWidgets('reduced motion disables automatic and inertial motion', (
    tester,
  ) async {
    final runtime = FakeSceneRuntime();
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: MaterialApp(home: FlutterScene3dPage(runtime: runtime)),
      ),
    );
    await tester.pump();

    expect(runtime.camera.reducedMotion, isTrue);
    expect(runtime.camera.motionState, SceneMotionState.paused);
    expect(find.byKey(const Key('reduced-motion-status')), findsOneWidget);
  });

  testWidgets('basic mode blocks wheel zoom', (tester) async {
    final runtime = FakeSceneRuntime();
    await tester.pumpWidget(
      MaterialApp(home: FlutterScene3dPage(runtime: runtime)),
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('basic-mode')));
    await tester.pump();

    await tester.sendEventToBinding(
      PointerScrollEvent(
        position: tester.getCenter(
          find.byKey(const Key('scene-interaction-surface')),
        ),
        scrollDelta: const Offset(0, 100),
      ),
    );
    await tester.pump();

    expect(runtime.camera.distance, SceneCameraController.initialDistance);
  });

  testWidgets('keyboard remains active after selecting a mode control', (
    tester,
  ) async {
    final runtime = FakeSceneRuntime();
    await tester.pumpWidget(
      MaterialApp(home: FlutterScene3dPage(runtime: runtime)),
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('basic-mode')));
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();

    expect(runtime.camera.yaw, closeTo(0.15, 0.001));
  });

  testWidgets('held arrow keys consume repeat events inside the viewer', (
    tester,
  ) async {
    final runtime = FakeSceneRuntime();
    var escapedArrowRepeats = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Focus(
          onKeyEvent: (_, event) {
            if (event is KeyRepeatEvent &&
                event.logicalKey == LogicalKeyboardKey.arrowLeft) {
              escapedArrowRepeats++;
            }
            return KeyEventResult.ignored;
          },
          child: FlutterScene3dPage(runtime: runtime),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('basic-mode')));
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowLeft);
    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.arrowLeft);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();

    expect(runtime.camera.yaw, closeTo(-0.30, 0.001));
    expect(escapedArrowRepeats, 0);
  });

  testWidgets('top-right orientation thumbnail previews and resets camera', (
    tester,
  ) async {
    final runtime = FakeSceneRuntime();
    await tester.pumpWidget(
      MaterialApp(home: FlutterScene3dPage(runtime: runtime)),
    );
    await tester.pump();
    final surface = find.byKey(const Key('scene-interaction-surface'));
    final thumbnail = find.byKey(const Key('scene-orientation-thumbnail'));

    expect(thumbnail, findsOneWidget);
    final surfaceRect = tester.getRect(surface);
    final thumbnailRect = tester.getRect(thumbnail);
    expect(thumbnailRect.top, closeTo(surfaceRect.top + 12, 0.1));
    expect(thumbnailRect.right, closeTo(surfaceRect.right - 12, 0.1));

    await tester.tap(find.byKey(const Key('basic-mode')));
    runtime.camera.orbitBy(0.5);
    expect(runtime.camera.yaw, 0.5);
    await tester.tap(thumbnail);
    await tester.pump();
    expect(runtime.camera.yaw, 0);
  });

  testWidgets('tap selects a part and focus targets its center', (
    tester,
  ) async {
    final runtime = FakeSceneRuntime();
    await tester.pumpWidget(
      MaterialApp(home: FlutterScene3dPage(runtime: runtime)),
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('scene-interaction-surface')));
    await tester.pump();
    expect(find.text('机身'), findsOneWidget);

    final focusButton = find.byKey(const Key('focus-selected-part'));
    await tester.ensureVisible(focusButton);
    await tester.pump();
    await tester.tap(focusButton);
    await tester.pump();
    runtime.camera.tick(Duration.zero);
    runtime.camera.tick(const Duration(milliseconds: 350));
    expect(runtime.camera.targetX, -1.4);
  });

  testWidgets('shows loading state', (tester) async {
    final runtime = FakeSceneRuntime(initialization: Completer<void>().future);
    await tester.pumpWidget(
      MaterialApp(home: FlutterScene3dPage(runtime: runtime)),
    );

    expect(find.byKey(const Key('scene-loading')), findsOneWidget);
    expect(find.text('正在准备 3D 场景'), findsOneWidget);
  });

  testWidgets('shows initialization error state', (tester) async {
    final initialization = Completer<void>();
    final runtime = FakeSceneRuntime(initialization: initialization.future);
    await tester.pumpWidget(
      MaterialApp(home: FlutterScene3dPage(runtime: runtime)),
    );
    initialization.completeError(StateError('gpu unavailable'));
    await tester.pump();

    expect(find.byKey(const Key('scene-error')), findsOneWidget);
    expect(find.textContaining('Flutter GPU 已启用'), findsOneWidget);
  });

  test('catalog registers ready macOS-only module and route', () {
    final module = AppRouteTable.modules.singleWhere(
      (item) => item.path == '/flutter-scene-3d',
    );

    expect(module.status, ModuleStatus.ready);
    expect(module.supportedPlatforms, {TargetPlatform.macOS});
    expect(isModuleAvailable(module, TargetPlatform.macOS), isTrue);
    for (final platform in [
      TargetPlatform.windows,
      TargetPlatform.android,
      TargetPlatform.iOS,
      TargetPlatform.linux,
      TargetPlatform.fuchsia,
    ]) {
      expect(isModuleAvailable(module, platform), isFalse);
    }
    expect(
      AppRouteTable.routes.where((route) => route.path == module.path),
      defaultTargetPlatform == TargetPlatform.macOS ? isNotEmpty : isEmpty,
    );
  });
}

class FakeSceneRuntime implements SceneDemoRuntime {
  FakeSceneRuntime({Future<void>? initialization})
    : _initialization = initialization ?? Future<void>.value();

  final Future<void> _initialization;
  @override
  final SceneCameraController camera = SceneCameraController();
  @override
  final SceneSelectionController selection = SceneSelectionController();

  @override
  Widget buildView() =>
      const ColoredBox(key: Key('fake-scene-view'), color: Colors.black);

  @override
  Future<void> initialize() => _initialization;

  @override
  void clearSelection() => selection.clear();

  @override
  void focusSelection() {
    final selected = selection.selected;
    if (selected == null) return;
    camera.focusOn(
      x: selected.centerX,
      y: selected.centerY,
      z: selected.centerZ,
    );
  }

  @override
  void selectAt(Offset position, Size viewSize) {
    selection.select(
      const ScenePartHit(
        id: 'cuboid',
        label: '机身',
        centerX: -1.4,
        centerY: 0,
        centerZ: 0,
        distance: 3.2,
        normalX: 0,
        normalY: 1,
        normalZ: 0,
      ),
    );
  }
}
