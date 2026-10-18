import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_battery/flutter_battery.dart';
import 'package:flutter_battery/flutter_battery_platform_interface.dart';
import 'package:flutter_battery/flutter_battery_method_channel.dart';
import 'package:flutter_battery/src/native_battery_monitoring.dart';
import 'package:flutter_battery/src/platform_capabilities.dart';
import 'package:flutter_test/flutter_test.dart';

class TestPlatform extends FlutterBatteryPlatform {
  Map<String, dynamic> payload = {'availability': 'available', 'level': 0};
  Object? fault;
  Future<Map<String, dynamic>>? pendingRead;
  Future<NativeBatteryObservation>? pendingOpen;
  var rejectClose = false;
  // Ownership is released through a local alias or the owner teardown; covered by lifecycle tests.
  // ignore: close_sinks
  final source = StreamController<Map<String, dynamic>>.broadcast();
  late final hub = BatteryObservationCoordinator(
    source: source.stream,
    configure: (config) async {
      if (rejectClose && config['monitorBatteryLevel'] == false) {
        throw PlatformException(code: 'RELEASE_FAILED');
      }
    },
  );
  @override
  Future<BatteryPlatformCapabilities> queryCapabilities() async =>
      const BatteryPlatformCapabilities(
        features: {
          BatteryFeature.batteryLevel: true,
          BatteryFeature.batteryInfo: true,
          BatteryFeature.batteryHealth: true,
          BatteryFeature.batteryLevelStream: true,
          BatteryFeature.batteryInfoStream: true,
          BatteryFeature.batteryHealthStream: true,
          BatteryFeature.scopedObservations: true,
          BatteryFeature.changeNotifications: true,
        },
      );
  @override
  Future<Map<String, dynamic>> readBattery(BatterySample sample) async {
    if (fault != null) throw fault!;
    if (pendingRead != null) return await pendingRead!;
    return payload;
  }

