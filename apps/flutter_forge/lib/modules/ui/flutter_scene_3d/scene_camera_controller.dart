import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';

enum SceneMotionState { autoTour, manual, coasting, paused, transitioning }

class SceneCameraController extends ChangeNotifier {
  static const initialDistance = 4.0;
  static const minDistance = 1.8;
  static const maxDistance = 12.0;
  static const initialPitch = 0.5;
  static const minPitch = -20 * math.pi / 180;
  static const maxPitch = 60 * math.pi / 180;
  static const _dragSensitivity = 0.008;
  static const _coastDuration = Duration(milliseconds: 650);

  double _yaw = 0;
  double _pitch = initialPitch;
  double _distance = initialDistance;
  double _targetX = 0;
  double _targetY = 0;
  double _targetZ = 0;
  double _coastYawVelocity = 0;
  double _coastPitchVelocity = 0;
  Duration _coastElapsed = Duration.zero;
  Duration? _previousElapsed;
  bool _enhancedMode = true;
  bool _reducedMotion = false;
  SceneMotionState _motionState = SceneMotionState.autoTour;
  _CameraTransition? _transition;

  double get yaw => _yaw;
  double get pitch => _pitch;
  double get distance => _distance;
  double get zoomScale => initialDistance / _distance;
  double get targetX => _targetX;
  double get targetY => _targetY;
  double get targetZ => _targetZ;
  bool get enhancedMode => _enhancedMode;
  bool get reducedMotion => _reducedMotion;
  SceneMotionState get motionState => _motionState;

  void tick(Duration elapsed) {
    final previous = _previousElapsed;
    _previousElapsed = elapsed;
    if (previous == null) return;
    final delta = elapsed - previous;
    if (delta <= Duration.zero) return;

    final transition = _transition;
    if (transition != null) {
      transition.elapsed += delta;
      final raw =
          transition.elapsed.inMicroseconds /
          transition.duration.inMicroseconds;
      final t = _easeOutCubic(raw.clamp(0.0, 1.0));
      _yaw = _lerp(transition.startYaw, transition.targetYaw, t);
      _pitch = _lerp(transition.startPitch, transition.targetPitch, t);
      _distance = _lerp(transition.startDistance, transition.targetDistance, t);
      _targetX = _lerp(transition.startTargetX, transition.targetTargetX, t);
      _targetY = _lerp(transition.startTargetY, transition.targetTargetY, t);
      _targetZ = _lerp(transition.startTargetZ, transition.targetTargetZ, t);
      if (raw >= 1) {
        _transition = null;
        _motionState = transition.resumeAuto && !_reducedMotion
            ? SceneMotionState.autoTour
            : SceneMotionState.manual;
      }
      return;
    }

    final seconds = delta.inMicroseconds / Duration.microsecondsPerSecond;
    if (_motionState == SceneMotionState.autoTour && !_reducedMotion) {
      _yaw += seconds * 0.35;
    } else if (_motionState == SceneMotionState.coasting) {
      _coastElapsed += delta;
      final progress =
          _coastElapsed.inMicroseconds / _coastDuration.inMicroseconds;
      if (progress >= 1) {
        _motionState = SceneMotionState.manual;
        _coastYawVelocity = 0;
        _coastPitchVelocity = 0;
      } else {
        final strength = (1 - progress) * (1 - progress);
        _yaw += _coastYawVelocity * seconds * strength;
        _pitch = (_pitch + _coastPitchVelocity * seconds * strength).clamp(
          minPitch,
          maxPitch,
        );
      }
    }
  }

  void beginInteraction() {
    if (!_enhancedMode) return;
    _cancelMotion();
    _motionState = SceneMotionState.manual;
    notifyListeners();
  }

  void dragBy(Offset delta) {
    if (!_enhancedMode) return;
    _yaw -= delta.dx * _dragSensitivity;
    _pitch = (_pitch - delta.dy * _dragSensitivity).clamp(minPitch, maxPitch);
    _motionState = SceneMotionState.manual;
    notifyListeners();
  }

  void endInteraction(Offset velocity) {
    if (!_enhancedMode || _reducedMotion) return;
    final angularVelocity = Offset(
      -velocity.dx * _dragSensitivity,
      -velocity.dy * _dragSensitivity,
    );
    if (angularVelocity.distance < 0.35) return;
    _coastYawVelocity = angularVelocity.dx.clamp(-4.0, 4.0);
    _coastPitchVelocity = angularVelocity.dy.clamp(-3.0, 3.0);
    _coastElapsed = Duration.zero;
    _motionState = SceneMotionState.coasting;
    notifyListeners();
  }

  void orbitBy(double radians) {
    _cancelMotion();
    if (_enhancedMode && !_reducedMotion) {
      _animateTo(
        yaw: _yaw + radians,
        duration: const Duration(milliseconds: 180),
      );
    } else {
      _yaw += radians;
      _motionState = SceneMotionState.manual;
    }
    notifyListeners();
  }

