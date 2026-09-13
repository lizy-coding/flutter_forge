import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_forge_app/app/router/app_route_table.dart';
import 'package:flutter_forge_app/module_registry/module_catalog_utils.dart';
import 'package:flutter_forge_app/module_registry/module_category.dart';
import 'package:flutter_forge_app/modules/ui/flutter_scene_3d/module_root.dart';
import 'package:flutter_forge_app/modules/ui/flutter_scene_3d/scene_runtime.dart';

void main() {
  testWidgets('shows title, learning content, and semantic controls', (
    tester,
  ) async {
    final runtime = FakeSceneRuntime();
    await tester.pumpWidget(
      MaterialApp(home: FlutterScene3dPage(runtime: runtime)),
    );
    await tester.pump();

    expect(find.text('Flutter Scene 3D 入门'), findsOneWidget);
    expect(find.text('交互长方体'), findsOneWidget);
    expect(find.textContaining('Scene、Node、Mesh'), findsOneWidget);
    for (final label in ['向左环绕', '向右环绕', '拉近相机', '拉远相机', '暂停环绕', '重置相机']) {
      expect(find.byTooltip(label), findsOneWidget);
    }

    await tester.tap(find.byTooltip('暂停环绕'));
    await tester.pump();
    expect(find.byTooltip('继续环绕'), findsOneWidget);
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
  bool _paused = false;
  double _zoom = 4;

  @override
  bool get isPaused => _paused;

  @override
  double get zoom => _zoom;

  @override
  Widget buildView() =>
      const ColoredBox(key: Key('fake-scene-view'), color: Colors.black);

  @override
  Future<void> initialize() => _initialization;

  @override
  void orbitBy(double radians) {}

  @override
  void resetCamera() {
    _paused = false;
    _zoom = 4;
  }

  @override
  void togglePaused() => _paused = !_paused;

  @override
  void zoomBy(double delta) => _zoom += delta;
}
