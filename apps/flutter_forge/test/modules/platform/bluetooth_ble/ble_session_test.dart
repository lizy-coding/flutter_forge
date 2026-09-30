import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_forge_app/app/router/app_route_table.dart';
import 'package:flutter_forge_app/module_registry/app_platform_snapshot.dart';
import 'package:flutter_forge_app/modules/platform/bluetooth_ble/module_root.dart';
import 'package:flutter_forge_app/modules/platform/bluetooth_ble/state/ble_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_ble/universal_ble.dart';

void main() {
  testWidgets(
    'Windows uses the common BLE page without Android system controls',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      final client = FakeBleClient()
        ..systemDevices = [
          BleDevice(deviceId: 'windows-system', name: 'System BLE sensor'),
        ];
      await tester.pumpWidget(
        MaterialApp(home: BluetoothBlePage(client: client)),
      );
      await tester.pump();
      expect(find.text('System BLE sensor'), findsOneWidget);
      expect(find.text('连接 GATT'), findsOneWidget);
      expect(find.byKey(const Key('ble-enable-bluetooth')), findsNothing);
      expect(find.byKey(const Key('ble-bluetooth-settings')), findsNothing);
      expect(client.settingsCount, 0);
      await tester.pumpWidget(const SizedBox());
      await client.close();
      debugDefaultTargetPlatformOverride = null;
    },
  );
  testWidgets('system audio and GATT connections appear at top without scan', (
    tester,
  ) async {
    final client = FakeBleClient()
      ..systemDevices = [BleDevice(deviceId: 'gatt', name: 'System sensor')]
      ..audioDevices = [
        const SystemAudioDevice(
          id: 'audio',
          name: 'Connected headphones',
          profiles: ['音频', '通话'],
        ),
      ];
    await tester.pumpWidget(
      MaterialApp(home: BluetoothBlePage(client: client)),
    );
    await tester.pump();
    expect(find.text('Connected headphones'), findsOneWidget);
    expect(find.text('System sensor'), findsOneWidget);
    expect(find.text('连接 GATT'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Connected headphones')).dy,
      lessThan(tester.getTopLeft(find.text('蓝牙与权限')).dy),
    );
    client.audioDevices = [];
    client.systemDevices = [];
    await tester.tap(find.byKey(const Key('ble-system-devices')));
    await tester.pump();
    expect(find.text('Connected headphones'), findsNothing);
    expect(find.text('System sensor'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await client.close();
  });

  testWidgets('Android powered-on control opens settings for shutdown', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final client = FakeBleClient();
    await tester.pumpWidget(
      MaterialApp(home: BluetoothBlePage(client: client)),
    );
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('ble-bluetooth-settings')));
    await tester.tap(find.byKey(const Key('ble-bluetooth-settings')));
    await tester.pump();
    expect(client.settingsCount, 1);
    await tester.pumpWidget(const SizedBox());
    await client.close();
    debugDefaultTargetPlatformOverride = null;
  });

  test(
    'connection refresh replaces stale system devices and preserves active GATT',
    () async {
      final client = FakeBleClient()
        ..systemDevices = [BleDevice(deviceId: 'system', name: 'Sensor')];
      final session = BleSession(client);
      await session.connect(BleDevice(deviceId: 'active', name: 'Active'));
      await session.loadSystemDevices();
      expect(session.systemDevices.keys, ['system']);
      expect(session.connectedId, 'active');
      client.systemDevices = [];
      await session.loadSystemDevices();
      expect(session.systemDevices, isEmpty);
      expect(session.connectedId, 'active');
      await session.close();
      await client.close();
    },
  );

  test(
    'Bluetooth power-off clears current system and application connections',
    () async {
      final client = FakeBleClient()
        ..systemDevices = [BleDevice(deviceId: 'system', name: 'Sensor')];
      final session = BleSession(client);
      await session.refreshStatus();
      await session.connect(BleDevice(deviceId: 'active', name: 'Active'));
      client.available.add(AvailabilityState.poweredOff);
      await Future<void>.delayed(Duration.zero);
      expect(session.connectedId, isNull);
      expect(session.systemDevices, isEmpty);
      await session.close();
      await client.close();
    },
  );
  testWidgets('connected device stays at top with disconnect action', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final client = FakeBleClient();
    await tester.pumpWidget(
      MaterialApp(home: BluetoothBlePage(client: client)),
    );
    expect(find.text('当前连接'), findsOneWidget);
    client.scan.add(BleDevice(deviceId: 'device', name: 'Test device'));
    await tester.pump();
    await tester.ensureVisible(find.text('连接'));
    await tester.tap(find.text('连接'));
    await tester.pump();
    expect(find.text('Test device'), findsOneWidget);
    expect(find.byKey(const Key('ble-disconnect')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await client.close();
  });

  testWidgets('Android can request the system Bluetooth switch', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final client = FakeBleClient()..poweredOn = false;
    await tester.pumpWidget(
      MaterialApp(home: BluetoothBlePage(client: client)),
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('ble-enable-bluetooth')));
    await tester.pump();
    expect(client.enableCount, 1);
    expect(find.text('适配器：已开启'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await client.close();
    debugDefaultTargetPlatformOverride = null;
  });
  testWidgets(
    'scan list favors readable names and can reveal unnamed devices',
    (tester) async {
      tester.view.physicalSize = const Size(1000, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final client = FakeBleClient();
      await tester.pumpWidget(
        MaterialApp(home: BluetoothBlePage(client: client)),
      );
      client.scan.add(
        BleDevice(deviceId: 'named', name: 'iQOO TWS Air3', rssi: -50),
      );
      client.scan.add(BleDevice(deviceId: 'anonymous', name: null, rssi: -40));
      await tester.pump();
      expect(find.text('iQOO TWS Air3'), findsOneWidget);
      expect(find.text('未命名 BLE 设备'), findsNothing);
      await tester.ensureVisible(find.textContaining('显示未命名'));
      await tester.tap(find.textContaining('显示未命名'));
      await tester.pump();
      expect(find.text('未命名 BLE 设备'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('ble-device-search')),
        'iQOO',
      );
      await tester.pump();
      expect(find.text('iQOO TWS Air3'), findsOneWidget);
      expect(find.text('未命名 BLE 设备'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await client.close();
    },
  );

  test(
    'catalog opens BLE on Android macOS and Windows without claiming host acceptance',
    () {
      final module = AppRouteTable.modules.singleWhere(
        (item) => item.path == '/bluetooth-ble',
      );
      expect(module.platformSupport.excludedPlatforms, {
        AppTargetPlatform.iOS,
        AppTargetPlatform.web,
      });
      expect(module.platformSupport.openTargetPlatforms, [
        AppTargetPlatform.android,
        AppTargetPlatform.macOS,
        AppTargetPlatform.windows,
      ]);
    },
  );

  test('scan stops on timeout and reports empty result', () async {
    final client = FakeBleClient();
    final session = BleSession(
      client,
      scanDuration: const Duration(milliseconds: 20),
    );
    await session.startScan();
    expect(session.scanning, isTrue);
    await Future<void>.delayed(const Duration(milliseconds: 40));
    expect(session.scanning, isFalse);
    expect(client.stopCount, 1);
    expect(session.logs.first, contains('未发现'));
    await session.close();
    await client.close();
  });

  test('permission refusal prevents scanning', () async {
    final client = FakeBleClient()..denyPermission = true;
    final session = BleSession(client);
    await session.startScan();
    expect(client.startCount, 0);
    expect(session.error, contains('权限被拒绝'));
    await session.close();
    await client.close();
  });

  test(
    'read and subscription obey characteristic properties and release',
    () async {
      final client = FakeBleClient();
      final session = BleSession(client);
      final device = BleDevice(deviceId: 'device', name: 'Test');
      client.services = [
        BleService('180f', [
          BleCharacteristic('2a19', [
            CharacteristicProperty.read,
            CharacteristicProperty.notify,
          ], []),
          BleCharacteristic('2a1a', [CharacteristicProperty.write], []),
        ]),
      ];
      await session.connect(device);
      expect(session.connectedId, 'device');
      final service = session.services.single;
      await session.read(service, service.characteristics.last);
      expect(client.readCount, 0);
      await session.read(service, service.characteristics.first);
      expect(client.readCount, 1);
      expect(
        session.values['${service.uuid}/${service.characteristics.first.uuid}'],
        Uint8List.fromList([100]),
      );
      await session.toggleSubscription(service, service.characteristics.first);
      expect(session.subscriptions, isNotEmpty);
      await session.disconnect();
      expect(client.unsubscribeCount, 1);
      expect(client.disconnectCount, 1);
      expect(session.subscriptions, isEmpty);
      expect(session.services, isEmpty);
      await session.close();
      await client.close();
    },
  );
}

class FakeBleClient implements BleClient {
  final scan = StreamController<BleDevice>.broadcast();
  final available = StreamController<AvailabilityState>.broadcast();
  final connection = StreamController<bool>.broadcast();
  final valueStream = StreamController<Uint8List>.broadcast();
  List<BleService> services = [];
  bool denyPermission = false;
  bool poweredOn = true;
  int enableCount = 0;
  int settingsCount = 0;
  List<SystemAudioDevice> audioDevices = [];
  int startCount = 0;
  int stopCount = 0;
  int readCount = 0;
  int unsubscribeCount = 0;
  int disconnectCount = 0;
  List<BleDevice> systemDevices = [];

  @override
  Stream<BleDevice> get scanResults => scan.stream;
  @override
  Stream<AvailabilityState> get availabilityChanges => available.stream;
  @override
  Stream<bool> connectionChanges(String id) => connection.stream;
  @override
  Stream<Uint8List> values(String id, String characteristic) =>
      valueStream.stream;
  @override
  Future<AvailabilityState> availability() async =>
      poweredOn ? AvailabilityState.poweredOn : AvailabilityState.poweredOff;
  @override
  Future<bool> enableBluetooth() async {
    enableCount++;
    poweredOn = true;
    return true;
  }

  @override
  Future<void> openBluetoothSettings() async {
    settingsCount++;
  }

  @override
  Future<List<SystemAudioDevice>> getConnectedAudioDevices() async =>
      audioDevices;

  @override
  Future<bool> hasPermissions() async => !denyPermission;
  @override
  Future<void> requestPermissions() async {
    if (denyPermission) throw StateError('denied');
  }

  @override
  Future<void> startScan() async {
    startCount++;
  }

  @override
  Future<void> stopScan() async {
    stopCount++;
  }

  @override
  Future<List<BleDevice>> getSystemDevices() async => systemDevices;

  @override
  Future<void> connect(String id) async {}
  @override
  Future<void> disconnect(String id) async {
    disconnectCount++;
  }

  @override
  Future<List<BleService>> discover(String id) async => services;
  @override
  Future<Uint8List> read(
    String id,
    String service,
    String characteristic,
  ) async {
    readCount++;
    return Uint8List.fromList([100]);
  }

  @override
  Future<void> subscribe(
    String id,
    String service,
    String characteristic, {
    required bool indicate,
  }) async {}
  @override
  Future<void> unsubscribe(
    String id,
    String service,
    String characteristic,
  ) async {
    unsubscribeCount++;
  }

  Future<void> close() async {
    await scan.close();
    await available.close();
    await connection.close();
    await valueStream.close();
  }
}
