import 'dart:async';

import 'package:flutter/services.dart';

import 'battery_monitoring.dart' show BatterySample;
import 'src/battery_channel_contract.dart';
import 'src/platform_capabilities.dart';

/// Distinguishes successful measurements from absent data and runtime failures.
enum BatteryStatus {
  pending,
  available,
  noBattery,
  unknown,
  unsupported,
  permissionDenied,
  unavailable,
  invalidData,
  timedOut,
  failed,
  closed,
}

/// A stable, machine-readable reason with a human-readable explanation.
class BatteryReason {
  const BatteryReason(this.code, this.message);
  final String code;
  final String message;
}

/// A runtime outcome. Only [BatteryStatus.available] contains a value.
enum BatteryEventDelivery { initial, sample, change }

class BatteryOutcome<T> {
  const BatteryOutcome._(
    this.status,
    this.value,
    this.reason, [
    this.sample,
    this.delivery,
  ]);
  factory BatteryOutcome.available(T value) => BatteryOutcome._(
    BatteryStatus.available,
    value,
    null,
    value is BatterySnapshot ? value.sample : null,
  );
  factory BatteryOutcome.state(
    BatteryStatus status,
    String code,
    String message, {
    BatterySample? sample,
  }) {
    if (status == BatteryStatus.available) throw ArgumentError.value(status);
    return BatteryOutcome._(
      status,
      null,
      BatteryReason(
        code.trim().isEmpty ? 'unspecified_reason' : code,
        message.trim().isEmpty ? 'No additional detail' : message,
      ),
      sample,
    );
  }
  final BatteryStatus status;
  final T? value;
  final BatteryReason? reason;
  final BatterySample? sample;
  final BatteryEventDelivery? delivery;
  BatteryOutcome<T> forSample(BatterySample selected) =>
      BatteryOutcome._(status, value, reason, selected, delivery);
  BatteryOutcome<T> withDelivery(BatteryEventDelivery? kind) =>
      BatteryOutcome._(status, value, reason, sample, kind);
  bool get isAvailable => status == BatteryStatus.available;
}

/// Implementation support, separate from permissions and current device state.
class BatteryCapabilities {
  BatteryCapabilities({
    required Set<BatterySample> samples,
    required Set<BatterySample> observableSamples,
    required this.observationSupported,
    this.changeObservationSupported = false,
  }) : samples = Set.unmodifiable(samples),
       observableSamples = Set.unmodifiable(observableSamples);
  final Set<BatterySample> samples;
  final Set<BatterySample> observableSamples;
  final bool observationSupported;
  final bool changeObservationSupported;
  bool supports(BatterySample sample) => samples.contains(sample);
  bool supportsChanges(BatterySample sample) =>
      changeObservationSupported && observableSamples.contains(sample);
  bool supportsObservation(BatterySample sample) =>
      observationSupported && observableSamples.contains(sample);
}

enum BatteryHealthCondition {
  degraded,
  good,
  overheat,
  dead,
  overVoltage,
  failure,
  cold,
}

enum BatteryPowerSource { external, battery, unknown }

enum BatteryChargeState { charging, full, notCharging, discharging, unknown }

/// Units must be confirmed by the adapter; unspecified values are diagnostic only.
enum BatteryCapacityUnit { milliampHours, milliwattHours, percent, unspecified }

class BatteryCapacityDetails {
  BatteryCapacityDetails({
    this.remaining,
    this.fullCharge,
    this.design,
    this.cycleCount,
    required this.unit,
    required this.source,
  }) {
    if (remaining != null && remaining! < 0) {
      throw ArgumentError.value(remaining, 'remaining');
    }
    if (fullCharge != null && fullCharge! <= 0) {
      throw ArgumentError.value(fullCharge, 'fullCharge');
    }
    if (design != null && design! <= 0) {
      throw ArgumentError.value(design, 'design');
    }
    if (cycleCount != null && cycleCount! < 0) {
      throw ArgumentError.value(cycleCount, 'cycleCount');
    }
    if (source.isEmpty) throw ArgumentError.value(source, 'source');
  }
  final int? remaining;
  final int? fullCharge;
  final int? design;
  final int? cycleCount;
  final BatteryCapacityUnit unit;
  final String source;
  double? get fullChargeRelativeToDesignPercent =>
      unit != BatteryCapacityUnit.unspecified &&
          unit != BatteryCapacityUnit.percent &&
          fullCharge != null &&
          design != null &&
          design! > 0
      ? fullCharge! / design! * 100
      : null;
}

