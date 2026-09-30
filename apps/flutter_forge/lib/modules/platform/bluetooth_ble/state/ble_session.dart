import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:universal_ble/universal_ble.dart';

abstract class BleClient {
  Stream<BleDevice> get scanResults;
  Stream<AvailabilityState> get availabilityChanges;
  Stream<bool> connectionChanges(String id);
  Stream<Uint8List> values(String id, String characteristic);
  Future<AvailabilityState> availability();
  Future<bool> hasPermissions();
  Future<void> requestPermissions();
  Future<bool> enableBluetooth();
  Future<void> startScan();
  Future<void> stopScan();
  Future<List<BleDevice>> getSystemDevices();
  Future<void> connect(String id);
  Future<void> disconnect(String id);
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
      UniversalBle.enableBluetooth(timeout: BleSession.operationTimeout);
  @override
  Future<void> startScan() => UniversalBle.startScan();
  @override
  Future<void> stopScan() => UniversalBle.stopScan();
  @override
  Future<List<BleDevice>> getSystemDevices() => UniversalBle.getSystemDevices();
  @override
  Future<void> connect(String id) =>
      UniversalBle.connect(id, timeout: const Duration(seconds: 15));
  @override
  Future<void> disconnect(String id) =>
      UniversalBle.disconnect(id, timeout: const Duration(seconds: 8));
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

class BleSession extends ChangeNotifier {
  static const operationTimeout = Duration(seconds: 8);
  BleSession(this.client, {this.scanDuration = const Duration(seconds: 10)}) {
    _scanSubscription = client.scanResults.listen((device) {
      devices[device.deviceId] = device;
      notifyListeners();
    });
    _availabilitySubscription = client.availabilityChanges.listen((state) {
      availabilityState = state;
      notifyListeners();
    });
  }

  final BleClient client;
  final Duration scanDuration;
  final Map<String, BleDevice> devices = {};
  final Map<String, Uint8List> values = {};
  final Set<String> subscriptions = {};
  final List<String> logs = [];
  AvailabilityState availabilityState = AvailabilityState.unknown;
  bool permissionGranted = false;
  bool scanning = false;
  bool busy = false;
  String? connectedId;
  String? error;
  List<BleService> services = [];
  StreamSubscription<BleDevice>? _scanSubscription;
  StreamSubscription<AvailabilityState>? _availabilitySubscription;
  StreamSubscription<bool>? _connectionSubscription;
  final Map<String, StreamSubscription<Uint8List>> _valueSubscriptions = {};
  Timer? _scanTimer;
  bool _closed = false;
  int _generation = 0;

  void _log(String message) {
    logs.insert(
      0,
      '${DateTime.now().toLocal().toIso8601String().substring(11, 19)} $message',
    );
    if (logs.length > 30) logs.removeLast();
    if (!_closed) notifyListeners();
  }

  Future<void> refreshStatus() async {
    try {
      availabilityState = await client.availability().timeout(operationTimeout);
      permissionGranted = await client.hasPermissions().timeout(
        operationTimeout,
      );
      error = null;
      notifyListeners();
    } catch (e) {
      error = '读取蓝牙状态失败：$e';
      notifyListeners();
    }
  }