  @override
  Future<NativeBatteryObservation> observeBattery(
    BatteryObservationOptions options,
  ) => pendingOpen ?? hub.open(options);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final cases = <String, (Map<String, dynamic>, BatteryStatus)>{
    'real zero': (
      {
        'availability': 'available',
        'level': 0,
        'temperature': 0.0,
        'voltage': 0.0,
      },
      BatteryStatus.available,
    ),
    'no battery': ({'availability': 'noBattery'}, BatteryStatus.noBattery),
    'unknown': ({'availability': 'unknown'}, BatteryStatus.unknown),
    'empty': ({}, BatteryStatus.invalidData),
    'invalid availability': (
      {'availability': false, 'level': 50},
      BatteryStatus.invalidData,
    ),
    'missing level': ({'availability': 'available'}, BatteryStatus.invalidData),
    'negative level': (
      {'availability': 'available', 'level': -1},
      BatteryStatus.invalidData,
    ),
    'too high': (
      {'availability': 'available', 'level': 101},
      BatteryStatus.invalidData,
    ),
    'wrong charging': (
      {'availability': 'available', 'level': 50, 'isCharging': 'false'},
      BatteryStatus.invalidData,
    ),
    'wrong temperature': (
      {'availability': 'available', 'level': 50, 'temperature': '0'},
      BatteryStatus.invalidData,
    ),
    'nonfinite': (
      {'availability': 'available', 'level': 50, 'voltage': double.infinity},
      BatteryStatus.invalidData,
    ),
    'wrong timestamp': (
      {'availability': 'available', 'level': 50, 'timestamp': -1},
      BatteryStatus.invalidData,
    ),
  };
  for (final item in cases.entries) {
    test('read classifies ${item.key}', () async {
      final platform = TestPlatform()..payload = item.value.$1;
      final result = await FlutterBattery(platform: platform).read();
      expect(result.status, item.value.$2);
      expect(result.value != null, result.isAvailable);
      if (!result.isAvailable) expect(result.reason!.code, isNotEmpty);
      if (item.key == 'real zero') {
        expect(result.value!.temperatureCelsius, 0);
        expect(result.value!.voltageVolts, 0);
      }
      await platform.source.close();
    });
  }
  test('optional fields stay unknown, no manufactured timestamp', () async {
    final platform = TestPlatform();
    final result = await FlutterBattery(platform: platform).read();
    expect(result.value!.isCharging, isNull);
    expect(result.value!.temperatureCelsius, isNull);
    expect(result.value!.timestamp, isNull);
    await platform.source.close();
  });
  test('health unknown differs from no battery', () async {
    final platform = TestPlatform()
      ..payload = {
        'availability': 'available',
        'level': 70,
        'state': 'UNKNOWN',
      };
    final battery = FlutterBattery(platform: platform);
    expect(
      (await battery.read(sample: BatterySample.health)).status,
      BatteryStatus.unknown,
    );
    platform.payload = {'availability': 'noBattery'};
    expect(
      (await battery.read(sample: BatterySample.health)).status,
      BatteryStatus.noBattery,
    );
    await platform.source.close();
  });
  for (final item in {
    'NOT_SUPPORTED': BatteryStatus.unsupported,
    'PERMISSION_DENIED': BatteryStatus.permissionDenied,
    'UNAVAILABLE': BatteryStatus.unavailable,
    'OTHER': BatteryStatus.failed,
  }.entries) {
    test(
      'native ${item.key} is a structured result and retry recovers',
      () async {
        final platform = TestPlatform()
          ..fault = PlatformException(code: item.key);
        final battery = FlutterBattery(platform: platform);
        expect((await battery.read()).status, item.value);
        platform.fault = null;
        expect((await battery.read()).status, BatteryStatus.available);
        await platform.source.close();
      },
    );
  }
  test(
    'platform-reported limited capacity is a typed health condition',
    () async {
      final platform = TestPlatform()
        ..payload = {
          'availability': 'available',
          'level': 40,
          'state': 'DEGRADED',
        };
      final result = await FlutterBattery(
        platform: platform,
      ).read(sample: BatterySample.health);
      expect(result.status, BatteryStatus.available);
      expect(result.value!.health, BatteryHealthCondition.degraded);
      await platform.source.close();
    },
  );
  test('invalid health label is not an unknown measurement', () async {
    final platform = TestPlatform()
      ..payload = {
        'availability': 'available',
        'level': 70,
        'state': 'BAD_LABEL',
      };
    expect(
      (await FlutterBattery(
        platform: platform,
      ).read(sample: BatterySample.health)).status,
      BatteryStatus.invalidData,
    );
    await platform.source.close();
  });
  test('read timeout is bounded', () async {
    final platform = TestPlatform()
      ..pendingRead = Completer<Map<String, dynamic>>().future;
    expect(
      (await FlutterBattery(
        platform: platform,
        timeout: const Duration(milliseconds: 20),
      ).read()).status,
      BatteryStatus.timedOut,
    );
    await platform.source.close();
  });
  test('late open after timeout releases its owner', () async {
    final platform = TestPlatform();
    final pending = Completer<NativeBatteryObservation>();
    platform.pendingOpen = pending.future;
    final result = await FlutterBattery(
      platform: platform,
      timeout: const Duration(milliseconds: 20),
    ).observe();
    expect(result.status, BatteryStatus.timedOut);
    pending.complete(await platform.hub.open(BatteryObservationOptions()));
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    expect(platform.source.hasListener, isFalse);
    await platform.source.close();
  });
  test(
    'event states, idempotent close and no queued data after close',
    () async {
      final platform = TestPlatform();
      final result = await FlutterBattery(platform: platform).watchChanges();
      final observation = result.value!;
      expect(observation.current.status, BatteryStatus.pending);
      final events = <BatteryOutcome<BatterySnapshot>>[];
      final subscription = observation.events.listen(events.add);
      platform.source.add({
        'type': 'BATTERY_LEVEL',
        'availability': 'available',
        'level': 60,
      });
      await Future<void>.delayed(Duration.zero);
      expect(observation.current.value!.level, 60);
      platform.source.add({
        'type': 'BATTERY_UNAVAILABLE',
        'availability': 'noBattery',
      });
      await Future<void>.delayed(Duration.zero);
      expect(observation.current.status, BatteryStatus.noBattery);
      subscription.pause();
      platform.source.add({
        'type': 'BATTERY_LEVEL',
        'availability': 'available',
        'level': 40,
      });
      await Future<void>.delayed(Duration.zero);
      final first = observation.close();
      expect(identical(first, observation.close()), isTrue);
      expect((await first).status, BatteryStatus.closed);
      subscription.resume();
      await Future<void>.delayed(Duration.zero);
      expect(events.any((event) => event.value?.level == 40), isFalse);
      expect(observation.state, BatteryObservationState.closed);
      expect(platform.source.hasListener, isFalse);
      await subscription.cancel();
      await platform.source.close();
    },
  );
  test(
    'event failure is explicit and same-value recovery is delivered',
    () async {
      final platform = TestPlatform();
      final observation = (await FlutterBattery(
        platform: platform,
      ).watchChanges()).value!;
      final subscription = observation.events.listen((_) {});
      platform.source.add({
        'type': 'BATTERY_LEVEL',
        'availability': 'available',
        'level': 60,
      });
      await Future<void>.delayed(Duration.zero);
      platform.source.addError(PlatformException(code: 'UNAVAILABLE'));
      await Future<void>.delayed(Duration.zero);
      expect(observation.current.status, BatteryStatus.unavailable);
      expect(observation.state, BatteryObservationState.failed);
      platform.source.add({
        'type': 'BATTERY_LEVEL',
        'availability': 'available',
        'level': 60,
      });
      await Future<void>.delayed(Duration.zero);
      expect(observation.current.status, BatteryStatus.available);
      expect(observation.state, BatteryObservationState.active);
      platform.source.add({
        'type': 'BATTERY_LEVEL',
        'availability': 'available',
        'level': 'bad',
      });
      await Future<void>.delayed(Duration.zero);
      expect(observation.current.status, BatteryStatus.invalidData);
      await observation.close();
      await subscription.cancel();
      await platform.source.close();
    },
  );
  test(
    'unsupported host differs from missing registered native adapter',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      expect(
        (await FlutterBattery().capabilities()).status,
        BatteryStatus.unsupported,
      );
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      const channel = MethodChannel('flutter_battery');
      messenger.setMockMethodCallHandler(channel, (_) async {
        throw MissingPluginException();
      });
      addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
      expect(
        (await FlutterBattery(
          platform: MethodChannelFlutterBattery(),
        ).capabilities()).status,
        BatteryStatus.unavailable,
      );
    },
  );

  test(
    'silent observation reports first-sample timeout and can recover',
    () async {
      final platform = TestPlatform();
      final observation = (await FlutterBattery(
        platform: platform,
        timeout: const Duration(milliseconds: 20),
      ).observe()).value!;
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(observation.current.status, BatteryStatus.timedOut);
      expect(observation.state, BatteryObservationState.failed);
      platform.source.add({
        'type': 'BATTERY_LEVEL',
        'availability': 'available',
        'level': 60,
      });
      await Future<void>.delayed(Duration.zero);
      expect(observation.current.status, BatteryStatus.available);
      await observation.close();
      await platform.source.close();
    },
  );
  test('close failure is explicit while local delivery is closed', () async {
    final platform = TestPlatform();
    final observation = (await FlutterBattery(
      platform: platform,
    ).observe()).value!;
    platform.rejectClose = true;
    expect((await observation.close()).status, BatteryStatus.failed);
    expect(observation.state, BatteryObservationState.closed);
    expect(platform.source.hasListener, isFalse);
    await platform.source.close();
  });
}
