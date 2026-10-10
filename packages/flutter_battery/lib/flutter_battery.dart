import 'dart:async';

import 'package:flutter/foundation.dart';

import 'battery_monitoring.dart';
import 'battery_result.dart';
import 'flutter_battery_platform_interface.dart';
import 'src/native_battery_monitoring.dart';
import 'src/platform_capabilities.dart';

export 'battery_monitoring.dart'
    show
        BatterySample,
        BatteryObservationOptions,
        BatterySamplingOptions,
        BatteryChangeOptions,
        BatteryDeliveryMode,
        BatteryObservation,
        BatteryObservationState;
export 'battery_result.dart'
    show
        BatteryStatus,
        BatteryEventDelivery,
        BatteryReason,
        BatteryOutcome,
        BatteryCapabilities,
        BatterySnapshot,
        BatteryCapacityDetails,
        BatteryCapacityUnit,
        BatteryHealthCondition,
        BatteryPowerSource,
        BatteryChargeState;

/// Reads battery samples and creates independently owned observations.
class FlutterBattery {
  FlutterBattery({
    FlutterBatteryPlatform? platform,
    this.timeout = const Duration(seconds: 5),
  }) : _platform = platform ?? FlutterBatteryPlatform.instance,
       _supportedHost =
           platform != null ||
           (!kIsWeb &&
               (defaultTargetPlatform == TargetPlatform.android ||
                   defaultTargetPlatform == TargetPlatform.macOS)) {
    if (timeout <= Duration.zero || timeout > const Duration(seconds: 60)) {
      throw ArgumentError.value(timeout, 'timeout');
    }
  }
  final FlutterBatteryPlatform _platform;
  final bool _supportedHost;
  final Duration timeout;

  Future<BatteryOutcome<BatteryCapabilities>> capabilities() async {
    if (!_supportedHost) {
      return BatteryOutcome.state(
        BatteryStatus.unsupported,
        'platform_unsupported',
        'This host has no supported battery adapter',
      );
    }
    try {
      final caps = await _platform.queryCapabilities().timeout(timeout);
      final samples = <BatterySample>{
        if (caps.isSupported(BatteryFeature.batteryLevel)) BatterySample.level,
        if (caps.isSupported(BatteryFeature.batteryInfo)) BatterySample.info,
        if (caps.isSupported(BatteryFeature.batteryHealth))
          BatterySample.health,
      };
      return BatteryOutcome.available(
        BatteryCapabilities(
          observableSamples: {
            if (caps.isSupported(BatteryFeature.batteryLevelStream))
              BatterySample.level,
            if (caps.isSupported(BatteryFeature.batteryInfoStream))
              BatterySample.info,
            if (caps.isSupported(BatteryFeature.batteryHealthStream))
              BatterySample.health,
          },
          samples: samples,
          changeObservationSupported: caps.isSupported(
            BatteryFeature.changeNotifications,
          ),
          observationSupported: caps.isSupported(
            BatteryFeature.scopedObservations,
          ),
        ),
      );
    } catch (error) {
      return batteryFailure(error);
    }
  }

  Future<BatteryOutcome<BatterySnapshot>> read({
    BatterySample sample = BatterySample.info,
  }) async {
    final clock = Stopwatch()..start();
    final caps = await capabilities();
    if (!caps.isAvailable) {
      return BatteryOutcome.state(
        caps.status,
        caps.reason!.code,
        caps.reason!.message,
        sample: sample,
      );
    }
    if (!caps.value!.supports(sample)) {
      return BatteryOutcome.state(
        BatteryStatus.unsupported,
        'sample_unsupported',
        '${sample.name} is not implemented',
        sample: sample,
      );
    }
    try {
      final remaining = timeout - clock.elapsed;
      if (remaining <= Duration.zero) {
        throw TimeoutException("Read deadline exceeded");
      }
      final payload = await _platform.readBattery(sample).timeout(remaining);
      return decodeBatterySample(payload, sample).forSample(sample);
    } catch (error) {
      return batteryFailure<BatterySnapshot>(error).forSample(sample);
    }
  }

  Future<BatteryOutcome<BatteryObservation>> sample({
    BatterySamplingOptions? options,
  }) => observe(options: options ?? BatterySamplingOptions());

  Future<BatteryOutcome<BatteryObservation>> watchChanges({
    BatteryChangeOptions? options,
  }) => observe(options: options ?? BatteryChangeOptions());

  Future<BatteryOutcome<BatteryObservation>> observe({
    BatteryObservationOptions? options,
  }) async {
    final clock = Stopwatch()..start();
    final selection = options ?? BatteryObservationOptions();
    final caps = await capabilities();
    if (!caps.isAvailable) {
      return BatteryOutcome.state(
        caps.status,
        caps.reason!.code,
        caps.reason!.message,
      );
    }
    if (!(selection.mode == BatteryDeliveryMode.changes
            ? caps.value!.changeObservationSupported
            : caps.value!.observationSupported) ||
        !selection.samples.every(
          selection.mode == BatteryDeliveryMode.changes
              ? caps.value!.supportsChanges
              : caps.value!.supportsObservation,
        )) {
      return BatteryOutcome.state(
        BatteryStatus.unsupported,
        'observation_unsupported',
        'Requested observation samples are not implemented',
      );
    }
    var expired = false;
    late final Future<NativeBatteryObservation> opening;
    try {
      opening = _platform.observeBattery(selection);
    } catch (error) {
      return batteryFailure(error);
    }
    unawaited(
      opening
          .then((owner) async {
            if (expired) await owner.close();
          })
          .catchError((Object _) {}),
    );
    try {
      final remaining = timeout - clock.elapsed;
      if (remaining <= Duration.zero) {
        throw TimeoutException("Observation deadline exceeded");
      }
      final owner = await opening.timeout(remaining);
      return BatteryOutcome.available(
        BatteryObservation.fromNative(owner, timeout),
      );
    } catch (error) {
      expired = true;
      return batteryFailure(error);
    }
  }
}
