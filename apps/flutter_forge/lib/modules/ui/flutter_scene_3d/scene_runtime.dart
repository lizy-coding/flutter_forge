import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;

/// Module-local boundary around flutter_scene's pre-1.0 API.
abstract interface class SceneDemoRuntime {
  Future<void> initialize();

  Widget buildView();

  bool get isPaused;

  double get zoom;

  void orbitBy(double radians);

  void zoomBy(double delta);

  void togglePaused();

  void resetCamera();
}

class FlutterSceneRuntime implements SceneDemoRuntime {
  final Scene _scene = Scene();
  double _orbitOffset = 0;
  double _distance = 4;
  double _animatedAngle = 0;
  Duration? _previousElapsed;
  bool _paused = false;

  @override
  bool get isPaused => _paused;

  @override
  double get zoom => _distance;

  @override
  Future<void> initialize() async {
    await Scene.initializeStaticResources();
    _scene.add(
      Node(
        mesh: Mesh(
          CuboidGeometry(vm.Vector3(1.8, 1.2, 1)),
          PhysicallyBasedMaterial(),
        ),
      ),
    );
  }

  @override
  Widget buildView() {
    return SceneView(
      _scene,
      cameraBuilder: (elapsed) {
        final previous = _previousElapsed;
        _previousElapsed = elapsed;
        if (!_paused && previous != null) {
          _animatedAngle +=
              (elapsed - previous).inMicroseconds /
              Duration.microsecondsPerSecond *
              0.35;
        }
        final angle = _animatedAngle + _orbitOffset;
        return PerspectiveCamera(
          position: vm.Vector3(
            math.sin(angle) * _distance,
            2.2,
            -math.cos(angle) * _distance,
          ),
          target: vm.Vector3.zero(),
        );
      },
    );
  }

  @override
  void orbitBy(double radians) => _orbitOffset += radians;

  @override
  void zoomBy(double delta) {
    _distance = (_distance + delta).clamp(2.4, 7).toDouble();
  }

  @override
  void togglePaused() => _paused = !_paused;

  @override
  void resetCamera() {
    _orbitOffset = 0;
    _animatedAngle = 0;
    _distance = 4;
    _previousElapsed = null;
    _paused = false;
  }
}
