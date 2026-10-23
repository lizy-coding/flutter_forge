import 'dart:async';

import 'package:flutter/foundation.dart';

import 'diagnostic_models.dart';
import 'network_probe.dart';

enum DiagnosticState { idle, running, completed, cancelled, timedOut, failed }

class DiagnosticSession extends ChangeNotifier {
  DiagnosticSession({
    NetworkProbe? probe,
    this.stageBudget = const Duration(seconds: 12),
    this.sessionBudget = const Duration(seconds: 60),
    this.interval = const Duration(seconds: 1),
  }) : _probe = probe ?? createNetworkProbe();

  final NetworkProbe _probe;
  final Duration stageBudget;
  final Duration sessionBudget;
  final Duration interval;
  DiagnosticState state = DiagnosticState.idle;
  DiagnosticSymptom symptom = DiagnosticSymptom.offline;
  NetworkSnapshot? snapshot;
  List<DiagnosticTarget> targets = const [];
  final List<ProbeSample> _samples = [];
  List<ProbeSample> get samples => List.unmodifiable(_samples);
  DateTime? startedAt;
  DateTime? finishedAt;
  String? error;
  DiagnosticCancellation? _cancellation;
  bool _disposed = false;

  bool get running => state == DiagnosticState.running;
  int get rounds => symptom == DiagnosticSymptom.intermittent ? 5 : 1;
  int get plannedSamples => targets.length * rounds;
  double get progress =>
      plannedSamples == 0 ? 0 : _samples.length / plannedSamples;
  String get stateLabel => switch (state) {
    DiagnosticState.idle => '尚未检测',
    DiagnosticState.running => '正在检测',
    DiagnosticState.completed => '检测完成',
    DiagnosticState.cancelled => '已取消，保留已完成观测',
    DiagnosticState.timedOut => '已达到会话时间上限，观测不完整',
    DiagnosticState.failed => '检测异常，观测不完整',
  };

  Future<void> start(
    List<DiagnosticTarget> selection,
    DiagnosticSymptom selectedSymptom,
  ) async {
    if (_disposed || running) return;
    if (selection.isEmpty || selection.length > 4) {
      throw ArgumentError('需要 1～4 个检测目标');
    }
    final cancellation = DiagnosticCancellation();
    _cancellation = cancellation;
    targets = List.unmodifiable(selection);
    symptom = selectedSymptom;
    _samples.clear();
    snapshot = null;
    error = null;
    startedAt = DateTime.now();
    finishedAt = null;
    state = DiagnosticState.running;
    notifyListeners();
    final deadline = Timer(sessionBudget, () {
      if (_active(cancellation)) {
        state = DiagnosticState.timedOut;
        finishedAt = DateTime.now();
        cancellation.cancel();
        notifyListeners();
      }
    });
    try {
      try {
        final value = await cancellation.wait(
          _probe.snapshot(cancellation),
          stageBudget,
        );
        if (_active(cancellation)) {
          snapshot = value;
          notifyListeners();
        }
      } on DiagnosticCancelled {
        rethrow;
      } catch (_) {
        if (_active(cancellation)) {
          snapshot = const NetworkSnapshot(
            system: '未知',
            interfaces: [],
            note: '基本信息未取得；继续检测目标。',
          );
        }
      }
      for (var round = 1; round <= rounds; round++) {
        cancellation.check();
        await Future.wait(
          targets.map((target) async {
            final value = await cancellation.wait(
              _probe.probe(target, round, cancellation),
              stageBudget,
            );
            if (_active(cancellation)) {
              _samples.add(value);
              notifyListeners();
            }
          }),
        );
        if (round < rounds) {
          await cancellation.wait(
            Future<void>.delayed(interval),
            interval + const Duration(seconds: 1),
          );
        }
      }
      if (_active(cancellation)) state = DiagnosticState.completed;
    } on DiagnosticCancelled {
      // cancel(), deadline and dispose() already own the state transition.
    } catch (_) {
      if (_active(cancellation)) {
        state = DiagnosticState.failed;
        error = '检测未能完成，请重新检测；不能将未完成项视为网络失败。';
      }
    } finally {
      deadline.cancel();
      cancellation.cancel();
      if (!_disposed && identical(_cancellation, cancellation)) {
        finishedAt ??= DateTime.now();
        _cancellation = null;
        notifyListeners();
      }
    }
  }

  bool _active(DiagnosticCancellation cancellation) =>
      !_disposed &&
      identical(_cancellation, cancellation) &&
      !cancellation.isCancelled;

  void cancel() {
    if (!running) return;
    state = DiagnosticState.cancelled;
    finishedAt = DateTime.now();
    _cancellation?.cancel();
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _cancellation?.cancel();
    super.dispose();
  }
}
