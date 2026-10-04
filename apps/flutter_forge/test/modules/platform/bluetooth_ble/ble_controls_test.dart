import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_forge_app/modules/platform/bluetooth_ble/module_root.dart';
import 'package:flutter_forge_app/modules/platform/bluetooth_ble/state/ble_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_ble/universal_ble.dart';

import 'ble_session_test.dart' show FakeBleClient;

Future<void> flush() => Future<void>.delayed(Duration.zero);

class ControlledClient extends FakeBleClient {
  Completer<void>? startGate;
  Completer<void>? connectGate;
  Completer<List<BleService>>? discoverGate;
  Completer<void>? disconnectGate;
  Completer<void>? stopGate;
  Completer<Uint8List>? readGate;
  Completer<bool>? permissionGate;
  bool failConnect = false;
  bool keepScanning = false;
  bool keepConnected = false;

  @override
  Future<bool> hasPermissions() async => permissionGate == null
      ? await super.hasPermissions()
      : await permissionGate!.future;

  @override
  Future<void> startScan() async {
    startCount++;
    await startGate?.future;
    nativeScanning = true;
  }

  @override
  Future<void> connect(String id) async {
    nativeState = BleConnectionState.connecting;
    await connectGate?.future;
    if (failConnect) {
      nativeState = BleConnectionState.disconnected;
      throw StateError('connection refused');
    }
    nativeState = BleConnectionState.connected;
  }

  @override
  Future<List<BleService>> discover(String id) async =>
      discoverGate == null ? services : await discoverGate!.future;

  @override
  Future<void> disconnect(String id) async {
    disconnectCount++;
    await disconnectGate?.future;
    if (!keepConnected) nativeState = BleConnectionState.disconnected;
  }

  @override
  Future<void> stopScan() async {
    stopCount++;
    await stopGate?.future;
    if (!keepScanning) nativeScanning = false;
  }

  @override
  Future<Uint8List> read(
    String id,
    String service,
    String characteristic,
  ) async {
    readCount++;
    return readGate == null
        ? Uint8List.fromList([100])
        : await readGate!.future;
  }
}

