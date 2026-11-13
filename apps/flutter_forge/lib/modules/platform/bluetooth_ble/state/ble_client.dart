import 'package:flutter/foundation.dart';
import 'package:bluetooth_system_bridge/bluetooth_system_bridge.dart';
import 'package:universal_ble/universal_ble.dart';
export 'package:bluetooth_system_bridge/bluetooth_system_bridge.dart'
    show SystemAudioDevice;

/// Shared bound for adapter operations; the session re-exports it as
/// [BleSession.operationTimeout].
const bleOperationTimeout = Duration(seconds: 8);

/// Platform boundary of the BLE module: everything the session state machine
/// may ask of the radio, and nothing about phases or generations.
abstract class BleClient {
  Stream<BleDevice> get scanResults;
  Stream<AvailabilityState> get availabilityChanges;
  Stream<bool> connectionChanges(String id);
  Stream<Uint8List> values(String id, String characteristic);
  Future<AvailabilityState> availability();
  Future<bool> hasPermissions();
  Future<void> requestPermissions();
  Future<bool> enableBluetooth();
  Future<void> openBluetoothSettings();
  Future<List<SystemAudioDevice>> getConnectedAudioDevices();
  Future<void> startScan();
  Future<void> stopScan();
  Future<bool> isScanning();
  Future<List<BleDevice>> getSystemDevices();
  Future<void> connect(String id);
  Future<void> disconnect(String id);
  Future<BleConnectionState> connectionState(String id);
  Future<List<BleService>> discover(String id);
  Future<Uint8List> read(String id, String service, String characteristic);
  Future<void> subscribe(
    String id,
    String service,
    String characteristic, {
    required bool indicate,
  });
  Future<void> unsubscribe(String id, String service, String characteristic);
}

class UniversalBleClient implements BleClient {
  UniversalBleClient({BluetoothSystemPlatform? system})
    : _system = system ?? BluetoothSystemPlatform.instance;
  final BluetoothSystemPlatform _system;
  @override
  Future<void> openBluetoothSettings() async {
    final outcome = await _system.openSettings();
    if (!outcome.isAvailable) {
      throw StateError('${outcome.status.name}: ${outcome.reason}');
    }
  }

  @override
  Future<List<SystemAudioDevice>> getConnectedAudioDevices() async {
    final outcome = await _system.connectedAudioDevices();
    if (outcome.status == BluetoothSystemStatus.unsupported) return [];
    if (!outcome.isAvailable) {
      throw StateError('${outcome.status.name}: ${outcome.reason}');
    }
    return outcome.value!;
  }

  @override
  Stream<BleDevice> get scanResults => UniversalBle.scanStream;
  @override
  Stream<AvailabilityState> get availabilityChanges =>
      UniversalBle.availabilityStream;
  @override
  Stream<bool> connectionChanges(String id) =>
      UniversalBle.connectionStream(id);
  @override
  Stream<Uint8List> values(String id, String characteristic) =>
      UniversalBle.characteristicValueStream(id, characteristic);
  @override
  Future<AvailabilityState> availability() =>
      UniversalBle.getBluetoothAvailabilityState();
  @override
  Future<bool> hasPermissions() => UniversalBle.hasPermissions();
  @override
  Future<void> requestPermissions() => UniversalBle.requestPermissions();
  @override
  Future<bool> enableBluetooth() =>
      UniversalBle.enableBluetooth(timeout: bleOperationTimeout);
  @override
  Future<void> startScan() => UniversalBle.startScan();
  @override
  Future<void> stopScan() => UniversalBle.stopScan();
  @override
  Future<bool> isScanning() => UniversalBle.isScanning();
  @override
  Future<List<BleDevice>> getSystemDevices() => UniversalBle.getSystemDevices();
  @override
  Future<void> connect(String id) =>
      UniversalBle.connect(id, timeout: const Duration(seconds: 15));
  @override
  Future<void> disconnect(String id) => UniversalBle.disconnect(
    id,
    timeout: const Duration(seconds: 8),
    queueId: 'ble-control/$id',
  );
  @override
  Future<BleConnectionState> connectionState(String id) =>
      UniversalBle.getConnectionState(
        id,
        timeout: const Duration(seconds: 3),
        queueId: 'ble-control/$id',
      );
  @override
  Future<List<BleService>> discover(String id) =>
      UniversalBle.discoverServices(id);
  @override
  Future<Uint8List> read(String id, String service, String characteristic) =>
      UniversalBle.read(id, service, characteristic);
  @override
  Future<void> subscribe(
    String id,
    String service,
    String characteristic, {
    required bool indicate,
  }) => indicate
      ? UniversalBle.subscribeIndications(id, service, characteristic)
      : UniversalBle.subscribeNotifications(id, service, characteristic);
  @override
  Future<void> unsubscribe(String id, String service, String characteristic) =>
      UniversalBle.unsubscribe(id, service, characteristic);
}
