import 'dart:async';

import 'package:flutter/services.dart';

import 'flutter_bluetooth_platform_interface.dart';
import 'src/battery_channel_contract.dart';
import 'src/platform_capabilities.dart';

class MethodChannelFlutterBluetooth extends FlutterBluetoothPlatform {
  static const MethodChannel _methodChannel = MethodChannel(
    BatteryChannelNames.bleMethods,
  );
  static const EventChannel _scanEventChannel = EventChannel(
    BatteryChannelNames.bleScanEvents,
  );
  static const EventChannel _connectionEventChannel = EventChannel(
    BatteryChannelNames.bleConnectionEvents,
  );

  Stream<List<BleDevice>>? _scanStream;
  Stream<BleConnectionEvent>? _connectionStream;

  Future<T?> _invoke<T>(String method, [Map<String, dynamic>? args]) async {
    try {
      return await _methodChannel.invokeMethod<T>(method, args);
    } on MissingPluginException {
      throw UnsupportedBatteryFeatureException(BatteryFeature.blePeerSync);
    } on PlatformException catch (error) {
      if (error.code == 'NOT_SUPPORTED') {
        throw UnsupportedBatteryFeatureException(
          BatteryFeature.blePeerSync,
          error.message ?? '',
        );
      }
      rethrow;
    }
  }

  @override
  Future<bool> isBleAvailable() async {
    final result = await _invoke<bool>(BatteryMethodNames.isBleAvailable);
    return result ?? false;
  }

  @override
  Future<bool> isBleEnabled() async {
    final result = await _invoke<bool>(BatteryMethodNames.isBleEnabled);
    return result ?? false;
  }

  @override
  Stream<List<BleDevice>> scanDevices({String? serviceUuid}) {
    _scanStream ??= _scanEventChannel
        .receiveBroadcastStream({BatteryPayloadKeys.serviceUuid: serviceUuid})
        .map((event) {
          final list = (event as List).cast<Object?>();
          return list.map((e) {
            final map = Map<String, Object?>.from(e as Map);
            return BleDevice.fromJson(map);
          }).toList();
        });
    return _scanStream!;
  }

  @override
  Future<void> startScan({String? serviceUuid}) async {
    await _invoke(BatteryMethodNames.startScan, {
      BatteryPayloadKeys.serviceUuid: serviceUuid,
    });
  }

  @override
  Future<void> stopScan() async {
    await _invoke(BatteryMethodNames.stopScan);
  }

  @override
  Stream<BleConnectionEvent> connectionEvents() {
    _connectionStream ??= _connectionEventChannel.receiveBroadcastStream().map((
      event,
    ) {
      final map = Map<String, Object?>.from(event as Map);
      return BleConnectionEvent.fromJson(map);
    });
    return _connectionStream!;
  }

  @override
  Future<void> connect(String deviceId, {bool autoConnect = false}) async {
    await _invoke(BatteryMethodNames.connect, {
      BatteryPayloadKeys.deviceId: deviceId,
      BatteryPayloadKeys.autoConnect: autoConnect,
    });
  }

  @override
  Future<void> disconnect([String? deviceId]) async {
    await _invoke(BatteryMethodNames.disconnect, {
      BatteryPayloadKeys.deviceId: deviceId,
    });
  }

  @override
  Future<bool> writeCharacteristic({
    required String deviceId,
    required String serviceUuid,
    required String characteristicUuid,
    required List<int> value,
    bool withResponse = true,
  }) async {
    final result = await _invoke<bool>(BatteryMethodNames.writeCharacteristic, {
      BatteryPayloadKeys.deviceId: deviceId,
      BatteryPayloadKeys.serviceUuid: serviceUuid,
      BatteryPayloadKeys.characteristicUuid: characteristicUuid,
      BatteryPayloadKeys.value: value,
      BatteryPayloadKeys.withResponse: withResponse,
    });
    return result ?? false;
  }

  @override
  Stream<List<int>> subscribeToCharacteristic({
    required String deviceId,
    required String serviceUuid,
    required String characteristicUuid,
  }) {
    return Stream.error(
      UnsupportedBatteryFeatureException(
        BatteryFeature.bleCharacteristicNotifications,
        'Characteristic notifications are not implemented.',
      ),
    );
  }

  @override
  Future<void> unsubscribeFromCharacteristic({
    required String deviceId,
    required String serviceUuid,
    required String characteristicUuid,
  }) async {
    throw UnsupportedBatteryFeatureException(
      BatteryFeature.bleCharacteristicNotifications,
      'Characteristic notifications are not implemented.',
    );
  }
}
