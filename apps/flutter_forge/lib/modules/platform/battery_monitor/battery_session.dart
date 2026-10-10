import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_battery/flutter_battery.dart';

class BatterySession extends ChangeNotifier {
  BatterySession(this.battery);
  final FlutterBattery battery;
  BatteryCapabilities? capabilities;
  BatteryOutcome<BatterySnapshot>? reading;
  BatteryOutcome<BatterySnapshot>? levelReading;
  BatteryOutcome<BatterySnapshot>? healthReading;
  BatteryObservation? _observation;
  // Ownership is released through a local alias or the owner teardown; covered by lifecycle tests.
  // ignore: cancel_subscriptions
  StreamSubscription<BatteryOutcome<BatterySnapshot>>? _subscription;
  String? streamError;
  int eventCount = 0;
  bool loading = false;
  bool _disposed = false;

  BatterySnapshot? get info => reading?.value;
  BatterySnapshot? get health => healthReading?.value;
  int? get level => levelReading?.value?.level ?? info?.level;
  BatterySnapshot? get power => levelReading?.value ?? info;
  String get powerText =>
      switch (power?.chargeState ?? BatteryChargeState.unknown) {
        BatteryChargeState.charging => '接入电源，正在充电',
        BatteryChargeState.full => '接入电源，电池已充满',
        BatteryChargeState.notCharging => '接入电源，当前未充电',
        BatteryChargeState.discharging => '使用电池供电',
        BatteryChargeState.unknown => '供电或充电状态未知',
      };
  String? get error => reading?.reason == null
      ? null
      : '${reading!.reason!.code}：${reading!.reason!.message}';
  String get statusText => _status(reading?.status ?? BatteryStatus.pending);
  String get healthStatus =>
      healthReading?.value?.health?.name ??
      _status(healthReading?.status ?? BatteryStatus.pending);

  BatteryDeliveryMode mode = BatteryDeliveryMode.changes;
  int intervalMs = 1000;
  Set<BatterySample> samples = {BatterySample.info};
  final List<BatteryOutcome<BatterySnapshot>> _history = [];
  List<BatteryOutcome<BatterySnapshot>> get history =>
      List.unmodifiable(_history);
  BatteryOutcome<void>? closeResult;
  bool _configured = false;
  bool get observing => _observation != null;
  BatteryObservationState? get observationState => _observation?.state;
  bool get modeSupported =>
      capabilities != null &&
      (mode == BatteryDeliveryMode.changes
          ? capabilities!.changeObservationSupported
          : capabilities!.observationSupported);
  Set<BatterySample> get selectableSamples =>
      capabilities?.observableSamples ?? {};
  String get observationText => switch (observationState) {
    BatteryObservationState.active => '监听中',
    BatteryObservationState.failed => '监听异常，可重试',
    BatteryObservationState.closing => '正在关闭',
    BatteryObservationState.closed || null => '已停止',
  };

  Future<void> initialize() => _run(() async {
    if (!await _queryCapabilities()) return;
    await _read();
    if (!_disposed) await _open();
  });

  Future<void> refresh() => _run(() async {
    if (!await _queryCapabilities()) return;
    await _read();
    if (!_disposed && observationState == BatteryObservationState.failed) {
      if (await _release()) await _open();
    }
  });

  Future<void> start() => _run(() async {
    if (!await _queryCapabilities()) return;
    if (observing && !await _release()) return;
    if (!_disposed) await _open();
  });

  Future<void> stop() => _run(_release);

  Future<void> configure({
    BatteryDeliveryMode? deliveryMode,
    int? interval,
    Set<BatterySample>? selection,
  }) => _run(() async {
    if (interval != null && (interval < 100 || interval > 3600000)) {
      throw ArgumentError.value(interval, 'interval');
    }
    if (selection != null && selection.isEmpty) {
      throw ArgumentError.value(selection, 'selection');
    }
    final resume = observing;
    if (resume && !await _release()) return;
    if (_disposed) return;
    mode = deliveryMode ?? mode;
    intervalMs = interval ?? intervalMs;
    samples = Set.of(selection ?? samples);
    if (resume && !_disposed) await _open();
  });

  void clearHistory() {
    if (_disposed) return;
    _history.clear();
    notifyListeners();
  }

