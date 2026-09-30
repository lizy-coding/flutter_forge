import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:universal_ble/universal_ble.dart';
import 'package:url_launcher/url_launcher.dart';

class SystemAudioDevice {
  const SystemAudioDevice({
    required this.id,
    required this.name,
    required this.profiles,
  });
  final String id;
  final String? name;
  final List<String> profiles;
}

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
  static const _systemChannel = MethodChannel('flutter_forge/bluetooth_system');
  @override
  Future<void> openBluetoothSettings() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      await _systemChannel.invokeMethod<void>('openSettings');
      return;
    }
    final uri = switch (defaultTargetPlatform) {
      TargetPlatform.macOS => Uri.parse(
        'x-apple.systempreferences:com.apple.BluetoothSettings',
      ),
      TargetPlatform.windows => Uri.parse('ms-settings:bluetooth'),
      _ => throw UnsupportedError('当前平台不提供系统蓝牙设置入口'),
    };
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw StateError('系统未能打开蓝牙设置');
    }
  }

  @override
  Future<List<SystemAudioDevice>> getConnectedAudioDevices() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return [];
    final result =
        await _systemChannel.invokeListMethod<Map<Object?, Object?>>(
          'connectedAudioDevices',
        ) ??
        [];
    return result
        .map(
          (item) => SystemAudioDevice(
            id: item['id'] as String,
            name: item['name'] as String?,
            profiles: (item['profiles'] as List).cast<String>(),
          ),
        )
        .toList();
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
      if (state == AvailabilityState.poweredOff) {
        ++_connectionQueryGeneration;
        systemDevices.clear();
        systemAudioDevices = [];
        scanning = false;
        _scanTimer?.cancel();
        ++_generation;
        _clearConnection();
      } else if (state == AvailabilityState.poweredOn) {
        refreshStatus();
      }
      notifyListeners();
    });
  }

  final BleClient client;
  final Duration scanDuration;
  final Map<String, BleDevice> devices = {};
  final Map<String, BleDevice> systemDevices = {};
  List<SystemAudioDevice> systemAudioDevices = [];
  bool refreshingConnections = false;
  String? connectionQueryError;
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
  int _connectionQueryGeneration = 0;

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
      final state = await client.availability().timeout(operationTimeout);
      final granted = await client.hasPermissions().timeout(operationTimeout);
      if (_closed) return;
      availabilityState = state;
      permissionGranted = granted;
      error = null;
      notifyListeners();
      if (state == AvailabilityState.poweredOn && granted) {
        await loadSystemDevices(requestPermission: false);
      } else {
        ++_connectionQueryGeneration;
        systemDevices.clear();
        systemAudioDevices = [];
        notifyListeners();
      }
    } catch (e) {
      if (_closed) return;
      error = '读取蓝牙状态失败：$e';
      notifyListeners();
    }
  }

  Future<void> requestEnableBluetooth() async {
    if (_closed || busy || availabilityState == AvailabilityState.poweredOn) {
      return;
    }
    busy = true;
    error = null;
    notifyListeners();
    try {
      await client.requestPermissions().timeout(operationTimeout);
      permissionGranted = await client.hasPermissions().timeout(
        operationTimeout,
      );
      if (_closed) return;
      if (!permissionGranted) throw StateError('蓝牙权限未授予');
      final accepted = await client.enableBluetooth().timeout(
        const Duration(seconds: 60),
      );
      if (_closed) return;
      await refreshStatus();
      if (!accepted || availabilityState != AvailabilityState.poweredOn) {
        error = '蓝牙尚未开启，请在系统中开启后刷新状态。';
        _log(error!);
      } else {
        _log('系统蓝牙已开启');
      }
    } catch (e) {
      if (_closed) return;
      error = '请求开启系统蓝牙失败：$e';
      _log(error!);
    } finally {
      busy = false;
      if (!_closed) notifyListeners();
    }
  }

  Future<void> openBluetoothSettings() async {
    try {
      await client.openBluetoothSettings();
    } catch (e) {
      if (_closed) return;
      error = '打开系统蓝牙设置失败：$e';
      _log(error!);
    }
  }

  Future<void> startScan() async {
    if (_closed || scanning || busy || connectedId != null) return;
    busy = true;
    error = null;
    devices.clear();
    notifyListeners();
    try {
      await client.requestPermissions().timeout(operationTimeout);
      permissionGranted = await client.hasPermissions().timeout(
        operationTimeout,
      );
      if (_closed) return;
      if (!permissionGranted) throw StateError('蓝牙权限未授予');
      await client.startScan().timeout(operationTimeout);
      if (_closed) {
        await client.stopScan().timeout(operationTimeout);
        return;
      }
      scanning = true;
      _log('开始扫描，${scanDuration.inSeconds} 秒后自动停止');
      _scanTimer = Timer(scanDuration, () {
        stopScan();
      });
    } catch (e) {
      if (_closed) return;
      error = '扫描失败或权限被拒绝：$e';
      _log(error!);
    } finally {
      busy = false;
      if (!_closed) notifyListeners();
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

  Future<void> loadSystemDevices({bool requestPermission = true}) async {
    if (_closed || refreshingConnections) return;
    refreshingConnections = true;
    final queryGeneration = ++_connectionQueryGeneration;
    connectionQueryError = null;
    notifyListeners();
    try {
      if (requestPermission) {
        await client.requestPermissions().timeout(operationTimeout);
      }
      final granted = await client.hasPermissions().timeout(operationTimeout);
      if (_closed) return;
      permissionGranted = granted;
      if (!granted) throw StateError('请先授予蓝牙连接权限');
      final state = await client.availability().timeout(operationTimeout);
      if (_closed) return;
      availabilityState = state;
      if (state != AvailabilityState.poweredOn) {
        systemDevices.clear();
        systemAudioDevices = [];
        return;
      }
      final found = await client.getSystemDevices().timeout(operationTimeout);
      final audio = await client.getConnectedAudioDevices().timeout(
        operationTimeout,
      );
      if (_closed || queryGeneration != _connectionQueryGeneration) return;
      systemDevices
        ..clear()
        ..addEntries(found.map((device) => MapEntry(device.deviceId, device)));
      systemAudioDevices = audio;
      _log('系统已连接的 BLE 设备：${found.length} 台');
    } catch (e) {
      if (_closed) return;
      connectionQueryError = '查询系统连接失败：$e';
      _log(connectionQueryError!);
    } finally {
      refreshingConnections = false;
      if (!_closed) notifyListeners();
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
      devices[id] = device;
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
    _closed = true;
    _scanTimer?.cancel();
    await stopScan();
    await disconnect();
    await _scanSubscription?.cancel();
    await _availabilitySubscription?.cancel();
    super.dispose();
  }
}
