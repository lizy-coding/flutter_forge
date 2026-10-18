import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;

import 'scene_camera_controller.dart';
import 'scene_selection_controller.dart';
import 'scene_part_definition.dart';
import 'scene_render_controller.dart';
import 'scene_render_metrics.dart';
import 'scene_render_surface.dart';

/// A scene-viewing boundary with explicit ownership and drawing diagnostics.
abstract interface class SceneViewerRuntime {
  Future<void> initialize();
  Widget buildView();
  SceneCameraController get camera;
  SceneSelectionController get selection;
  SceneRenderController get rendering;
  void selectAt(Offset position, Size viewSize);
  void focusSelection();
  void clearSelection();
  void dispose();
}

/// Adapts the fixed Flutter Scene version without exposing its types to callers.
class FlutterSceneViewerRuntime implements SceneViewerRuntime {
  FlutterSceneViewerRuntime({required List<ScenePartDefinition> parts})
    : parts = List.unmodifiable(parts) {
    rendering.captureDelegate = _captureFrame;
  }

  final List<ScenePartDefinition> parts;
  Scene? _scene;
  Future<void>? _initializing;
  final Map<Node, ScenePartDefinition> _parts = {};
  Completer<RenderGraphCaptureResult>? _captureCancellation;
  PerspectiveCamera? _currentCamera;
  Node? _highlightedNode;
  bool _disposed = false;
  late final Widget _view = SceneRenderSurface(
    controller: rendering,
    render: _render,
  );

  @override
  final SceneCameraController camera = SceneCameraController();
  @override
  final SceneSelectionController selection = SceneSelectionController();
  @override
  late final SceneRenderController rendering = SceneRenderController(
    camera: camera,
  );

  @override
  Future<void> initialize() {
    if (_disposed) {
      return Future.error(StateError('Scene runtime is disposed.'));
    }
    return _initializing ??= _initialize();
  }

  Future<void> _initialize() async {
    try {
      final ids = <String>{};
      for (final part in parts) {
        if (part.id.isEmpty ||
            !ids.add(part.id) ||
            [part.x, part.y, part.z].any((n) => !n.isFinite) ||
            [
              part.width,
              part.height,
              part.depth,
            ].any((n) => !n.isFinite || n <= 0)) {
          throw ArgumentError(
            'Scene parts require unique nonempty IDs, finite positions, and positive dimensions.',
          );
        }
      }
      await Scene.initializeStaticResources();
      if (_disposed) return;
      final scene = _scene = Scene();
      for (final part in parts) {
        final geometry = switch (part.shape) {
          ScenePartShape.cuboid => CuboidGeometry(
            vm.Vector3(part.width, part.height, part.depth),
          ),
          ScenePartShape.sphere => SphereGeometry(
            radius: part.width / 2,
            segments: 24,
            rings: 12,
          ),
          ScenePartShape.cylinder => CylinderGeometry(
            bottomRadius: part.width / 2,
            topRadius: part.width / 2,
            height: part.height,
            radialSegments: 24,
          ),
        };
        final node = Node(
          name: part.id,
          mesh: Mesh(geometry, PhysicallyBasedMaterial()),
        )..position = vm.Vector3(part.x, part.y, part.z);
        _parts[node] = part;
        scene.add(node);
      }
      rendering.markReady();
    } catch (error) {
      rendering.reportError(error);
      rethrow;
    }
  }

  @override
  Widget buildView() => _view;

