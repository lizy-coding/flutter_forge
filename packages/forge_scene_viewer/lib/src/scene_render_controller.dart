import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import 'scene_camera_controller.dart';
import 'scene_render_metrics.dart';

enum SceneRenderMode { onDemand, continuous, manual }

class _RepaintSignal extends ChangeNotifier {
  void request() => notifyListeners();
}

/// Controls scene scheduling separately from sampling and diagnostic UI updates.
class SceneRenderController extends ChangeNotifier {
  SceneRenderController({required this.camera, Duration Function()? now})
    : _now = now ?? (Stopwatch()..start()).elapsedGetter {
    camera.addListener(_cameraChanged);
  }

  final SceneCameraController camera;
  final Duration Function() _now;
  final SceneRenderMetrics metrics = SceneRenderMetrics();
  final _RepaintSignal _repaint = _RepaintSignal();
  final ValueNotifier<bool> ticking = ValueNotifier(false);
  final Set<String> _pending = {};
  Timer? _publication;
  bool _unmountedPublication = false;
  Timer? _rateExpiry;
  Duration? _lastDriverElapsed;
  Duration _simulationElapsed = Duration.zero;
  bool _advancing = false;
  bool _disposed = false;
  bool _ready = false;
  bool _visible = true;
  bool _failed = false;
  bool _driverAttached = false;
  SceneRenderMode _mode = SceneRenderMode.onDemand;
  Future<SceneCaptureSnapshot> Function()? captureDelegate;
  bool capturing = false;
  SceneCaptureSnapshot? capture;
  int _samplingGeneration = 0;

  Listenable get repaint => _repaint;
  SceneRenderMode get mode => _mode;
  bool get ready => _ready;
  bool get visible => _visible;
  bool get isDisposed => _disposed;
  bool get isFaulted => _failed;
  bool get canManipulate => _mode != SceneRenderMode.manual;
  Duration get now => _now();
  int get callRate => metrics.callsInLastSecond(now);

  void markReady() {
    if (_disposed) return;
    _ready = true;
    requestFrame('初始化', force: true);
    _synchronize();
  }

  void attachDriver() {
    if (_driverAttached) {
      throw StateError('A render controller supports one mounted scene view.');
    }
    _driverAttached = true;
    _synchronize();
  }

  void detachDriver() {
    _driverAttached = false;
    _publication?.cancel();
    _publication = null;
    _rateExpiry?.cancel();
    _rateExpiry = null;
    stopSampling();
    _synchronize();
  }

  void setVisible(bool value) {
    if (_disposed || _visible == value) return;
    _visible = value;
    _lastDriverElapsed = null;
    camera.resetClock();
    _synchronize();
    if (value) requestFrame('恢复可见', force: true);
    _publishLater();
  }

  void setMode(SceneRenderMode value) {
    if (_disposed || _mode == value) return;
    _mode = value;
    if (value == SceneRenderMode.manual) camera.pauseMotion();
    _lastDriverElapsed = null;
    camera.resetClock();
    metrics.event(now, '绘制模式：${value.name}');
    _synchronize();
    notifyListeners();
  }

  void _cameraChanged() {
    if (_disposed || _advancing) return;
    requestFrame('相机');
    _synchronize();
  }

  void _synchronize() {
    final next =
        !_disposed &&
        _ready &&
        _visible &&
        _driverAttached &&
        !_failed &&
        (_mode == SceneRenderMode.continuous ||
            (_mode == SceneRenderMode.onDemand && camera.hasMotion));
    if (next != ticking.value) {
      _lastDriverElapsed = null;
      camera.resetClock();
      ticking.value = next;
    }
  }

  /// Advances the simulation only while its scene driver is active.
  void onTick(Duration elapsed) {
    if (_disposed || !ticking.value) return;
    final previous = _lastDriverElapsed;
    _lastDriverElapsed = elapsed;
    if (previous != null && elapsed >= previous) {
      _simulationElapsed += elapsed - previous;
    }
    _advancing = true;
    try {
      camera.tick(_simulationElapsed);
    } finally {
      _advancing = false;
    }
    requestFrame(camera.hasMotion ? '动画' : '持续绘制', force: true);
    _synchronize();
  }

  void requestFrame(String reason, {bool force = false}) {
    if (_disposed ||
        (!_visible && !force) ||
        (_mode == SceneRenderMode.manual && !force)) {
      return;
    }
    metrics.request(reason, merged: _pending.isNotEmpty);
    _pending.add(reason);
    _repaint.request();
    _publishLater();
  }

  void redrawOnce() {
    if (!_ready || _disposed) return;
    _failed = false;
    requestFrame('单帧重绘', force: true);
  }

