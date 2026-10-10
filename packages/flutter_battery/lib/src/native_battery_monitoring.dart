import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';

import '../battery_monitoring.dart'
    show BatterySample, BatteryObservationOptions, BatteryDeliveryMode;
import '../models/battery_info.dart';
import '../models/battery_health.dart';
import 'battery_channel_contract.dart';

/// A closeable event owner. Closing one owner leaves other owners active.
class NativeBatteryObservation {
  NativeBatteryObservation._(this.options, this._release);

  final BatteryObservationOptions options;
  final Future<void> Function(NativeBatteryObservation) _release;
  final _controller = StreamController<Map<String, dynamic>>.broadcast();
  final _lastDelivery = <BatterySample, int>{};
  final _signatures = <BatterySample, String>{};
  final _pendingEvents = <BatterySample, Map<String, dynamic>>{};
  final _deliveryTimers = <BatterySample, Timer>{};

  void _clearPending() {
    for (final timer in _deliveryTimers.values) {
      timer.cancel();
    }
    _deliveryTimers.clear();
    _pendingEvents.clear();
  }

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
    _clearPending();
    try {
      await _release(this);
    } finally {
      unawaited(_controller.close());
    }
  }

  String _signature(Map<String, dynamic> event, BatterySample sample) {
    Object? canonical(Object? value) {
      if (value is Map) {
        final keys = value.keys.map((key) => key.toString()).toList()..sort();
        return {for (final key in keys) key: canonical(value[key])};
      }
      if (value is List) return value.map(canonical).toList();
      return value;
    }

    final keys = switch (sample) {
      BatterySample.level => [
        BatteryPayloadKeys.availability,
        BatteryPayloadKeys.level,
      ],
      BatterySample.health => [
        BatteryPayloadKeys.availability,
        BatteryPayloadKeys.state,
      ],
      BatterySample.info => [
        BatteryPayloadKeys.availability,
        BatteryPayloadKeys.level,
        BatteryPayloadKeys.isCharging,
        BatteryPayloadKeys.isCharged,
        BatteryPayloadKeys.powerSource,
        BatteryPayloadKeys.temperature,
        BatteryPayloadKeys.voltage,
        BatteryPayloadKeys.capacity,
      ],
    };
    final payload = {
      for (final key in keys)
        if (event.containsKey(key)) key: event[key],
    };
    return jsonEncode(canonical(payload));
  }

  void _deliver(Map<String, dynamic> event) {
    if (_closed || !_controller.hasListener) return;
    final sample =
        _sampleFor(event[BatteryPayloadKeys.type]) ??
        switch (event[BatteryPayloadKeys.sample]) {
          'level' => BatterySample.level,
          'info' => BatterySample.info,
          'health' => BatterySample.health,
          _ =>
            event[BatteryPayloadKeys.type] ==
                    BatteryEventTypes.batteryUnavailable
                ? options.samples.first
                : null,
        };
    if (sample == null) {
      _error(
        const FormatException('Unknown battery event type'),
        StackTrace.current,
      );
      return;
    }
    if (!options.samples.contains(sample)) return;
    final initial = !_lastDelivery.containsKey(sample);
    if (options.mode == BatteryDeliveryMode.changes) {
      String signature;
      try {
        signature = _signature(event, sample);
      } catch (error, stack) {
        _error(error, stack);
        return;
      }
      if (_signatures[sample] == signature) return;
      _signatures[sample] = signature;
    } else {
      final now = DateTime.now().millisecondsSinceEpoch;
      final previous = _lastDelivery[sample];
      final interval = options.intervalFor(sample)!;
      if (previous != null && now - previous < interval) {
        _pendingEvents[sample] = Map.unmodifiable(event);
        _deliveryTimers.putIfAbsent(
          sample,
          () => Timer(Duration(milliseconds: interval - (now - previous)), () {
            _deliveryTimers.remove(sample);
            final pending = _pendingEvents.remove(sample);
            if (pending != null && !_closed) _deliver(pending);
          }),
        );
        return;
      }
    }
    _lastDelivery[sample] = DateTime.now().millisecondsSinceEpoch;
    _controller.add(
      Map.unmodifiable({
        ...event,
        BatteryPayloadKeys.delivery: initial
            ? 'initial'
            : options.mode == BatteryDeliveryMode.changes
            ? 'change'
            : 'sample',
      }),
    );
  }

  void _error(Object error, StackTrace stack) {
    _lastDelivery.clear();
    _signatures.clear();
    _clearPending();
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
  final _owners = <NativeBatteryObservation>{};
  final _latest = <String, Map<String, dynamic>>{};
  // Ownership is released through a local alias or the owner teardown; covered by lifecycle tests.
  // ignore: cancel_subscriptions
  StreamSubscription<Map<String, dynamic>>? _subscription;
  Future<void> _pending = Future.value();

  Future<T> _serialize<T>(Future<T> Function() operation) {
    final result = _pending.then((_) => operation());
    _pending = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }

  Stream<Map<String, dynamic>> watch(BatteryObservationOptions options) {
    // The broadcast stream remains reusable; its listener is released on cancellation.
    // ignore: close_sinks
    late StreamController<Map<String, dynamic>> controller;
    Future<NativeBatteryObservation>? opening;
    // The broadcast stream remains reusable; its listener is released on cancellation.
    // ignore: cancel_subscriptions
    StreamSubscription<Map<String, dynamic>>? forwarding;
    var generation = 0;
    controller = StreamController<Map<String, dynamic>>.broadcast(
      onListen: () {
        final ticket = ++generation;
        final request = open(options);
        opening = request;
        unawaited(
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
          ),
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

  Future<NativeBatteryObservation> open(BatteryObservationOptions options) {
    return _serialize(() async {
      final owner = NativeBatteryObservation._(options, _release);
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
            _latest.clear();
            for (final current in _owners.toList()) {
              current._error(error, stack);
            }
          },
          onDone: () {
            _subscription = null;
            _latest.clear();
            for (final current in _owners.toList()) {
              current._error(
                PlatformException(
                  code: 'UNAVAILABLE',
                  message: 'Native event stream ended',
                ),
                StackTrace.current,
              );
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

  Future<void> _release(NativeBatteryObservation owner) => _serialize(() async {
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
          .map((owner) => owner.options.intervalFor(sample))
          .whereType<int>();
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
      BatteryPayloadKeys.enableDebounce: false,
    };
  }
}
