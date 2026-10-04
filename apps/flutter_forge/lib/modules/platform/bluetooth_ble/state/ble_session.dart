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

enum BleScanPhase { idle, starting, running, stopping, unconfirmed }

enum BleLinkPhase {
  idle,
  connecting,
  discovering,
  ready,
  cancelling,
  disconnecting,
  disconnectUnconfirmed,
  failed,
}

enum BleAdvertisementState { currentRound, previousRound, expired }

class BleSession extends ChangeNotifier {
  static const operationTimeout = Duration(seconds: 8);
  BleSession(
    this.client, {
    this.scanDuration = const Duration(seconds: 10),
    this.staleAfter = const Duration(seconds: 20),
    this.connectionTimeout = const Duration(seconds: 15),
    this.operationLimit = operationTimeout,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now {
    _scanSubscription = client.scanResults.listen((device) {
      if (_closed) return;
      devices[device.deviceId] = device;
      lastSeen[device.deviceId] = _now();
      discoveryOrder.putIfAbsent(device.deviceId, () => discoveryOrder.length);
      if (scanning || scanPhase == BleScanPhase.starting) {
        currentRoundIds.add(device.deviceId);
      }
      _startHeartbeat();
      if (_scanUpdateTimer == null) {
        _notify();
        _scanUpdateTimer = Timer(const Duration(milliseconds: 250), () {
          _scanUpdateTimer = null;
          _notify();
        });
      }
    });
    _availabilitySubscription = client.availabilityChanges.listen((state) {
      if (_closed) return;
      _applyAvailability(state);
      if (state == AvailabilityState.poweredOn) refreshStatus();
      _notify();
    });
  }

  final BleClient client;
  final Duration scanDuration;
  final Duration staleAfter;
  final Duration connectionTimeout;
  final Duration operationLimit;
  final DateTime Function() _now;
  final Map<String, BleDevice> devices = {};
  final Map<String, DateTime> lastSeen = {};
  final Map<String, int> discoveryOrder = {};
  final Set<String> currentRoundIds = {};
  final Map<String, BleDevice> systemDevices = {};
  List<SystemAudioDevice> systemAudioDevices = [];
  bool refreshingConnections = false;
  String? connectionQueryError;
  final Map<String, Uint8List> values = {};
  final Set<String> subscriptions = {};
  final Set<String> pendingCharacteristics = {};
  final List<String> logs = [];
  AvailabilityState availabilityState = AvailabilityState.unknown;
  bool permissionGranted = false;
  BleScanPhase scanPhase = BleScanPhase.idle;
  BleLinkPhase linkPhase = BleLinkPhase.idle;
  String? connectedId;
  BleDevice? connectionTarget;
  String? error;
  String scanSummary = '尚未开始扫描';
  List<BleService> services = [];
  StreamSubscription<BleDevice>? _scanSubscription;
  StreamSubscription<AvailabilityState>? _availabilitySubscription;
  StreamSubscription<bool>? _connectionSubscription;
  final Map<String, StreamSubscription<Uint8List>> _valueSubscriptions = {};
  Timer? _scanTimer;
  Timer? _heartbeat;
  Timer? _scanUpdateTimer;
  DateTime? _scanDeadline;
  bool _closed = false;
  bool _active = true;
  bool _radioBusy = false;
  bool _scanStartInFlight = false;
  bool _nativeConnectionRequested = false;
  int _generation = 0;
  int _scanGeneration = 0;
  int _connectionQueryGeneration = 0;

  bool get scanning =>
      scanPhase == BleScanPhase.running ||
      scanPhase == BleScanPhase.stopping ||
      scanPhase == BleScanPhase.unconfirmed;
  bool get busy =>
      _radioBusy ||
      _scanStartInFlight ||
      scanPhase == BleScanPhase.stopping ||
      switch (linkPhase) {
        BleLinkPhase.connecting ||
        BleLinkPhase.discovering ||
        BleLinkPhase.cancelling ||
        BleLinkPhase.disconnecting => true,
        _ => false,
      };
  bool get canConnect =>
      !_closed &&
      !busy &&
      connectedId == null &&
      availabilityState != AvailabilityState.poweredOff &&
      availabilityState != AvailabilityState.unsupported &&
      availabilityState != AvailabilityState.resetting &&
      availabilityState != AvailabilityState.unauthorized &&
      linkPhase != BleLinkPhase.disconnectUnconfirmed &&
      scanPhase != BleScanPhase.unconfirmed;
  bool get canStartScan =>
      !_closed &&
      !busy &&
      !scanning &&
      _active &&
      connectedId == null &&
      linkPhase != BleLinkPhase.disconnectUnconfirmed &&
      availabilityState != AvailabilityState.poweredOff &&
      availabilityState != AvailabilityState.unsupported &&
      availabilityState != AvailabilityState.resetting;
  bool get canCancelConnection =>
      linkPhase == BleLinkPhase.connecting ||
      linkPhase == BleLinkPhase.discovering;
  bool get gattReady => linkPhase == BleLinkPhase.ready && connectedId != null;
  bool get canRetryConnection =>
      canConnect &&
      linkPhase == BleLinkPhase.failed &&
      connectionTarget != null;
  int get scanSecondsRemaining {
    final remaining = _scanDeadline?.difference(_now()).inMilliseconds ?? 0;
    return remaining <= 0 ? 0 : (remaining / 1000).ceil();
  }

  Duration? ageOf(String id) {
    final seen = lastSeen[id];
    return seen == null ? null : _now().difference(seen);
  }

  BleAdvertisementState advertisementState(String id) {
    final age = ageOf(id);
    if (age == null || age >= staleAfter) return BleAdvertisementState.expired;
    return currentRoundIds.contains(id)
        ? BleAdvertisementState.currentRound
        : BleAdvertisementState.previousRound;
  }

  void _notify() {
    if (!_closed) notifyListeners();
  }

  void _log(String message) {
    logs.insert(
      0,
      '${_now().toLocal().toIso8601String().substring(11, 19)} $message',
    );
    if (logs.length > 30) logs.removeLast();
    _notify();
  }

  void _startHeartbeat() {
    if (_closed || !_active || _heartbeat != null) return;
    _heartbeat = Timer.periodic(const Duration(seconds: 1), (_) => _notify());
  }

  void setActive(bool active) {
    _active = active;
    if (!active) {
      _heartbeat?.cancel();
      _heartbeat = null;
      if (scanPhase != BleScanPhase.idle) stopScan(reason: '页面离开');
    } else if (lastSeen.isNotEmpty || scanning) {
      _startHeartbeat();
      _notify();
    }
  }

  void _applyAvailability(AvailabilityState state) {
    availabilityState = state;
    if (state == AvailabilityState.poweredOff ||
        state == AvailabilityState.unsupported) {
      ++_connectionQueryGeneration;
      ++_scanGeneration;
      ++_generation;
      _scanTimer?.cancel();
      _scanDeadline = null;
      scanPhase = BleScanPhase.idle;
      scanSummary = '蓝牙不可用，扫描已结束';
      systemDevices.clear();
      systemAudioDevices = [];
      error = null;
      _clearConnection();
      linkPhase = BleLinkPhase.idle;
    }
  }

  Future<void> refreshStatus() async {
    try {
      final state = await client.availability().timeout(operationLimit);
      final granted = await client.hasPermissions().timeout(operationLimit);
      if (_closed) return;
      _applyAvailability(state);
      permissionGranted = granted;
      _notify();
      if (state == AvailabilityState.poweredOn && granted) {
        await loadSystemDevices(requestPermission: false);
      } else {
        ++_connectionQueryGeneration;
        systemDevices.clear();
        systemAudioDevices = [];
        _notify();
      }
    } catch (e) {
      if (_closed) return;
      error = '读取蓝牙状态失败：$e';
      _notify();
    }
  }

  Future<void> requestEnableBluetooth() async {
    if (_closed || busy || availabilityState == AvailabilityState.poweredOn) {
      return;
    }
    _radioBusy = true;
    error = null;
    _notify();
    try {
      await client.requestPermissions().timeout(operationLimit);
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
      _radioBusy = false;
      _notify();
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

  Future<void> startScan({Duration? duration}) async {
    if (!canStartScan) return;
    final limit = duration ?? scanDuration;
    if (limit <= Duration.zero || limit > const Duration(seconds: 60)) {
      error = '扫描时长应大于 0 且不超过 60 秒';
      _notify();
      return;
    }
    final generation = ++_scanGeneration;
    _scanStartInFlight = true;
    scanPhase = BleScanPhase.starting;
    currentRoundIds.clear();
    error = null;
    scanSummary = '正在检查权限并启动扫描';
    _notify();
    var nativeRequested = false;
    try {
      await client.requestPermissions().timeout(operationLimit);
      final granted = await client.hasPermissions().timeout(operationLimit);
      if (_closed || generation != _scanGeneration || !_active) return;
      permissionGranted = granted;
      if (!granted) throw StateError('蓝牙权限未授予');
      final state = await client.availability().timeout(operationLimit);
      if (_closed || generation != _scanGeneration || !_active) return;
      _applyAvailability(state);
      if (state != AvailabilityState.poweredOn) throw StateError('请先开启蓝牙');
      nativeRequested = true;
      final nativeStart = client.startScan();
      unawaited(
        nativeStart.then<void>((_) {
          if (_closed ||
              generation != _scanGeneration ||
              scanPhase == BleScanPhase.idle ||
              scanPhase == BleScanPhase.unconfirmed) {
            unawaited(_releaseLateScan(generation));
          }
        }, onError: (Object error, StackTrace stack) {}),
      );
      await nativeStart.timeout(operationLimit);
      if (_closed || generation != _scanGeneration || !_active) {
        return;
      }
      scanPhase = BleScanPhase.running;
      _scanDeadline = _now().add(limit);
      scanSummary = '扫描中';
      _startHeartbeat();
      _log('开始扫描，${limit.inSeconds} 秒后自动停止；保留历史结果');
      _scanTimer = Timer(limit, () => stopScan(reason: '限时结束'));
    } catch (e) {
      if (_closed || generation != _scanGeneration) return;
      scanPhase = BleScanPhase.idle;
      scanSummary = '扫描启动失败';
      error = '扫描失败或权限被拒绝：$e';
      if (nativeRequested) {
        try {
          await client.stopScan().timeout(operationLimit);
          if (await client.isScanning().timeout(operationLimit)) {
            throw StateError('适配器仍在扫描');
          }
        } catch (cleanupError) {
          if (_closed || generation != _scanGeneration) return;
          scanPhase = BleScanPhase.unconfirmed;
          scanSummary = '启动失败后的停止尚未确认';
          error = '$error；停止未确认：$cleanupError';
        }
      }
      if (_closed || generation != _scanGeneration) return;
      _log(error!);
    } finally {
      _scanStartInFlight = false;
      _notify();
    }
  }

  Future<void> _releaseLateScan(int generation) async {
    // A newer scan attempt owns the adapter now.
    if (!_closed &&
        generation != _scanGeneration &&
        (scanPhase == BleScanPhase.running ||
            scanPhase == BleScanPhase.starting)) {
      return;
    }
    final cleanupGeneration = _scanGeneration;
    try {
      await client.stopScan().timeout(operationLimit);
      if (await client.isScanning().timeout(operationLimit)) {
        throw StateError('适配器仍在扫描');
      }
    } catch (e) {
      if (_closed || cleanupGeneration != _scanGeneration) return;
      scanPhase = BleScanPhase.unconfirmed;
      scanSummary = '迟到扫描的停止尚未确认';
      error = '停止扫描未确认：$e';
      _log(error!);
    }
  }

  Future<void> stopScan({String reason = '手动停止'}) async {
    if (scanPhase == BleScanPhase.idle || scanPhase == BleScanPhase.stopping) {
      return;
    }
    final generation = ++_scanGeneration;
    _scanTimer?.cancel();
    _scanTimer = null;
    _scanDeadline = null;
    scanPhase = BleScanPhase.stopping;
    scanSummary = '正在确认扫描停止';
    _notify();
    try {
      await client.stopScan().timeout(operationLimit);
      if (await client.isScanning().timeout(operationLimit)) {
        throw StateError('适配器仍在扫描');
      }
      if (_closed || generation != _scanGeneration) return;
      scanPhase = BleScanPhase.idle;
      if (error?.startsWith('停止扫描未确认') ?? false) error = null;
      scanSummary = '$reason · 本轮 ${currentRoundIds.length} 台';
      _log(
        currentRoundIds.isEmpty
            ? '$reason：未发现 BLE 外设'
            : '$reason：本轮 ${currentRoundIds.length} 台设备',
      );
    } catch (e) {
      if (_closed || generation != _scanGeneration) return;
      scanPhase = BleScanPhase.unconfirmed;
      scanSummary = '停止尚未确认，可再次停止';
      error = '停止扫描未确认：$e';
      _log(error!);
    }
  }

  void clearScanHistory() {
    if (scanning || _scanStartInFlight) return;
    devices.removeWhere((id, _) => id != connectedId);
    lastSeen.clear();
    discoveryOrder.clear();
    currentRoundIds.clear();
    _notify();
  }

  Future<void> loadSystemDevices({bool requestPermission = true}) async {
    if (_closed || refreshingConnections) return;
    refreshingConnections = true;
    final generation = ++_connectionQueryGeneration;
    connectionQueryError = null;
    _notify();
    try {
      if (requestPermission) {
        await client.requestPermissions().timeout(operationLimit);
      }
      final granted = await client.hasPermissions().timeout(operationLimit);
      if (_closed) return;
      permissionGranted = granted;
      if (!granted) throw StateError('请先授予蓝牙连接权限');
      final state = await client.availability().timeout(operationLimit);
      if (_closed || generation != _connectionQueryGeneration) return;
      _applyAvailability(state);
      if (state != AvailabilityState.poweredOn) return;
      final found = await client.getSystemDevices().timeout(operationLimit);
      final audio = await client.getConnectedAudioDevices().timeout(
        operationTimeout,
      );
      if (_closed || generation != _connectionQueryGeneration) return;
      systemDevices
        ..clear()
        ..addEntries(found.map((device) => MapEntry(device.deviceId, device)));
      systemAudioDevices = audio;
      _log('系统已连接的 BLE 设备：${found.length} 台');
    } catch (e) {
      if (_closed || generation != _connectionQueryGeneration) return;
      connectionQueryError = '查询系统连接失败：$e';
      _log(connectionQueryError!);
    } finally {
      refreshingConnections = false;
      _notify();
    }
  }

  bool _currentLink(int generation) => !_closed && generation == _generation;
  Future<void> _disconnectVerified(String id) async {
    await client.disconnect(id).timeout(operationLimit);
    final state = await client.connectionState(id).timeout(operationLimit);
    if (state != BleConnectionState.disconnected) {
      throw StateError('设备连接状态仍为 ${state.name}');
    }
  }

  Future<void> _releaseLateLink(String id) async {
    // A newer attempt to the same device owns the native connection now.
    if (!_closed &&
        (connectedId == id ||
            connectionTarget?.deviceId == id &&
                (canCancelConnection || linkPhase == BleLinkPhase.ready))) {
      return;
    }
    try {
      await _disconnectVerified(id);
    } catch (e) {
      if (_closed) return;
      if (connectedId != null && connectedId != id ||
          connectionTarget?.deviceId != id && canCancelConnection) {
        _log('旧设备 $id 的释放未确认：$e');
        return;
      }
      connectionTarget = devices[id] ?? connectionTarget;
      linkPhase = BleLinkPhase.disconnectUnconfirmed;
      error = '迟到连接的释放未确认：$e';
      _log(error!);
    }
  }

  Future<void> connect(BleDevice device) async {
    if (!canConnect) return;
    connectionTarget = device;
    _nativeConnectionRequested = false;
    final generation = ++_generation;
    linkPhase = BleLinkPhase.connecting;
    error = null;
    _notify();
    if (scanning) await stopScan(reason: '准备连接');
    if (!_currentLink(generation)) return;
    if (scanning) {
      linkPhase = BleLinkPhase.failed;
      error = '扫描停止尚未确认，暂不连接。请先重试停止扫描。';
      _log(error!);
      return;
    }
    final id = device.deviceId;
    _connectionSubscription = client.connectionChanges(id).listen((connected) {
      if (!connected && connectedId == id) {
        final ending =
            linkPhase == BleLinkPhase.cancelling ||
            linkPhase == BleLinkPhase.disconnecting;
        if (!ending) ++_generation;
        _clearConnection();
        if (!ending) {
          _nativeConnectionRequested = false;
          linkPhase = BleLinkPhase.failed;
          error = '设备意外断开，可重新连接。';
          _log(error!);
        }
      }
    });
    var nativeRequested = false;
    try {
      var granted = await client.hasPermissions().timeout(operationLimit);
      if (!_currentLink(generation)) return;
      if (!granted) {
        await client.requestPermissions().timeout(operationLimit);
        if (!_currentLink(generation)) return;
        granted = await client.hasPermissions().timeout(operationLimit);
      }
      if (!_currentLink(generation)) return;
      permissionGranted = granted;
      if (!granted) throw StateError('蓝牙连接权限未授予');
      final state = await client.availability().timeout(operationLimit);
      if (!_currentLink(generation)) return;
      availabilityState = state;
      if (state != AvailabilityState.poweredOn) throw StateError('请先开启蓝牙并授予权限');
      _log('正在连接 ${device.rawName?.isNotEmpty == true ? device.rawName : id}');
      nativeRequested = true;
      _nativeConnectionRequested = true;
      final nativeConnect = client.connect(id);
      unawaited(
        nativeConnect.then<void>((_) {
          if (!_currentLink(generation) ||
              linkPhase == BleLinkPhase.failed ||
              linkPhase == BleLinkPhase.idle ||
              linkPhase == BleLinkPhase.disconnectUnconfirmed) {
            unawaited(_releaseLateLink(id));
          }
        }, onError: (Object error, StackTrace stack) {}),
      );
      await nativeConnect.timeout(connectionTimeout);
      if (!_currentLink(generation)) {
        return;
      }
      final nativeState = await client
          .connectionState(id)
          .timeout(operationLimit);
      if (!_currentLink(generation)) return;
      if (nativeState != BleConnectionState.connected) {
        throw StateError('连接完成后链路未保持：${nativeState.name}');
      }
      connectedId = id;
      devices[id] = device;
      linkPhase = BleLinkPhase.discovering;
      _log('已建立链路，正在发现服务');
      final discovered = await client.discover(id).timeout(operationLimit);
      if (!_currentLink(generation)) return;
      services = discovered;
      linkPhase = BleLinkPhase.ready;
      _log('发现 ${services.length} 项服务，可操作 GATT');
    } catch (e) {
      if (!_currentLink(generation)) return;
      final phase = linkPhase == BleLinkPhase.discovering ? '服务发现' : '连接';
      error = e is TimeoutException ? '$phase 超时，可重新连接。' : '$phase 失败：$e';
      _log(error!);
      if (!nativeRequested) {
        _clearConnection();
        _nativeConnectionRequested = false;
        linkPhase = BleLinkPhase.failed;
        _notify();
        return;
      }
      linkPhase = BleLinkPhase.disconnecting;
      _notify();
      try {
        await _disconnectVerified(id);
        if (!_currentLink(generation)) return;
        _clearConnection();
        linkPhase = BleLinkPhase.failed;
      } catch (cleanupError) {
        if (!_currentLink(generation)) return;
        linkPhase = BleLinkPhase.disconnectUnconfirmed;
        error = '$error；释放连接未确认：$cleanupError';
      }
      _notify();
    }
  }

  Future<void> retryConnection() async {
    final target = connectionTarget;
    if (target != null && canRetryConnection) await connect(target);
  }

  Future<void> cancelConnection() async {
    if (!canCancelConnection) return;
    await _endConnection(cancel: true);
  }

  Future<void> disconnect() async {
    if (_closed ||
        linkPhase == BleLinkPhase.cancelling ||
        linkPhase == BleLinkPhase.disconnecting) {
      return;
    }
    if (connectedId == null &&
        linkPhase != BleLinkPhase.disconnectUnconfirmed) {
      return;
    }
    await _endConnection(cancel: false);
  }

  Future<void> _endConnection({required bool cancel}) async {
    final id = connectedId ?? connectionTarget?.deviceId;
    if (id == null) return;
    final generation = ++_generation;
    if (!_nativeConnectionRequested &&
        connectedId == null &&
        linkPhase != BleLinkPhase.disconnectUnconfirmed) {
      _clearConnection();
      linkPhase = BleLinkPhase.idle;
      error = null;
      _log('连接准备已取消，未发起原生连接');
      return;
    }
    linkPhase = cancel ? BleLinkPhase.cancelling : BleLinkPhase.disconnecting;
    _notify();
    try {
      await _disconnectVerified(id);
      if (!_currentLink(generation)) return;
      _clearConnection();
      _nativeConnectionRequested = false;
      linkPhase = BleLinkPhase.idle;
      error = null;
      _log(cancel ? '连接已取消并确认释放' : '主动断开，已确认释放');
    } catch (e) {
      if (!_currentLink(generation)) return;
      linkPhase = BleLinkPhase.disconnectUnconfirmed;
      error = '断开未确认：$e；请重试确认断开。';
      _log(error!);
    }
  }

  Future<void> read(
    BleService service,
    BleCharacteristic characteristic,
  ) async {
    final id = connectedId;
    if (!gattReady ||
        id == null ||
        !characteristic.properties.contains(CharacteristicProperty.read)) {
      return;
    }
    final generation = _generation;
    final key = '${service.uuid}/${characteristic.uuid}';
    if (!pendingCharacteristics.add(key)) return;
    _notify();
    try {
      final value = await client
          .read(id, service.uuid, characteristic.uuid)
          .timeout(operationLimit);
      if (!_currentLink(generation) || connectedId != id || !gattReady) return;
      values[key] = value;
      _log('读取 ${characteristic.uuid}：${hex(value)}');
    } catch (e) {
      if (!_currentLink(generation)) return;
      error = '读取失败：$e';
      _log(error!);
    } finally {
      if (_currentLink(generation)) {
        pendingCharacteristics.remove(key);
        _notify();
      }
    }
  }

  Future<void> toggleSubscription(
    BleService service,
    BleCharacteristic characteristic,
  ) async {
    final id = connectedId;
    if (!gattReady || id == null) return;
    final key = '${service.uuid}/${characteristic.uuid}';
    final generation = _generation;
    final indicate = characteristic.properties.contains(
      CharacteristicProperty.indicate,
    );
    if (!indicate &&
        !characteristic.properties.contains(CharacteristicProperty.notify)) {
      return;
    }
    if (!pendingCharacteristics.add(key)) return;
    _notify();
    try {
      if (subscriptions.contains(key)) {
        await client
            .unsubscribe(id, service.uuid, characteristic.uuid)
            .timeout(operationLimit);
        if (!_currentLink(generation)) return;
        await _valueSubscriptions.remove(key)?.cancel();
        subscriptions.remove(key);
        _log('停止订阅 ${characteristic.uuid}');
      } else {
        final listener = client.values(id, characteristic.uuid).listen((data) {
          if (!_currentLink(generation) || connectedId != id) return;
          values[key] = data;
          _log('收到 ${characteristic.uuid}：${hex(data)}');
        });
        _valueSubscriptions[key] = listener;
        await client
            .subscribe(
              id,
              service.uuid,
              characteristic.uuid,
              indicate: indicate,
            )
            .timeout(operationLimit);
        if (!_currentLink(generation)) {
          await listener.cancel();
          return;
        }
        subscriptions.add(key);
        _log('订阅 ${characteristic.uuid}');
      }
    } catch (e) {
      if (!_currentLink(generation)) return;
      await _valueSubscriptions.remove(key)?.cancel();
      error = '订阅操作失败：$e';
      _log(error!);
    } finally {
      if (_currentLink(generation)) {
        pendingCharacteristics.remove(key);
        _notify();
      }
    }
  }

  void _clearConnection() {
    _connectionSubscription?.cancel();
    _connectionSubscription = null;
    for (final listener in _valueSubscriptions.values) {
      listener.cancel();
    }
    _valueSubscriptions.clear();
    subscriptions.clear();
    pendingCharacteristics.clear();
    values.clear();
    services = [];
    connectedId = null;
    _notify();
  }

  static String hex(Uint8List data) =>
      data.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join(' ');

  Future<void> close() async {
    if (_closed) return;
    final linkId =
        connectedId ??
        (_nativeConnectionRequested &&
                linkPhase != BleLinkPhase.idle &&
                linkPhase != BleLinkPhase.failed
            ? connectionTarget?.deviceId
            : null);
    final stopNeeded = scanPhase != BleScanPhase.idle;
    _closed = true;
    ++_generation;
    ++_scanGeneration;
    _scanTimer?.cancel();
    _heartbeat?.cancel();
    _scanUpdateTimer?.cancel();
    await _scanSubscription?.cancel();
    await _availabilitySubscription?.cancel();
    _clearConnection();
    // Dispose promptly; native cleanup has bounded waits and cannot update UI.
    super.dispose();
    if (stopNeeded) {
      try {
        await client.stopScan().timeout(operationLimit);
      } catch (_) {
        /* best effort during disposal */
      }
    }
    if (linkId != null) {
      try {
        await _disconnectVerified(linkId);
      } catch (_) {
        /* best effort during disposal */
      }
    }
  }
}