  Future<void> requestEnableBluetooth() async {
    if (busy || availabilityState == AvailabilityState.poweredOn) return;
    busy = true;
    error = null;
    notifyListeners();
    try {
      final accepted = await client.enableBluetooth().timeout(operationTimeout);
      await refreshStatus();
      if (!accepted || availabilityState != AvailabilityState.poweredOn) {
        error = '蓝牙尚未开启，请在系统中开启后刷新状态。';
        _log(error!);
      } else {
        _log('系统蓝牙已开启');
      }
    } catch (e) {
      error = '请求开启系统蓝牙失败：$e';
      _log(error!);
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> startScan() async {
    if (scanning || busy || connectedId != null) return;
    busy = true;
    error = null;
    devices.clear();
    notifyListeners();
    try {
      await client.requestPermissions().timeout(operationTimeout);
      permissionGranted = true;
      await client.startScan().timeout(operationTimeout);
      scanning = true;
      _log('开始扫描，${scanDuration.inSeconds} 秒后自动停止');
      _scanTimer = Timer(scanDuration, () {
        stopScan();
      });
    } catch (e) {
      error = '扫描失败或权限被拒绝：$e';
      _log(error!);
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> stopScan() async {
    _scanTimer?.cancel();
    _scanTimer = null;
    if (!scanning) return;
    scanning = false;
    notifyListeners();
    try {
      await client.stopScan().timeout(operationTimeout);
      _log(devices.isEmpty ? '扫描结束：未发现 BLE 外设' : '扫描结束：${devices.length} 台设备');
    } catch (e) {
      error = '停止扫描失败：$e';
      _log(error!);
    }
  }

  Future<void> loadSystemDevices() async {
    if (busy || scanning || connectedId != null) return;
    busy = true;
    error = null;
    notifyListeners();
    try {
      final found = await client.getSystemDevices().timeout(operationTimeout);
      for (final device in found) {
        devices[device.deviceId] = device;
      }
      _log('系统已连接的 BLE 设备：${found.length} 台');
    } catch (e) {
      error = '查询系统 BLE 设备失败：$e';
      _log(error!);
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> connect(BleDevice device) async {
    if (busy || connectedId != null) return;
    busy = true;
    error = null;
    notifyListeners();
    await stopScan();
    final generation = ++_generation;
    final id = device.deviceId;
    var phase = '连接';
    try {
      _log('正在连接 ${device.rawName?.isNotEmpty == true ? device.rawName : id}');
      await client.connect(id);
      if (_closed || generation != _generation) return;
      connectedId = id;
      _connectionSubscription = client.connectionChanges(id).listen((
        connected,
      ) {
        if (!connected && connectedId == id) {
          _clearConnection();
          _log('设备已断开');
        }
      });
      _log('已连接 ${device.name?.isNotEmpty == true ? device.name : id}');
      phase = '服务发现';
      services = await client.discover(id);
      if (_closed || generation != _generation) return;
      _log('发现 ${services.length} 项服务');
    } catch (e) {
      error = e is TimeoutException
          ? '$phase 超时：请确认外设可连接、未连接其他主机后重试。'
          : '$phase 失败：$e';
      _log(error!);
      if (connectedId == id) {
        await disconnect();
      } else {
        try {
          await client.disconnect(id).timeout(const Duration(seconds: 2));
        } catch (_) {
          // A failed connection may not have a native link to release.
        }
      }
    } finally {
      busy = false;
      if (!_closed) notifyListeners();
    }
  }

  Future<void> read(
    BleService service,
    BleCharacteristic characteristic,
  ) async {
    final id = connectedId;
    if (id == null ||
        !characteristic.properties.contains(CharacteristicProperty.read)) {
      return;
    }
    try {
      final key = '${service.uuid}/${characteristic.uuid}';
      values[key] = await client.read(id, service.uuid, characteristic.uuid);
      _log('读取 ${characteristic.uuid}：${hex(values[key]!)}');
    } catch (e) {
      error = '读取失败：$e';
      _log(error!);
    }
  }

  Future<void> toggleSubscription(
    BleService service,
    BleCharacteristic characteristic,
  ) async {
    final id = connectedId;
    if (id == null) return;
    final key = '${service.uuid}/${characteristic.uuid}';
    final indicate = characteristic.properties.contains(
      CharacteristicProperty.indicate,
    );
    if (!indicate &&
        !characteristic.properties.contains(CharacteristicProperty.notify)) {
      return;
    }
    try {
      if (subscriptions.contains(key)) {
        await client.unsubscribe(id, service.uuid, characteristic.uuid);
        await _valueSubscriptions.remove(key)?.cancel();
        subscriptions.remove(key);
        _log('停止订阅 ${characteristic.uuid}');
      } else {
        _valueSubscriptions[key] = client
            .values(id, characteristic.uuid)
            .listen((data) {
              values[key] = data;
              _log('收到 ${characteristic.uuid}：${hex(data)}');
            });
        await client.subscribe(
          id,
          service.uuid,
          characteristic.uuid,
          indicate: indicate,
        );
        subscriptions.add(key);
        _log('订阅 ${characteristic.uuid}');
      }
    } catch (e) {
      await _valueSubscriptions.remove(key)?.cancel();
      error = '订阅操作失败：$e';
      _log(error!);
    }
  }

  Future<void> disconnect() async {
    final id = connectedId;
    if (id == null) return;
    ++_generation;
    for (final key in subscriptions.toList()) {
      final parts = key.split('/');
      try {
        await client.unsubscribe(id, parts[0], parts[1]);
      } catch (_) {
        /* A disconnected peripheral cannot acknowledge. */
      }
    }
    _clearConnection();
    try {
      await client.disconnect(id);
      _log('主动断开');
    } catch (e) {
      error = '断开失败：$e';
      _log(error!);
    }
  }

  void _clearConnection() {
    _connectionSubscription?.cancel();
    _connectionSubscription = null;
    for (final subscription in _valueSubscriptions.values) {
      subscription.cancel();
    }
    _valueSubscriptions.clear();
    subscriptions.clear();
    values.clear();
    services = [];
    connectedId = null;
    if (!_closed) notifyListeners();
  }

  static String hex(Uint8List data) =>
      data.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join(' ');

  Future<void> close() async {
    _scanTimer?.cancel();
    await stopScan();
    await disconnect();
    _closed = true;
    await _scanSubscription?.cancel();
    await _availabilitySubscription?.cancel();
    super.dispose();
  }
}