/// A valid measurement. Optional fields remain null when the platform lacks them.
class BatterySnapshot {
  BatterySnapshot({
    required this.sample,
    required this.level,
    this.capacity,
    this.isCharging,
    this.isCharged,
    this.powerSource = BatteryPowerSource.unknown,
    this.temperatureCelsius,
    this.voltageVolts,
    this.health,
    this.timestamp,
  }) {
    if (level < 0 || level > 100) throw ArgumentError.value(level, 'level');
    if (temperatureCelsius != null && !temperatureCelsius!.isFinite) {
      throw ArgumentError.value(temperatureCelsius);
    }
    if (voltageVolts != null &&
        (!voltageVolts!.isFinite || voltageVolts! < 0)) {
      throw ArgumentError.value(voltageVolts);
    }
  }
  final BatterySample sample;
  final int level;
  final BatteryCapacityDetails? capacity;
  final bool? isCharging;
  final bool? isCharged;
  final BatteryPowerSource powerSource;

  BatteryChargeState get chargeState {
    if (isCharging == true) return BatteryChargeState.charging;
    if (powerSource == BatteryPowerSource.external) {
      if (isCharged == true) return BatteryChargeState.full;
      if (isCharging == false) return BatteryChargeState.notCharging;
    }
    if (powerSource == BatteryPowerSource.battery && isCharging == false) {
      return BatteryChargeState.discharging;
    }
    return BatteryChargeState.unknown;
  }

  final double? temperatureCelsius;
  final double? voltageVolts;
  final BatteryHealthCondition? health;
  final DateTime? timestamp;
}