  void _render(Canvas canvas, Size size, double dpr) {
    final scene = _scene;
    if (_disposed || scene == null) return;
    final horizontalDistance = math.cos(camera.pitch) * camera.distance;
    final target = vm.Vector3(camera.targetX, camera.targetY, camera.targetZ);
    final activeCamera = _currentCamera = PerspectiveCamera(
      position: vm.Vector3(
        target.x + math.sin(camera.yaw) * horizontalDistance,
        target.y + math.sin(camera.pitch) * camera.distance,
        target.z - math.cos(camera.yaw) * horizontalDistance,
      ),
      target: target,
    );
    rendering.measureRender(
      () => scene.render(
        activeCamera,
        canvas,
        viewport: Offset.zero & size,
        pixelRatio: dpr,
      ),
      specification: {
        'logical_width': size.width,
        'logical_height': size.height,
        'pixel_width': (size.width * dpr * scene.renderScale).ceil(),
        'pixel_height': (size.height * dpr * scene.renderScale).ceil(),
        'device_pixel_ratio': dpr,
        'render_scale': scene.renderScale,
        'anti_aliasing': scene.effectiveAntiAliasingMode.name,
        'refresh_rate_hz': rendering.refreshRate,
        'path': 'flutter_scene / Flutter GPU',
        'gpu_backend': null,
      },
    );
  }

  Future<SceneCaptureSnapshot> _captureFrame() async {
    final scene = _scene;
    if (_disposed || scene == null || !rendering.visible) {
      throw StateError('场景未就绪或不可见，无法抓取。');
    }
    _CaptureScope.acquire();
    try {
      final pending = scene.captureRenderGraph(
        request: const RenderGraphCaptureRequest(captureImages: false),
      );
      rendering.requestFrame('单帧抓取', force: true);
      final cancellation = _captureCancellation =
          Completer<RenderGraphCaptureResult>();
      final result = await Future.any<RenderGraphCaptureResult>([
        pending,
        cancellation.future,
      ]);
      return SceneCaptureSnapshot(
        width: result.pixelWidth,
        height: result.pixelHeight,
        passes: result.passes
            .map((p) => ScenePassTiming(p.name, p.cpuMicros))
            .toList(),
      );
    } finally {
      _captureCancellation = null;
      _CaptureScope.release();
    }
  }

  @override
  void selectAt(Offset position, Size viewSize) {
    final scene = _scene;
    final activeCamera = _currentCamera;
    if (_disposed ||
        !rendering.canManipulate ||
        scene == null ||
        activeCamera == null) {
      return;
    }
    final hit = scene.raycast(
      activeCamera.screenPointToRay(position, viewSize),
    );
    final part = hit == null ? null : _parts[hit.node];
    if (hit == null || part == null) {
      clearSelection();
      return;
    }
    _highlightedNode?.highlightColor = null;
    _highlightedNode = hit.node..highlightColor = vm.Vector4(.18, .65, 1, 1);
    final center = hit.node.position;
    selection.select(
      ScenePartHit(
        id: part.id,
        label: part.label,
        centerX: center.x,
        centerY: center.y,
        centerZ: center.z,
        distance: hit.distance,
        normalX: hit.worldNormal.x,
        normalY: hit.worldNormal.y,
        normalZ: hit.worldNormal.z,
      ),
    );
    rendering.requestFrame('选择');
  }

  @override
  void focusSelection() {
    final selected = selection.selected;
    if (_disposed || !rendering.canManipulate || selected == null) return;
    camera.focusOn(
      x: selected.centerX,
      y: selected.centerY,
      z: selected.centerZ,
    );
  }

  @override
  void clearSelection() {
    if (_disposed || !rendering.canManipulate) return;
    final hadSelection = selection.selected != null;
    _highlightedNode?.highlightColor = null;
    _highlightedNode = null;
    selection.clear();
    if (hadSelection) rendering.requestFrame('取消选择');
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _captureCancellation?.completeError(StateError('场景已退出，抓取取消。'));
    rendering.dispose();
    for (final node in _parts.keys) {
      _scene?.remove(node);
    }
    _parts.clear();
    _scene = null;
    _highlightedNode = null;
    _currentCamera = null;
    camera.dispose();
    selection.dispose();
  }
}

class _CaptureScope {
  static int _users = 0;
  static bool _previous = false;

  static void acquire() {
    if (_users++ == 0) {
      _previous = Scene.debugAllowRenderGraphCapture;
      Scene.debugAllowRenderGraphCapture = true;
    }
  }

  static void release() {
    if (--_users == 0) Scene.debugAllowRenderGraphCapture = _previous;
  }
}
