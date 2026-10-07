import 'dart:async';

import 'package:flutter_battery/flutter_battery.dart';
import 'package:flutter_battery/flutter_battery_method_channel.dart';
import 'package:flutter_battery/flutter_bluetooth_method_channel.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'observers merge only selected samples and release independently',
    () async {
      final source = StreamController<Map<String, dynamic>>.broadcast();
      final configs = <Map<String, dynamic>>[];
      final hub = BatteryObservationCoordinator(
        source: source.stream,
        configure: (config) async {
          configs.add(config);
        },
      );
      final level = await hub.open(
        BatteryObservationOptions(levelIntervalMs: 500),
      );
      final info = await hub.open(
        BatteryObservationOptions(samples: {BatterySample.info}),
      );
      expect(source.hasListener, isTrue);
      expect(configs.last[BatteryPayloadKeys.monitorBatteryHealth], false);
      expect(configs.last[BatteryPayloadKeys.monitorBatteryLevel], true);
      expect(configs.last[BatteryPayloadKeys.monitorBatteryInfo], true);
      final received = <Map<String, dynamic>>[];
      final subscription = info.events.listen(received.add);
      await level.close();
      expect(configs.last[BatteryPayloadKeys.monitorBatteryLevel], false);
      expect(source.hasListener, isTrue);
      source.add({
        BatteryPayloadKeys.type: BatteryEventTypes.batteryInfo,
        BatteryPayloadKeys.level: 50,
      });
      await Future<void>.delayed(Duration.zero);
      expect(received, hasLength(1));
      await info.close();
      await info.close();
      expect(source.hasListener, isFalse);
      expect(configs.last[BatteryPayloadKeys.monitorBatteryInfo], false);
      await subscription.cancel();
      await source.close();
    },
  );

  test(
    'fast and slow observers keep their own interval and event filter',
    () async {
      final source = StreamController<Map<String, dynamic>>.broadcast();
      final configs = <Map<String, dynamic>>[];
      final hub = BatteryObservationCoordinator(
        source: source.stream,
        configure: (config) async {
          configs.add(config);
        },
      );
      final fast = await hub.open(
        BatteryObservationOptions(levelIntervalMs: 100, debounceLevel: false),
      );
      final slow = await hub.open(
        BatteryObservationOptions(levelIntervalMs: 1000),
      );
      final fastValues = <Map<String, dynamic>>[];
      final slowValues = <Map<String, dynamic>>[];
      final a = fast.events.listen(fastValues.add);
      final b = slow.events.listen(slowValues.add);
      expect(configs.last[BatteryPayloadKeys.intervalMs], 100);
      expect(configs.last[BatteryPayloadKeys.enableDebounce], false);
      source.add({
        BatteryPayloadKeys.type: BatteryEventTypes.batteryLevel,
        BatteryPayloadKeys.level: 50,
      });
      source.add({
        BatteryPayloadKeys.type: BatteryEventTypes.batteryHealth,
        BatteryPayloadKeys.level: 50,
      });
      await Future<void>.delayed(const Duration(milliseconds: 120));
      source.add({
        BatteryPayloadKeys.type: BatteryEventTypes.batteryLevel,
        BatteryPayloadKeys.level: 49,
      });
      await Future<void>.delayed(Duration.zero);
      expect(fastValues, hasLength(2));
      expect(slowValues, hasLength(1));
      await fast.close();
      expect(configs.last[BatteryPayloadKeys.intervalMs], 1000);
      await slow.close();
      await a.cancel();
      await b.cancel();
      await source.close();
    },
  );

  test('failed configuration does not replace an active owner', () async {
    final source = StreamController<Map<String, dynamic>>.broadcast();
    final hub = BatteryObservationCoordinator(
      source: source.stream,
      configure: (config) async {
        if (config[BatteryPayloadKeys.monitorBatteryHealth] == true) {
          throw StateError('configure failed');
        }
      },
    );
    final owner = await hub.open(BatteryObservationOptions());
    await expectLater(
      hub.open(BatteryObservationOptions(samples: {BatterySample.health})),
      throwsStateError,
    );
    expect(owner.isClosed, isFalse);
    expect(source.hasListener, isTrue);
    await owner.close();
    await source.close();
  });

  test('closing a paused consumer still releases native ownership', () async {
    final source = StreamController<Map<String, dynamic>>.broadcast();
    final hub = BatteryObservationCoordinator(
      source: source.stream,
      configure: (_) async {},
    );
    final owner = await hub.open(BatteryObservationOptions());
    final subscription = owner.events.listen((_) {})..pause();
    await owner.close().timeout(const Duration(seconds: 1));
    expect(source.hasListener, isFalse);
    await subscription.cancel();
    await source.close();
  });

  test(
    'cancel during configuration leaves no orphan native listener',
    () async {
      final source = StreamController<Map<String, dynamic>>.broadcast();
      final configure = Completer<void>();
      var calls = 0;
      final hub = BatteryObservationCoordinator(
        source: source.stream,
        configure: (_) async {
          if (++calls == 1) await configure.future;
        },
      );
      final stream = hub.watch(BatteryObservationOptions());
      expect(stream.isBroadcast, isTrue);
      final subscription = stream.listen((_) {});
      await Future<void>.delayed(Duration.zero);
      await subscription.cancel();
      configure.complete();
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(source.hasListener, isFalse);
      expect(calls, 2);
      await source.close();
    },
  );

  test('invalid options and absent measurements are explicit', () {
    expect(() => BatteryObservationOptions(samples: {}), throwsArgumentError);
    expect(
      () => BatteryObservationOptions(levelIntervalMs: 0),
      throwsArgumentError,
    );
    final info = BatteryInfo.fromMap({});
    expect(info.level, -1);
    expect(info.state, BatteryState.UNKNOWN);
    expect(BatteryHealth.fromMap({}).riskLevel, 'UNKNOWN');
  });

  test('empty native readings fail rather than fabricating zero', () async {
    const channel = MethodChannel(BatteryChannelNames.methodChannel);
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (_) async => null);
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
    final platform = MethodChannelFlutterBattery();
    await expectLater(
      platform.getBatteryInfo(),
      throwsA(isA<PlatformException>()),
    );
    await expectLater(
      platform.getBatteryHealth(),
      throwsA(isA<PlatformException>()),
    );
  });

  test('older native observation method maps to typed unsupported', () async {
    const channel = MethodChannel(BatteryChannelNames.methodChannel);
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (_) async {
      throw MissingPluginException();
    });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
    await expectLater(
      MethodChannelFlutterBattery().observeBattery(BatteryObservationOptions()),
      throwsA(
        isA<UnsupportedBatteryFeatureException>().having(
          (error) => error.feature,
          'feature',
          BatteryFeature.scopedObservations,
        ),
      ),
    );
  });

  test(
    'unimplemented characteristic subscription reports unsupported',
    () async {
      final bluetooth = MethodChannelFlutterBluetooth();
      await expectLater(
        bluetooth.subscribeToCharacteristic(
          deviceId: 'd',
          serviceUuid: 's',
          characteristicUuid: 'c',
        ),
        emitsError(isA<UnsupportedBatteryFeatureException>()),
      );
    },
  );

  test('peer permission failures are not swallowed', () async {
    const channel = MethodChannel(BatteryChannelNames.peerMethods);
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (_) async {
      throw PlatformException(code: 'PERMISSION_DENIED');
    });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
    await expectLater(
      PeerBatteryService().startAsMaster(),
      throwsA(isA<PlatformException>()),
    );
  });
}
