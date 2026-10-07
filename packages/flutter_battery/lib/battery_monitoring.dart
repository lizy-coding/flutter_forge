import 'dart:async';

import 'src/battery_channel_contract.dart';
import 'models/battery_info.dart';
import 'models/battery_health.dart';

/// Independently selectable native battery samples.
enum BatterySample { level, info, health }

/// Sampling requirements owned by one observation.
class BatteryObservationOptions {
  BatteryObservationOptions({
    Set<BatterySample> samples = const {BatterySample.level},
    this.levelIntervalMs = 1000,
    this.infoIntervalMs = 5000,
    this.healthIntervalMs = 10000,
    this.debounceLevel = true,
  }) : samples = Set.unmodifiable(samples) {
    if (samples.isEmpty) throw ArgumentError.value(samples, 'samples');
    for (final interval in [
      levelIntervalMs,
      infoIntervalMs,
      healthIntervalMs,
    ]) {
      if (interval < 100 || interval > 3600000) {
        throw ArgumentError.value(interval, 'interval', 'Use 100..3600000 ms');
      }
    }
  }

  final Set<BatterySample> samples;
  final int levelIntervalMs;
  final int infoIntervalMs;
  final int healthIntervalMs;
  final bool debounceLevel;

  int intervalFor(BatterySample sample) => switch (sample) {
    BatterySample.level => levelIntervalMs,
    BatterySample.info => infoIntervalMs,
    BatterySample.health => healthIntervalMs,
  };
}

/// A closeable event owner. Closing one owner leaves other owners active.
class BatteryObservation {
  BatteryObservation._(this.options, this._release);

  final BatteryObservationOptions options;
  final Future<void> Function(BatteryObservation) _release;
  final _controller = StreamController<Map<String, dynamic>>.broadcast();
  final _lastDelivery = <BatterySample, int>{};
  int? _lastLevel;
  bool _closed = false;
  Future<void>? _closing;

  Stream<Map<String, dynamic>> get events => _controller.stream;
  bool get isClosed => _closed;

  Stream<int?> get levels => events
      .where(
        (event) =>
            event[BatteryPayloadKeys.type] == BatteryEventTypes.batteryLevel ||
            event[BatteryPayloadKeys.type] ==
                BatteryEventTypes.batteryUnavailable,
      )
      .map((event) {
        if (event[BatteryPayloadKeys.type] ==
            BatteryEventTypes.batteryUnavailable) {
          return null;
        }
        final value = event[BatteryPayloadKeys.level] as int?;
        return value != null && value >= 0 && value <= 100 ? value : null;
      });

  Stream<BatteryInfo> get info => events
      .where(
        (event) =>
            event[BatteryPayloadKeys.type] == BatteryEventTypes.batteryInfo,
      )
      .map(BatteryInfo.fromMap);

  Stream<BatteryHealth> get health => events
      .where(
        (event) =>
            event[BatteryPayloadKeys.type] == BatteryEventTypes.batteryHealth,
      )
      .map(BatteryHealth.fromMap);

  Future<void> close() {
    return _closing ??= _close();
  }

  Future<void> _close() async {
    _closed = true;
    try {
      await _release(this);
    } finally {
      unawaited(_controller.close());
    }
  }

  void _deliver(Map<String, dynamic> event) {
    if (_closed || !_controller.hasListener) return;
    final sample = _sampleFor(event[BatteryPayloadKeys.type]);
    if (sample == null) {
      if (event[BatteryPayloadKeys.type] ==
          BatteryEventTypes.batteryUnavailable) {
        _lastLevel = null;
        _lastDelivery.clear();
        _controller.add(Map.unmodifiable(event));
      }
      return;
    }
    if (!options.samples.contains(sample)) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    final previous = _lastDelivery[sample];
    if (previous != null && now - previous < options.intervalFor(sample)) {
      return;
    }
    if (sample == BatterySample.level) {
      final level = event[BatteryPayloadKeys.level] as int?;
      if (options.debounceLevel && _lastLevel == level && previous != null) {
        return;
      }
      _lastLevel = level;
    }
    _lastDelivery[sample] = now;
    _controller.add(Map.unmodifiable(event));
  }

  void _error(Object error, StackTrace stack) {
    if (!_closed) _controller.addError(error, stack);
  }
}

BatterySample? _sampleFor(Object? type) => switch (type) {
  BatteryEventTypes.batteryLevel => BatterySample.level,
  BatteryEventTypes.batteryInfo => BatterySample.info,
  BatteryEventTypes.batteryHealth => BatterySample.health,
  _ => null,
};

