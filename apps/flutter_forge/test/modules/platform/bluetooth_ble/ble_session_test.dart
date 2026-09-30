import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_forge_app/app/router/app_route_table.dart';
import 'package:flutter_forge_app/module_registry/app_platform_snapshot.dart';
import 'package:flutter_forge_app/modules/platform/bluetooth_ble/module_root.dart';
import 'package:flutter_forge_app/modules/platform/bluetooth_ble/state/ble_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_ble/universal_ble.dart';

void main() {
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
    'catalog opens BLE on Android and macOS without claiming GATT acceptance',
    () {
      final module = AppRouteTable.modules.singleWhere(
        (item) => item.path == '/bluetooth-ble',
      );
      expect(module.platformSupport.excludedPlatforms, {
        AppTargetPlatform.iOS,
        AppTargetPlatform.web,
        AppTargetPlatform.windows,
      });
      expect(module.platformSupport.openTargetPlatforms, [
        AppTargetPlatform.android,
        AppTargetPlatform.macOS,
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
  Future<AvailabilityState> availability() async => AvailabilityState.poweredOn;
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