  void zoomBy(double delta) {
    _cancelMotion();
    _distance = (_distance + delta).clamp(minDistance, maxDistance);
    _motionState = SceneMotionState.manual;
    notifyListeners();
  }

  void animateZoomBy(double delta) {
    _cancelMotion();
    final target = (_distance + delta).clamp(minDistance, maxDistance);
    if (_enhancedMode && !_reducedMotion) {
      _animateTo(distance: target, duration: const Duration(milliseconds: 180));
    } else {
      _distance = target;
      _motionState = SceneMotionState.manual;
    }
    notifyListeners();
  }

  void togglePaused() {
    _cancelMotion();
    _motionState = _motionState == SceneMotionState.paused
        ? (_reducedMotion ? SceneMotionState.manual : SceneMotionState.autoTour)
        : SceneMotionState.paused;
    notifyListeners();
  }

  void reset() {
    _cancelMotion();
    if (_enhancedMode && !_reducedMotion) {
      _animateTo(
        yaw: 0,
        pitch: initialPitch,
        distance: initialDistance,
        targetX: 0,
        targetY: 0,
        targetZ: 0,
        duration: const Duration(milliseconds: 350),
        resumeAuto: true,
      );
    } else {
      _yaw = 0;
      _pitch = initialPitch;
      _distance = initialDistance;
      _targetX = 0;
      _targetY = 0;
      _targetZ = 0;
      _motionState = _reducedMotion
          ? SceneMotionState.paused
          : SceneMotionState.autoTour;
    }
    _previousElapsed = null;
    notifyListeners();
  }

  void focusOn({required double x, required double y, required double z}) {
    _cancelMotion();
    if (_reducedMotion) {
      _targetX = x;
      _targetY = y;
      _targetZ = z;
      _distance = 3;
      _motionState = SceneMotionState.manual;
    } else {
      _animateTo(
        targetX: x,
        targetY: y,
        targetZ: z,
        distance: 3,
        duration: const Duration(milliseconds: 350),
      );
    }
    notifyListeners();
  }

  void setEnhancedMode(bool value) {
    if (_enhancedMode == value) return;
    final interruptedMotion =
        _motionState == SceneMotionState.transitioning ||
        _motionState == SceneMotionState.coasting;
    _cancelMotion();
    _enhancedMode = value;
    if (interruptedMotion) {
      _motionState = _reducedMotion
          ? SceneMotionState.paused
          : SceneMotionState.manual;
    }
    notifyListeners();
  }

  void setReducedMotion(bool value) {
    if (_reducedMotion == value) return;
    _cancelMotion();
    _reducedMotion = value;
    _motionState = value ? SceneMotionState.paused : SceneMotionState.autoTour;
    _previousElapsed = null;
    notifyListeners();
  }

  void _animateTo({
    double? yaw,
    double? pitch,
    double? distance,
    double? targetX,
    double? targetY,
    double? targetZ,
    required Duration duration,
    bool resumeAuto = false,
  }) {
    _transition = _CameraTransition(
      startYaw: _yaw,
      targetYaw: yaw ?? _yaw,
      startPitch: _pitch,
      targetPitch: pitch ?? _pitch,
      startDistance: _distance,
      targetDistance: distance ?? _distance,
      startTargetX: _targetX,
      targetTargetX: targetX ?? _targetX,
      startTargetY: _targetY,
      targetTargetY: targetY ?? _targetY,
      startTargetZ: _targetZ,
      targetTargetZ: targetZ ?? _targetZ,
      duration: duration,
      resumeAuto: resumeAuto,
    );
    _motionState = SceneMotionState.transitioning;
  }

  void _cancelMotion() {
    _transition = null;
    _coastYawVelocity = 0;
    _coastPitchVelocity = 0;
    _coastElapsed = Duration.zero;
  }

  static double _easeOutCubic(double value) =>
      1 - math.pow(1 - value, 3).toDouble();
  static double _lerp(double start, double end, double t) =>
      start + (end - start) * t;
}

class _CameraTransition {
  _CameraTransition({
    required this.startYaw,
    required this.targetYaw,
    required this.startPitch,
    required this.targetPitch,
    required this.startDistance,
    required this.targetDistance,
    required this.startTargetX,
    required this.targetTargetX,
    required this.startTargetY,
    required this.targetTargetY,
    required this.startTargetZ,
    required this.targetTargetZ,
    required this.duration,
    required this.resumeAuto,
  });

  final double startYaw;
  final double targetYaw;
  final double startPitch;
  final double targetPitch;
  final double startDistance;
  final double targetDistance;
  final double startTargetX;
  final double targetTargetX;
  final double startTargetY;
  final double targetTargetY;
  final double startTargetZ;
  final double targetTargetZ;
  final Duration duration;
  final bool resumeAuto;
  Duration elapsed = Duration.zero;
}
