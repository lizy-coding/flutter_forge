import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;

import 'scene_camera_controller.dart';
import 'scene_selection_controller.dart';

/// Module-local boundary around flutter_scene's pre-1.0 API.
abstract interface class SceneDemoRuntime {
  Future<void> initialize();

  Widget buildView();

  SceneCameraController get camera;

  SceneSelectionController get selection;

  void selectAt(Offset position, Size viewSize);

  void focusSelection();

  void clearSelection();
}

class FlutterSceneRuntime implements SceneDemoRuntime {
  final Scene _scene = Scene();
  final Map<String, Node> _parts = {};
  PerspectiveCamera? _currentCamera;
  Node? _highlightedNode;

  @override
  final SceneCameraController camera = SceneCameraController();

  @override
  final SceneSelectionController selection = SceneSelectionController();

  @override
  Future<void> initialize() async {
    await Scene.initializeStaticResources();
    _addPart(
      id: 'cuboid',
      label: '机身',
      position: vm.Vector3(-1.4, 0, 0),
      geometry: CuboidGeometry(vm.Vector3(1.2, 1, 1)),
    );
    _addPart(
      id: 'sphere',
      label: '传感器',
      position: vm.Vector3(0, 0, 0),
      geometry: SphereGeometry(radius: 0.62, segments: 24, rings: 12),
    );
    _addPart(
      id: 'cylinder',
      label: '驱动轴',
      position: vm.Vector3(1.4, 0, 0),
      geometry: CylinderGeometry(
        bottomRadius: 0.55,
        topRadius: 0.55,
        height: 1.2,
        radialSegments: 24,
      ),
    );
  }

  @override
  Widget buildView() {
    return SceneView(
      _scene,
      cameraBuilder: (elapsed) {
        camera.tick(elapsed);
        final horizontalDistance = math.cos(camera.pitch) * camera.distance;
        final target = vm.Vector3(
          camera.targetX,
          camera.targetY,
          camera.targetZ,
        );
        final result = PerspectiveCamera(
          position: vm.Vector3(
            target.x + math.sin(camera.yaw) * horizontalDistance,
            target.y + math.sin(camera.pitch) * camera.distance,
            target.z - math.cos(camera.yaw) * horizontalDistance,
          ),
          target: target,
        );
        _currentCamera = result;
        return result;
      },
    );
  }

  void _addPart({
    required String id,
    required String label,
    required vm.Vector3 position,
    required Geometry geometry,
  }) {
    final node = Node(
      name: '$id|$label',
      mesh: Mesh(geometry, PhysicallyBasedMaterial()),
    )..position = position;
    _parts[id] = node;
    _scene.add(node);
  }

  @override
  void selectAt(Offset position, Size viewSize) {
    final activeCamera = _currentCamera;
    if (activeCamera == null) return;
    final hit = _scene.raycast(
      activeCamera.screenPointToRay(position, viewSize),
    );
    if (hit == null) {
      clearSelection();
      return;
    }
    final fields = hit.node.name.split('|');
    if (fields.length != 2 || !_parts.containsKey(fields.first)) {
      clearSelection();
      return;
    }
    _highlightedNode?.highlightColor = null;
    _highlightedNode = hit.node..highlightColor = vm.Vector4(0.18, 0.65, 1, 1);
    final center = hit.node.position;
    selection.select(
      ScenePartHit(
        id: fields.first,
        label: fields.last,
        centerX: center.x,
        centerY: center.y,
        centerZ: center.z,
        distance: hit.distance,
        normalX: hit.worldNormal.x,
        normalY: hit.worldNormal.y,
        normalZ: hit.worldNormal.z,
      ),
    );
  }

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
  void clearSelection() {
    _highlightedNode?.highlightColor = null;
    _highlightedNode = null;
    selection.clear();
  }
}