void main() {
  final device = BleDevice(deviceId: 'sensor', name: 'Sensor');
  final service = BleService('180f', [
    BleCharacteristic('2a19', [CharacteristicProperty.read], []),
  ]);

  test(
    'cancelling permission preparation leaves existing system connections alone',
    () async {
      final client = ControlledClient()
        ..permissionGate = Completer<bool>()
        ..nativeState = BleConnectionState.connected;
      final session = BleSession(client);
      final connect = session.connect(device);
      await session.cancelConnection();
      expect(client.disconnectCount, 0);
      client.permissionGate!.complete(true);
      await connect;
      expect(client.nativeState, BleConnectionState.connected);
      expect(session.connectedId, isNull);
      await session.close();
      await client.close();
    },
  );

  test('connection preflight rejects a powered-off adapter', () async {
    final client = ControlledClient()..poweredOn = false;
    final session = BleSession(client);
    await session.connect(device);
    expect(session.canConnect, isFalse);
    expect(session.canStartScan, isFalse);
    expect(client.disconnectCount, 0);
    expect(client.nativeState, BleConnectionState.disconnected);
    await session.close();
    await client.close();
  });

  test(
    'permission refusal before connection does not disconnect an unowned device',
    () async {
      final client = ControlledClient()..denyPermission = true;
      final session = BleSession(client);
      await session.connect(device);
      expect(session.linkPhase, BleLinkPhase.failed);
      expect(client.nativeState, BleConnectionState.disconnected);
      expect(client.disconnectCount, 0);
      await session.close();
      await client.close();
    },
  );

  test(
    'a timed-out native scan start cannot later leave the scanner running',
    () async {
      final client = ControlledClient()..startGate = Completer<void>();
      final session = BleSession(
        client,
        operationLimit: const Duration(milliseconds: 20),
      );
      await session.startScan();
      expect(session.scanPhase, BleScanPhase.idle);
      client.startGate!.complete();
      await flush();
      expect(client.nativeScanning, isFalse);
      await session.close();
      await client.close();
    },
  );

  test(
    'scan duration controls the deadline and rejects unbounded requests',
    () async {
      var now = DateTime(2026, 10, 2);
      final client = ControlledClient();
      final session = BleSession(client, now: () => now);
      await session.startScan(duration: const Duration(seconds: 20));
      expect(session.scanSecondsRemaining, 20);
      now = now.add(const Duration(seconds: 4));
      expect(session.scanSecondsRemaining, 16);
      await session.stopScan();
      await session.startScan(duration: const Duration(seconds: 90));
      expect(client.startCount, 1);
      expect(session.error, contains('不超过 60 秒'));
      await session.close();
      await client.close();
    },
  );

  test(
    'connection timeout is bounded and a late success is released',
    () async {
      final client = ControlledClient()..connectGate = Completer<void>();
      final session = BleSession(
        client,
        connectionTimeout: const Duration(milliseconds: 20),
      );
      await session.connect(device);
      expect(session.linkPhase, BleLinkPhase.failed);
      expect(session.error, contains('超时'));
      client.connectGate!.complete();
      await flush();
      expect(client.nativeState, BleConnectionState.disconnected);
      expect(session.connectedId, isNull);
      await session.close();
      await client.close();
    },
  );

  test('duplicate characteristic reads share a guarded operation', () async {
    final client = ControlledClient()..readGate = Completer<Uint8List>();
    final session = BleSession(client);
    await session.connect(device);
    final first = session.read(service, service.characteristics.first);
    await session.read(service, service.characteristics.first);
    expect(client.readCount, 1);
    expect(session.pendingCharacteristics, isNotEmpty);
    client.readGate!.complete(Uint8List.fromList([42]));
    await first;
    expect(session.pendingCharacteristics, isEmpty);
    await session.close();
    await client.close();
  });

  test(
    'scan preserves previous results and ages advertisement state',
    () async {
      var now = DateTime(2026, 10, 2, 10);
      final client = ControlledClient();
      final session = BleSession(client, now: () => now);
      await session.startScan();
      client.scan.add(device);
      await flush();
      expect(session.currentRoundIds, {'sensor'});
      expect(
        session.advertisementState('sensor'),
        BleAdvertisementState.currentRound,
      );
      await session.stopScan();
      await session.startScan();
      expect(session.devices.keys, ['sensor']);
      expect(session.currentRoundIds, isEmpty);
      expect(
        session.advertisementState('sensor'),
        BleAdvertisementState.previousRound,
      );
      now = now.add(const Duration(seconds: 21));
      expect(
        session.advertisementState('sensor'),
        BleAdvertisementState.expired,
      );
      client.scan.add(device);
      await flush();
      expect(
        session.advertisementState('sensor'),
        BleAdvertisementState.currentRound,
      );
      expect(session.scanSecondsRemaining, 0);
      await session.stopScan();
      session.clearScanHistory();
      expect(session.lastSeen, isEmpty);
      await session.close();
      await client.close();
    },
  );

  test('stopping keeps scan active until backend confirmation', () async {
    final client = ControlledClient()..stopGate = Completer<void>();
    final session = BleSession(client);
    await session.startScan();
    final stop = session.stopScan();
    expect(session.scanPhase, BleScanPhase.stopping);
    expect(session.scanning, isTrue);
    expect(session.canStartScan, isFalse);
    client.stopGate!.complete();
    await stop;
    expect(session.scanPhase, BleScanPhase.idle);
    expect(client.nativeScanning, isFalse);
    await session.close();
    await client.close();
  });

  test(
    'unconfirmed scan stop blocks connection and supports another stop',
    () async {
      final client = ControlledClient()..keepScanning = true;
      final session = BleSession(client);
      await session.startScan();
      await session.stopScan();
      expect(session.scanPhase, BleScanPhase.unconfirmed);
      expect(session.canConnect, isFalse);
      expect(session.error, contains('停止扫描未确认'));
      client.keepScanning = false;
      await session.stopScan();
      expect(session.scanPhase, BleScanPhase.idle);
      expect(session.canConnect, isTrue);
      await session.close();
      await client.close();
    },
  );

  test(
    'connection phases separate the native link from GATT readiness',
    () async {
      final client = ControlledClient()
        ..discoverGate = Completer<List<BleService>>();
      final session = BleSession(client);
      final connect = session.connect(device);
      expect(session.linkPhase, BleLinkPhase.connecting);
      expect(session.canConnect, isFalse);
      await flush();
      expect(session.linkPhase, BleLinkPhase.discovering);
      expect(session.connectedId, 'sensor');
      expect(session.gattReady, isFalse);
      client.discoverGate!.complete([service]);
      await connect;
      expect(session.gattReady, isTrue);
      await session.close();
      await client.close();
    },
  );

  test(
    'cancel releases a connecting device and cleans a late successful connection',
    () async {
      final client = ControlledClient()..connectGate = Completer<void>();
      final session = BleSession(client);
      final connect = session.connect(device);
      expect(session.canCancelConnection, isTrue);
      await flush();
      await session.cancelConnection();
      expect(session.linkPhase, BleLinkPhase.idle);
      expect(session.connectedId, isNull);
      client.connectGate!.complete();
      await connect;
      await flush();
      expect(session.connectedId, isNull);
      expect(client.nativeState, BleConnectionState.disconnected);
      expect(client.disconnectCount, greaterThanOrEqualTo(2));
      await session.close();
      await client.close();
    },
  );

  test(
    'a late service discovery cannot refill a cancelled connection',
    () async {
      final client = ControlledClient()
        ..discoverGate = Completer<List<BleService>>();
      final session = BleSession(client);
      final connect = session.connect(device);
      await flush();
      await session.cancelConnection();
      client.discoverGate!.complete([service]);
      await connect;
      expect(session.connectedId, isNull);
      expect(session.services, isEmpty);
      expect(session.linkPhase, BleLinkPhase.idle);
      await session.close();
      await client.close();
    },
  );

  test(
    'unexpected disconnect invalidates in-flight service discovery',
    () async {
      final client = ControlledClient()
        ..discoverGate = Completer<List<BleService>>();
      final session = BleSession(client);
      final connect = session.connect(device);
      await flush();
      client.nativeState = BleConnectionState.disconnected;
      client.connection.add(false);
      await flush();
      client.discoverGate!.complete([service]);
      await connect;
      expect(session.services, isEmpty);
      expect(session.linkPhase, BleLinkPhase.failed);
      expect(session.canRetryConnection, isTrue);
      await session.close();
      await client.close();
    },
  );

  test(
    'disconnect keeps the link visible until the native state is confirmed',
    () async {
      final client = ControlledClient();
      final session = BleSession(client);
      await session.connect(device);
      client.disconnectGate = Completer<void>();
      final disconnect = session.disconnect();
      expect(session.linkPhase, BleLinkPhase.disconnecting);
      expect(session.connectedId, 'sensor');
      expect(session.gattReady, isFalse);
      client.disconnectGate!.complete();
      await disconnect;
      expect(session.connectedId, isNull);
      await session.close();
      await client.close();
    },
  );

  test(
    'a silent disconnect failure remains unconfirmed and can be retried',
    () async {
      final client = ControlledClient();
      final session = BleSession(client);
      await session.connect(device);
      client.keepConnected = true;
      await session.disconnect();
      expect(session.linkPhase, BleLinkPhase.disconnectUnconfirmed);
      expect(session.connectedId, 'sensor');
      expect(session.canConnect, isFalse);
      client.keepConnected = false;
      await session.disconnect();
      expect(session.connectedId, isNull);
      expect(session.linkPhase, BleLinkPhase.idle);
      await session.close();
      await client.close();
    },
  );

  test('failed connection can retry the same selected target', () async {
    final client = ControlledClient()..failConnect = true;
    final session = BleSession(client);
    await session.connect(device);
    expect(session.canRetryConnection, isTrue);
    client.failConnect = false;
    await session.retryConnection();
    expect(session.gattReady, isTrue);
    expect(session.error, isNull);
    await session.close();
    await client.close();
  });

  test('a late read cannot refill values after disconnect', () async {
    final client = ControlledClient()
      ..services = [service]
      ..readGate = Completer<Uint8List>();
    final session = BleSession(client);
    await session.connect(device);
    final read = session.read(service, service.characteristics.first);
    await session.disconnect();
    client.readGate!.complete(Uint8List.fromList([42]));
    await read;
    expect(session.values, isEmpty);
    await session.close();
    await client.close();
  });

  test('page disposal cannot receive a late discovery update', () async {
    final client = ControlledClient()
      ..discoverGate = Completer<List<BleService>>();
    final session = BleSession(client);
    final connect = session.connect(device);
    await flush();
    await session.close();
    client.discoverGate!.complete([service]);
    await connect;
    expect(session.services, isEmpty);
    await client.close();
  });

  test('leaving the foreground requests a confirmed scan stop', () async {
    final client = ControlledClient();
    final session = BleSession(client);
    await session.startScan();
    session.setActive(false);
    await flush();
    expect(client.nativeScanning, isFalse);
    expect(session.canStartScan, isFalse);
    session.setActive(true);
    expect(session.canStartScan, isTrue);
    await session.close();
    await client.close();
  });

  testWidgets('connection progress exposes cancellation and retry controls', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1100, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final client = ControlledClient()..connectGate = Completer<void>();
    await tester.pumpWidget(
      MaterialApp(home: BluetoothBlePage(client: client)),
    );
    client.scan.add(device);
    client.scan.add(BleDevice(deviceId: 'secondary', name: 'Another sensor'));
    await tester.pump();
    final selectedConnect = find.descendant(
      of: find.byKey(const ValueKey('ble-device-sensor')),
      matching: find.byType(TextButton),
    );
    await tester.ensureVisible(selectedConnect);
    await tester.tap(selectedConnect);
    await tester.pump();
    expect(find.text('连接中 · 可以取消'), findsOneWidget);
    final anotherConnect = find.descendant(
      of: find.byKey(const ValueKey('ble-device-secondary')),
      matching: find.byType(TextButton),
    );
    expect(tester.widget<TextButton>(anotherConnect).onPressed, isNull);
    await tester.tap(find.byKey(const Key('ble-cancel-connection')));
    await tester.pump();
    expect(find.text('正在取消并确认释放'), findsNothing);
    client.connectGate!.completeError(StateError('cancelled by native'));
    await tester.pump();
    expect(find.byKey(const Key('ble-disconnect')), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await client.close();
  });

  testWidgets('RSSI updates preserve row order and show last-seen state', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1100, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final client = ControlledClient();
    await tester.pumpWidget(
      MaterialApp(home: BluetoothBlePage(client: client)),
    );
    client.scan.add(BleDevice(deviceId: 'first', name: 'First', rssi: -90));
    client.scan.add(BleDevice(deviceId: 'second', name: 'Second', rssi: -30));
    await tester.pump();
    expect(
      tester.getTopLeft(find.text('First')).dy,
      lessThan(tester.getTopLeft(find.text('Second')).dy),
    );
    client.scan.add(BleDevice(deviceId: 'first', name: 'First', rssi: -20));
    client.scan.add(BleDevice(deviceId: 'second', name: 'Second', rssi: -95));
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      tester.getTopLeft(find.text('First')).dy,
      lessThan(tester.getTopLeft(find.text('Second')).dy),
    );
    expect(find.textContaining('秒前'), findsNWidgets(2));
    await tester.pumpWidget(const SizedBox());
    await client.close();
  });
}