/// Central decoding for method responses and event payloads.
BatteryOutcome<BatterySnapshot> decodeBatterySample(
  Map<String, dynamic> map,
  BatterySample sample,
) {
  try {
    final availability = map[BatteryPayloadKeys.availability];
    if (availability == 'noBattery') {
      return BatteryOutcome.state(
        BatteryStatus.noBattery,
        'no_battery',
        'No battery is present',
        sample: sample,
      );
    }
    if (availability == 'unknown') {
      return BatteryOutcome.state(
        BatteryStatus.unknown,
        'measurement_unknown',
        'The measurement is unavailable',
        sample: sample,
      );
    }
    if (availability != 'available') {
      throw const FormatException('Missing or invalid availability');
    }
    final level = map[BatteryPayloadKeys.level];
    if (level is! int || level < 0 || level > 100) {
      throw const FormatException('Invalid battery percentage');
    }
    final charging = map[BatteryPayloadKeys.isCharging];
    if (charging != null && charging is! bool) {
      throw const FormatException('Invalid charging state');
    }
    final charged = map[BatteryPayloadKeys.isCharged];
    if (charged != null && charged is! bool) {
      throw const FormatException('Invalid full-charge state');
    }
    final rawSource = map[BatteryPayloadKeys.powerSource];
    final powerSource = switch (rawSource) {
      'external' => BatteryPowerSource.external,
      'battery' => BatteryPowerSource.battery,
      null || 'unknown' => BatteryPowerSource.unknown,
      _ => throw const FormatException('Invalid power source'),
    };
    double? number(String key) {
      final raw = map[key];
      if (raw == null) return null;
      if (raw is! num || !raw.isFinite) throw FormatException('Invalid $key');
      return raw.toDouble();
    }

    final temperature = number(BatteryPayloadKeys.temperature);
    final voltage = number(BatteryPayloadKeys.voltage);
    if (voltage != null && voltage < 0) {
      throw const FormatException('Invalid voltage');
    }
    final stamp = map[BatteryPayloadKeys.timestamp];
    if (stamp != null && (stamp is! int || stamp < 0)) {
      throw const FormatException('Invalid timestamp');
    }
    final health = switch (map[BatteryPayloadKeys.state]) {
      'GOOD' => BatteryHealthCondition.good,
      'DEGRADED' => BatteryHealthCondition.degraded,
      'OVERHEAT' => BatteryHealthCondition.overheat,
      'DEAD' => BatteryHealthCondition.dead,
      'OVER_VOLTAGE' => BatteryHealthCondition.overVoltage,
      'FAILURE' => BatteryHealthCondition.failure,
      'COLD' => BatteryHealthCondition.cold,
      _ => null,
    };
    if (sample == BatterySample.health &&
        health == null &&
        map[BatteryPayloadKeys.state] != null &&
        map[BatteryPayloadKeys.state] != 'UNKNOWN') {
      throw const FormatException('Invalid health condition');
    }
    if (sample == BatterySample.health && health == null) {
      return BatteryOutcome.state(
        BatteryStatus.unknown,
        'health_unknown',
        'Battery health cannot be determined',
        sample: sample,
      );
    }
    BatteryCapacityDetails? capacity;
    final rawCapacity = map[BatteryPayloadKeys.capacity];
    if (rawCapacity != null) {
      if (rawCapacity is! Map) {
        throw const FormatException('Invalid capacity details');
      }
      int? value(String key, {bool positive = false}) {
        final raw = rawCapacity[key];
        if (raw == null) return null;
        if (raw is! int || raw < 0 || (positive && raw == 0)) {
          throw FormatException('Invalid capacity $key');
        }
        return raw;
      }

      final unit = switch (rawCapacity['unit']) {
        'milliampHours' => BatteryCapacityUnit.milliampHours,
        'milliwattHours' => BatteryCapacityUnit.milliwattHours,
        'percent' => BatteryCapacityUnit.percent,
        'unspecified' => BatteryCapacityUnit.unspecified,
        _ => throw const FormatException('Invalid capacity unit'),
      };
      final source = rawCapacity['source'];
      if (source is! String || source.isEmpty) {
        throw const FormatException('Missing capacity source');
      }
      capacity = BatteryCapacityDetails(
        remaining: value('remaining'),
        fullCharge: value('fullCharge', positive: true),
        design: value('design', positive: true),
        cycleCount: value('cycleCount'),
        unit: unit,
        source: source,
      );
    }
    return BatteryOutcome.available(
      BatterySnapshot(
        sample: sample,
        level: level,
        capacity: capacity,
        isCharging: charging as bool?,
        isCharged: charged as bool?,
        powerSource: powerSource,
        temperatureCelsius: temperature,
        voltageVolts: voltage,
        health: health,
        timestamp: stamp == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(stamp as int),
      ),
    );
  } catch (error) {
    return BatteryOutcome.state(
      BatteryStatus.invalidData,
      'invalid_payload',
      '$error',
      sample: sample,
    );
  }
}

BatteryOutcome<T> batteryFailure<T>(Object error) {
  if (error is UnsupportedBatteryFeatureException ||
      error is UnimplementedError) {
    return BatteryOutcome.state(
      BatteryStatus.unsupported,
      'interface_unsupported',
      '$error',
    );
  }
  if (error is TimeoutException) {
    return BatteryOutcome.state(
      BatteryStatus.timedOut,
      'operation_timeout',
      'Operation timed out',
    );
  }
  if (error is MissingPluginException) {
    return BatteryOutcome.state(
      BatteryStatus.unavailable,
      'native_adapter_unavailable',
      'Native battery adapter is unavailable',
    );
  }
  if (error is FormatException || error is TypeError) {
    return BatteryOutcome.state(
      BatteryStatus.invalidData,
      'invalid_payload',
      '$error',
    );
  }
  if (error is PlatformException) {
    final status = switch (error.code) {
      'NOT_SUPPORTED' || 'UNIMPLEMENTED' => BatteryStatus.unsupported,
      'PERMISSION_DENIED' ||
      'PERMISSION_REQUIRED' => BatteryStatus.permissionDenied,
      'UNAVAILABLE' => BatteryStatus.unavailable,
      'INVALID_ARGS' => BatteryStatus.invalidData,
      _ => BatteryStatus.failed,
    };
    return BatteryOutcome.state(
      status,
      error.code,
      error.message ?? 'Native operation failed',
    );
  }
  return BatteryOutcome.state(
    BatteryStatus.failed,
    'operation_failed',
    '$error',
  );
}
