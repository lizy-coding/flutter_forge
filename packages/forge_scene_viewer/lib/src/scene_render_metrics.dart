import 'dart:collection';

import 'package:flutter/foundation.dart';

/// A bounded distribution of CPU-side measurements, in microseconds.
@immutable
class SceneDurationSummary {
  const SceneDurationSummary(
    this.count,
    this.latest,
    this.p50,
    this.p95,
    this.max,
  );

  factory SceneDurationSummary.from(Iterable<int> values) {
    final original = values.toList();
    if (original.isEmpty) {
      return const SceneDurationSummary(0, null, null, null, null);
    }
    final sorted = [...original]..sort();
    int percentile(double p) =>
        sorted[((sorted.length * p).ceil() - 1).clamp(0, sorted.length - 1)];
    return SceneDurationSummary(
      sorted.length,
      original.last,
      percentile(.5),
      percentile(.95),
      sorted.last,
    );
  }

  final int count;
  final int? latest;
  final int? p50;
  final int? p95;
  final int? max;

  Map<String, Object?> toJson() => {
    'samples': count,
    'latest_us': latest,
    'p50_us': p50,
    'p95_us': p95,
    'max_us': max,
  };
}

@immutable
class SceneRenderSample {
  const SceneRenderSample(this.at, this.cpuMicros, {this.capture = false});

  final Duration at;
  final int cpuMicros;
  final bool capture;
}

@immutable
class SceneWindowFrameSample {
  const SceneWindowFrameSample(
    this.at,
    this.buildMicros,
    this.rasterMicros,
    this.budgetMicros,
  );

  final Duration at;
  final int buildMicros;
  final int rasterMicros;
  final int budgetMicros;
  bool get overBudget =>
      buildMicros > budgetMicros || rasterMicros > budgetMicros;
}

/// Metadata from a deliberately captured frame; timings are CPU timings.
@immutable
class SceneCaptureSnapshot {
  SceneCaptureSnapshot({
    required this.width,
    required this.height,
    required List<ScenePassTiming> passes,
  }) : passes = List.unmodifiable(passes);

  final int width;
  final int height;
  final List<ScenePassTiming> passes;

  Map<String, Object?> toJson() => {
    'width_px': width,
    'height_px': height,
    'passes': passes.map((p) => p.toJson()).toList(),
  };
}

@immutable
class ScenePassTiming {
  const ScenePassTiming(this.name, this.cpuMicros);
  final String name;
  final int cpuMicros;
  Map<String, Object> toJson() => {'name': name, 'cpu_us': cpuMicros};
}

/// Keeps ten seconds of samples, with a hard cap for high-refresh displays.
class SceneRenderMetrics {
  static const window = Duration(seconds: 10);
  static const maxSamples = 1200;
  final ListQueue<SceneRenderSample> _renders = ListQueue();
  final ListQueue<SceneWindowFrameSample> _windowFrames = ListQueue();
  final ListQueue<Duration> _callTimes = ListQueue();
  final ListQueue<String> _events = ListQueue();
  bool sampling = false;
  int requests = 0;
  int coalesced = 0;
  int renderCalls = 0;
  int returned = 0;
  int failures = 0;
  int captures = 0;
  String lastReason = '等待初始化';
  String? lastError;
  String? lastErrorAt;
  Map<String, Object?> specification = const {};

  List<SceneRenderSample> get renderSamples => List.unmodifiable(_renders);
  List<String> get events => List.unmodifiable(_events);
  SceneDurationSummary get sceneCpu => SceneDurationSummary.from(
    _renders.where((s) => !s.capture).map((s) => s.cpuMicros),
  );
  SceneDurationSummary get windowBuild =>
      SceneDurationSummary.from(_windowFrames.map((s) => s.buildMicros));
  SceneDurationSummary get windowRaster =>
      SceneDurationSummary.from(_windowFrames.map((s) => s.rasterMicros));
  double? get overBudgetRatio => _windowFrames.isEmpty
      ? null
      : _windowFrames.where((s) => s.overBudget).length / _windowFrames.length;

  void request(String reason, {required bool merged}) {
    requests++;
    if (merged) coalesced++;
    lastReason = reason;
  }

  void rendered(
    Duration now,
    int? cpuMicros, {
    required String reason,
    Object? error,
    bool capture = false,
  }) {
    renderCalls++;
    lastReason = reason;
    _callTimes.addLast(now);
    while (_callTimes.length > maxSamples) {
      _callTimes.removeFirst();
    }
    if (error == null) {
      returned++;
    } else {
      failures++;
      reportError(now, error);
    }
    if (capture) captures++;
    if (sampling && cpuMicros != null) {
      _renders.addLast(SceneRenderSample(now, cpuMicros, capture: capture));
      trim(now);
    }
  }

  void windowFrame(SceneWindowFrameSample sample) {
    if (!sampling) return;
    _windowFrames.addLast(sample);
    trim(sample.at);
  }

  void trim(Duration now) {
    while (_renders.isNotEmpty &&
        (_renders.length > maxSamples || now - _renders.first.at > window)) {
      _renders.removeFirst();
    }
    while (_windowFrames.isNotEmpty &&
        (_windowFrames.length > maxSamples ||
            now - _windowFrames.first.at > window)) {
      _windowFrames.removeFirst();
    }
  }

  int callsInLastSecond(Duration now) {
    while (_callTimes.isNotEmpty &&
        now - _callTimes.first >= const Duration(seconds: 1)) {
      _callTimes.removeFirst();
    }
    return _callTimes.length;
  }

  void event(Duration now, String message) {
    _events.addLast(
      '${(now.inMilliseconds / 1000).toStringAsFixed(2)}s · $message',
    );
    while (_events.length > 32) {
      _events.removeFirst();
    }
  }

  void reportError(Duration now, Object error) {
    lastError = '$error';
    lastErrorAt = DateTime.now().toIso8601String();
    event(now, '异常：$error');
  }

  void clear() {
    _renders.clear();
    _windowFrames.clear();
    _callTimes.clear();
    _events.clear();
    requests = coalesced = renderCalls = returned = failures = captures = 0;
    lastError = lastErrorAt = null;
  }

  Map<String, Object?> snapshot(Duration now) => {
    'requests': requests,
    'coalesced_requests': coalesced,
    'scene_render_calls': renderCalls,
    'returned_calls': returned,
    'failed_calls': failures,
    'scene_call_rate_hz': callsInLastSecond(now),
    'last_reason': lastReason,
    'scene_cpu': sceneCpu.toJson(),
    'window_build': windowBuild.toJson(),
    'window_raster': windowRaster.toJson(),
    'window_over_budget_ratio': overBudgetRatio,
    'sampling': sampling,
    'window_limit_seconds': window.inSeconds,
    'sample_limit': maxSamples,
    'capture_calls': captures,
    'specification': specification,
    'gpu_duration_us': null,
    'gpu_memory_bytes': null,
    'gpu_draw_calls': null,
    'last_error': lastError,
    'last_error_at': lastErrorAt,
    'events': events,
  };
}