/// Coordinates observations for one platform transport.
///
/// Platform adapters provide one event source and an atomic native configure
/// operation. All ownership changes are serialized.
class BatteryObservationCoordinator {
  BatteryObservationCoordinator({
    required this.source,
    required this.configure,
  });

  final Stream<Map<String, dynamic>> source;
  final Future<void> Function(Map<String, dynamic>) configure;
  final _owners = <BatteryObservation>{};
  final _latest = <String, Map<String, dynamic>>{};
  StreamSubscription<Map<String, dynamic>>? _subscription;
  Future<void> _pending = Future.value();

  Future<T> _serialize<T>(Future<T> Function() operation) {
    final result = _pending.then((_) => operation());
    _pending = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }

  Stream<Map<String, dynamic>> watch(BatteryObservationOptions options) {
    late StreamController<Map<String, dynamic>> controller;
    Future<BatteryObservation>? opening;
    StreamSubscription<Map<String, dynamic>>? forwarding;
    var generation = 0;
    controller = StreamController<Map<String, dynamic>>.broadcast(
      onListen: () {
        final ticket = ++generation;
        final request = open(options);
        opening = request;
        request.then(
          (owner) {
            if (ticket != generation) return;
            forwarding = owner.events.listen(
              controller.add,
              onError: controller.addError,
            );
          },
          onError: (Object error, StackTrace stack) {
            if (ticket == generation) controller.addError(error, stack);
          },
        );
      },
      onCancel: () async {
        generation++;
        final request = opening;
        opening = null;
        final subscription = forwarding;
        forwarding = null;
        await subscription?.cancel();
        try {
          final owner = await request;
          await owner?.close();
        } catch (_) {
          // Opening errors are delivered through the stream.
        }
      },
    );
    return controller.stream;
  }

  Future<BatteryObservation> open(BatteryObservationOptions options) {
    return _serialize(() async {
      final owner = BatteryObservation._(options, _release);
      _owners.add(owner);
      try {
        await configure(_configuration());
        _subscription ??= source.listen(
          (event) {
            final type = event[BatteryPayloadKeys.type];
            if (type == BatteryEventTypes.batteryUnavailable) {
              _latest.clear();
            } else {
              _latest.remove(BatteryEventTypes.batteryUnavailable);
            }
            if (type is String) _latest[type] = Map.unmodifiable(event);
            for (final current in _owners.toList()) {
              current._deliver(event);
            }
          },
          onError: (Object error, StackTrace stack) {
            for (final current in _owners.toList()) {
              current._error(error, stack);
            }
          },
        );
        owner._controller.onListen = () {
          for (final event in _latest.values.toList()) {
            owner._deliver(event);
          }
        };
        return owner;
      } catch (_) {
        _owners.remove(owner);
        owner._closed = true;
        await owner._controller.close();
        rethrow;
      }
    });
  }

  Future<void> _release(BatteryObservation owner) => _serialize(() async {
    _owners.remove(owner);
    try {
      await configure(_configuration());
    } finally {
      if (_owners.isEmpty) {
        final subscription = _subscription;
        _subscription = null;
        _latest.clear();
        await subscription?.cancel();
      }
    }
  });

  Map<String, dynamic> _configuration() {
    int interval(BatterySample sample, int fallback) {
      final values = _owners
          .where((owner) => owner.options.samples.contains(sample))
          .map((owner) => owner.options.intervalFor(sample));
      return values.isEmpty ? fallback : values.reduce((a, b) => a < b ? a : b);
    }

    bool enabled(BatterySample sample) =>
        _owners.any((owner) => owner.options.samples.contains(sample));
    return {
      BatteryPayloadKeys.monitorBatteryLevel: enabled(BatterySample.level),
      BatteryPayloadKeys.monitorBatteryInfo: enabled(BatterySample.info),
      BatteryPayloadKeys.monitorBatteryHealth: enabled(BatterySample.health),
      BatteryPayloadKeys.intervalMs: interval(BatterySample.level, 1000),
      BatteryPayloadKeys.batteryInfoIntervalMs: interval(
        BatterySample.info,
        5000,
      ),
      BatteryPayloadKeys.batteryHealthIntervalMs: interval(
        BatterySample.health,
        10000,
      ),
      BatteryPayloadKeys.enableDebounce: !_owners.any(
        (owner) =>
            owner.options.samples.contains(BatterySample.level) &&
            !owner.options.debounceLevel,
      ),
    };
  }
}