  /// Measures an actual scene render invocation, not a ticker callback.
  void measureRender(
    VoidCallback render, {
    required Map<String, Object?> specification,
  }) {
    if (_disposed) return;
    final reason = _pending.isEmpty ? '布局或外部重绘' : _pending.join('、');
    final isCapture = _pending.contains('单帧抓取');
    _pending.clear();
    metrics.specification = Map.unmodifiable(specification);
    final watch = metrics.sampling ? (Stopwatch()..start()) : null;
    Object? failure;
    try {
      render();
    } catch (error) {
      failure = error;
      _failed = true;
    } finally {
      watch?.stop();
      metrics.rendered(
        now,
        watch?.elapsedMicroseconds,
        reason: reason,
        error: failure,
        capture: isCapture,
      );
      _synchronize();
      _publishLater();
      _rateExpiry?.cancel();
      _rateExpiry = Timer(const Duration(seconds: 1), () {
        if (!_disposed) {
          metrics.callsInLastSecond(now);
          notifyListeners();
        }
      });
    }
  }

  void startSampling() {
    if (_disposed || metrics.sampling) return;
    metrics.sampling = true;
    _samplingGeneration++;
    SchedulerBinding.instance.addTimingsCallback(_timings);
    metrics.event(now, '开始采样');
    notifyListeners();
  }

  void stopSampling() {
    if (!metrics.sampling) return;
    metrics.sampling = false;
    _samplingGeneration++;
    SchedulerBinding.instance.removeTimingsCallback(_timings);
    metrics.event(now, '停止采样');
    if (!_disposed) notifyListeners();
  }

  double refreshRate = 60;

  void _timings(List<FrameTiming> values) {
    if (_disposed || !metrics.sampling || !_visible) return;
    final budget = (1000000 / refreshRate).round();
    for (final value in values) {
      metrics.windowFrame(
        SceneWindowFrameSample(
          now,
          value.buildDuration.inMicroseconds,
          value.rasterDuration.inMicroseconds,
          budget,
        ),
      );
    }
    if (ticking.value) _publishLater();
  }

  void clearStatistics() {
    if (_disposed) return;
    metrics.clear();
    capture = null;
    notifyListeners();
  }

  Future<void> captureFrame() async {
    if (_disposed || !_ready || capturing) return;
    final delegate = captureDelegate;
    if (delegate == null) {
      reportError(StateError('当前运行时未提供单帧抓取'));
      return;
    }
    capturing = true;
    notifyListeners();
    try {
      final result = await delegate();
      if (!_disposed) {
        capture = result;
        metrics.event(now, '完成单帧抓取（${result.passes.length} Pass）');
      }
    } catch (error) {
      if (!_disposed) metrics.reportError(now, error);
    } finally {
      capturing = false;
      if (!_disposed) notifyListeners();
    }
  }

  void reportError(Object error) {
    if (_disposed) return;
    metrics.reportError(now, error);
    _publishLater();
  }

  String diagnosticJson() => const JsonEncoder.withIndent('  ').convert({
    'schema': 'forge_scene_viewer.diagnostics.v1',
    'build_mode': kReleaseMode
        ? 'release'
        : kProfileMode
        ? 'profile'
        : 'debug',
    'platform': kIsWeb ? 'web' : defaultTargetPlatform.name,
    'render_mode': mode.name,
    'motion_state': camera.motionState.name,
    'visible': visible,
    'driver_active': ticking.value,
    'render_failed': isFaulted,
    'sampling_generation': _samplingGeneration,
    'metrics': metrics.snapshot(now),
    'capture': capture?.toJson(),
    'scope':
        'Scene CPU calls and Flutter window timings; GPU completion is not measured.',
  });

  void _publishLater() {
    if (_disposed) return;
    if (!_driverAttached) {
      if (_unmountedPublication) return;
      _unmountedPublication = true;
      scheduleMicrotask(() {
        _unmountedPublication = false;
        if (!_disposed && !_driverAttached) notifyListeners();
      });
      return;
    }
    if (_publication != null) return;
    _publication = Timer(const Duration(milliseconds: 500), () {
      _publication = null;
      if (_disposed) return;
      if (metrics.sampling) metrics.trim(now);
      notifyListeners();
    });
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    stopSampling();
    camera.removeListener(_cameraChanged);
    _publication?.cancel();
    _rateExpiry?.cancel();
    ticking.value = false;
    ticking.dispose();
    _repaint.dispose();
    super.dispose();
  }
}

extension on Stopwatch {
  Duration Function() get elapsedGetter =>
      () => elapsed;
}
