import 'dart:async';

import 'battery_result.dart';
import 'src/native_battery_monitoring.dart';
import 'src/battery_channel_contract.dart';

/// Independently selectable native battery samples.
enum BatterySample { level, info, health }

enum BatteryDeliveryMode { sampling, changes }

/// One mutually exclusive delivery policy per subscription.
sealed class BatteryObservationOptions {
  BatteryObservationOptions._(Set<BatterySample> samples)
    : samples = Set.unmodifiable(samples) {
    if (samples.isEmpty) throw ArgumentError.value(samples, 'samples');
  }
  factory BatteryObservationOptions({
    Set<BatterySample> samples,
    int levelIntervalMs,
    int infoIntervalMs,
    int healthIntervalMs,
  }) = BatterySamplingOptions;
  final Set<BatterySample> samples;
  BatteryDeliveryMode get mode;
  int? intervalFor(BatterySample sample);
}

final class BatterySamplingOptions extends BatteryObservationOptions {
  BatterySamplingOptions({
    Set<BatterySample> samples = const {BatterySample.level},
    this.levelIntervalMs = 1000,
    this.infoIntervalMs = 5000,
    this.healthIntervalMs = 10000,
  }) : super._(samples) {
    for (final value in [levelIntervalMs, infoIntervalMs, healthIntervalMs]) {
      if (value < 100 || value > 3600000) {
        throw ArgumentError.value(value, 'interval');
      }
    }
  }
  final int levelIntervalMs;
  final int infoIntervalMs;
  final int healthIntervalMs;
  @override
  BatteryDeliveryMode get mode => BatteryDeliveryMode.sampling;
  @override
  int intervalFor(BatterySample sample) => switch (sample) {
    BatterySample.level => levelIntervalMs,
    BatterySample.info => infoIntervalMs,
    BatterySample.health => healthIntervalMs,
  };
}

final class BatteryChangeOptions extends BatteryObservationOptions {
  BatteryChangeOptions({
    Set<BatterySample> samples = const {BatterySample.level},
  }) : super._(samples);
  @override
  BatteryDeliveryMode get mode => BatteryDeliveryMode.changes;
  @override
  int? intervalFor(BatterySample sample) => null;
}

enum BatteryObservationState { active, failed, closing, closed }

/// Owns one typed observation. Close is idempotent and returns a bounded result.
class BatteryObservation {
  BatteryObservation.fromNative(this._native, this.timeout) {
    _controller.onListen = () {
      if (!_controller.isClosed) _controller.add(_current);
    };
    _firstSampleTimer = Timer(timeout, () {
      if (_current.status == BatteryStatus.pending &&
          _state == BatteryObservationState.active) {
        _state = BatteryObservationState.failed;
        _publish(
          BatteryOutcome.state(
            BatteryStatus.timedOut,
            'first_sample_timeout',
            'No native sample arrived before the deadline',
          ),
        );
      }
    });
    _subscription = _native.events.listen(
      (event) {
        if (_state == BatteryObservationState.closing ||
            _state == BatteryObservationState.closed) {
          return;
        }
        final sample = switch (event[BatteryPayloadKeys.sample]) {
          'info' => BatterySample.info,
          'health' => BatterySample.health,
          'level' => BatterySample.level,
          _ => switch (event[BatteryPayloadKeys.type]) {
            BatteryEventTypes.batteryInfo => BatterySample.info,
            BatteryEventTypes.batteryHealth => BatterySample.health,
            _ => BatterySample.level,
          },
        };
        _state = BatteryObservationState.active;
        _publish(
          decodeBatterySample(event, sample).forSample(sample).withDelivery(
            switch (event[BatteryPayloadKeys.delivery]) {
              'initial' => BatteryEventDelivery.initial,
              'sample' => BatteryEventDelivery.sample,
              'change' => BatteryEventDelivery.change,
              _ => null,
            },
          ),
        );
      },
      onError: (Object error) {
        if (_state == BatteryObservationState.closing ||
            _state == BatteryObservationState.closed) {
          return;
        }
        final result = batteryFailure<BatterySnapshot>(error);
        if (result.status == BatteryStatus.unavailable) {
          _state = BatteryObservationState.failed;
        }
        _publish(result);
      },
      onDone: () {
        if (_state == BatteryObservationState.active) {
          _state = BatteryObservationState.failed;
          _publish(
            BatteryOutcome.state(
              BatteryStatus.unavailable,
              'event_stream_ended',
              'Native event stream ended',
            ),
          );
        }
      },
    );
  }

  final NativeBatteryObservation _native;
  final Duration timeout;
  Timer? _firstSampleTimer;
  late final StreamSubscription<Map<String, dynamic>> _subscription;
  final _controller =
      StreamController<BatteryOutcome<BatterySnapshot>>.broadcast();
  BatteryObservationState _state = BatteryObservationState.active;
  BatteryOutcome<BatterySnapshot> _current = BatteryOutcome.state(
    BatteryStatus.pending,
    'awaiting_sample',
    'Waiting for first sample',
  );
  Future<BatteryOutcome<void>>? _closing;

  BatteryObservationOptions get options => _native.options;
  BatteryObservationState get state => _state;
  BatteryOutcome<BatterySnapshot> get current => _current;
  Stream<BatteryOutcome<BatterySnapshot>> get events =>
      _controller.stream.where(
        (event) =>
            (_state != BatteryObservationState.closing &&
                _state != BatteryObservationState.closed) ||
            event.status == BatteryStatus.closed,
      );

  void _publish(BatteryOutcome<BatterySnapshot> result) {
    if (result.status != BatteryStatus.pending) _firstSampleTimer?.cancel();
    _current = result;
    if (!_controller.isClosed) _controller.add(result);
  }

  Future<BatteryOutcome<void>> close() => _closing ??= _close();

  Future<BatteryOutcome<void>> _close() async {
    _state = BatteryObservationState.closing;
    _firstSampleTimer?.cancel();
    _current = BatteryOutcome.state(
      BatteryStatus.closed,
      'observation_closing',
      'Observation is closing',
    );
    BatteryOutcome<void> result;
    try {
      final release = _native.close();
      await _subscription.cancel();
      await release.timeout(timeout);
      result = BatteryOutcome.state(
        BatteryStatus.closed,
        'observation_closed',
        'Observation closed',
      );
    } catch (error) {
      result = batteryFailure<void>(error);
    } finally {
      _state = BatteryObservationState.closed;
      _publish(
        BatteryOutcome.state(
          BatteryStatus.closed,
          'observation_closed',
          'Observation closed',
        ),
      );
      unawaited(_controller.close());
    }
    return result;
  }
}