  Future<void> _run(Future<dynamic> Function() action) async {
    if (_disposed || loading) return;
    loading = true;
    notifyListeners();
    try {
      await action();
    } finally {
      if (!_disposed) {
        loading = false;
        notifyListeners();
      }
    }
  }

  Future<bool> _queryCapabilities() async {
    final queried = await battery.capabilities();
    if (_disposed) return false;
    capabilities = queried.value;
    if (!queried.isAvailable) {
      reading = BatteryOutcome.state(
        queried.status,
        queried.reason!.code,
        queried.reason!.message,
      );
      levelReading = null;
      return false;
    }
    if (!_configured) {
      _configured = true;
      mode = capabilities!.changeObservationSupported
          ? BatteryDeliveryMode.changes
          : BatteryDeliveryMode.sampling;
      samples = capabilities!.observableSamples.contains(BatterySample.info)
          ? {BatterySample.info}
          : Set.of(capabilities!.observableSamples.take(1));
    }
    return true;
  }

  Future<void> _read() async {
    final sample = capabilities!.supports(BatterySample.info)
        ? BatterySample.info
        : BatterySample.level;
    final result = await battery.read(sample: sample);
    if (_disposed) return;
    reading = result;
    levelReading = null;
    if (capabilities!.supports(BatterySample.health)) {
      final result = await battery.read(sample: BatterySample.health);
      if (_disposed) return;
      healthReading = result;
    } else {
      healthReading = BatteryOutcome.state(
        BatteryStatus.unsupported,
        'health_unsupported',
        '健康信息不支持',
        sample: BatterySample.health,
      );
    }
  }

  Future<void> _open() async {
    if (!modeSupported ||
        samples.isEmpty ||
        !samples.every(selectableSamples.contains)) {
      streamError = '当前平台不支持所选监听模式或样本';
      return;
    }
    streamError = null;
    final opened = mode == BatteryDeliveryMode.changes
        ? await battery.watchChanges(
            options: BatteryChangeOptions(samples: samples),
          )
        : await battery.sample(
            options: BatterySamplingOptions(
              samples: samples,
              levelIntervalMs: intervalMs,
              infoIntervalMs: intervalMs,
              healthIntervalMs: intervalMs,
            ),
          );
    if (_disposed) {
      await opened.value?.close();
      return;
    }
    if (!opened.isAvailable) {
      streamError = '${_status(opened.status)}：${opened.reason!.code}';
      return;
    }
    _observation = opened.value;
    _subscription = _observation!.events.listen((result) {
      if (_disposed || result.status == BatteryStatus.pending) return;
      eventCount++;
      _history.insert(0, result);
      if (_history.length > 20) _history.removeLast();
      if (result.sample == null) {
        streamError =
            '${_status(result.status)}：${result.reason?.code ?? "unknown"}';
      } else {
        streamError = null;
        if (result.sample == BatterySample.health) {
          healthReading = result;
        } else if (result.sample == BatterySample.level &&
            result.isAvailable &&
            reading?.isAvailable == true &&
            reading?.sample == BatterySample.info) {
          levelReading = result;
        } else {
          reading = result;
          levelReading = null;
        }
      }
      notifyListeners();
    });
  }

  Future<bool> _release() async {
    final owner = _observation;
    final subscription = _subscription;
    _observation = null;
    _subscription = null;
    final closing = owner?.close();
    await subscription?.cancel();
    final result = await closing;
    if (!_disposed && result != null) {
      closeResult = result;
      if (result.status != BatteryStatus.closed) {
        streamError = '关闭异常：${_status(result.status)}，${result.reason?.code}';
      } else {
        streamError = null;
      }
    }
    return result == null || result.status == BatteryStatus.closed;
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_release());
    super.dispose();
  }
}

String _status(BatteryStatus status) => switch (status) {
  BatteryStatus.pending => '等待采样',
  BatteryStatus.available => '读取成功',
  BatteryStatus.noBattery => '未检测到电池',
  BatteryStatus.unknown => '测量未知',
  BatteryStatus.unsupported => '功能不支持',
  BatteryStatus.permissionDenied => '权限不足',
  BatteryStatus.unavailable => '原生不可用',
  BatteryStatus.invalidData => '数据异常',
  BatteryStatus.timedOut => '操作超时',
  BatteryStatus.failed => '操作失败',
  BatteryStatus.closed => '观察已关闭',
};
