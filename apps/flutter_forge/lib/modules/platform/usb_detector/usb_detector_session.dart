import 'dart:async';
import 'dart:developer' as developer;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:usb_detector_bridge/usb_detector_bridge.dart';

/// Device-list state over [UsbDetectorBridge]. Periodic scanning is a session
/// policy here; the bridge itself stays request/response.
class UsbDetectorSession extends ChangeNotifier {
  UsbDetectorSession({
    UsbDetectorBridge? bridge,
    this.scanInterval = const Duration(seconds: 3),
  }) : _bridge = bridge ?? UsbDetectorBridge();

  final UsbDetectorBridge _bridge;
  final Duration scanInterval;

  UsbDetectionCapabilities? capabilities;
  UsbDetectionOutcome<List<UsbDeviceInfo>>? listResult;
  String? systemInfo;

  bool get capabilityResolved => capabilities != null;
  bool get supported => capabilities?.isSupported ?? false;
  bool get scanning => _scanTimer != null;
  List<UsbDeviceInfo> get devices => listResult?.value ?? const [];

  int get errorCount =>
      devices.where((device) => device.status == UsbDeviceStatus.error).length;

  UsbReason? get reason => listResult?.reason;

  String get statusText {
    if (!capabilityResolved) return '正在初始化 USB 服务…';
    if (!supported) {
      return '当前平台不支持 USB 设备枚举（platform_unsupported）';
    }
    final outcome = listResult;
    if (outcome == null) return '正在初始化 USB 服务…';
    return switch (outcome.status) {
      UsbDetectionStatus.pending => '正在初始化 USB 服务…',
      UsbDetectionStatus.available =>
        devices.isEmpty
            ? 'USB功能正常，但未检测到设备'
            : errorCount > 0
            ? 'USB功能部分异常：${devices.length - errorCount} 个设备正常，$errorCount 个设备异常'
            : 'USB功能正常：检测到 ${devices.length} 个设备',
      UsbDetectionStatus.unsupported =>
        '当前平台不支持 USB 设备枚举（${reason?.code ?? 'platform_unsupported'}）',
      UsbDetectionStatus.unavailable => 'USB 服务不可用：${reason?.message ?? ''}',
      UsbDetectionStatus.invalidData => '设备数据解析失败：${reason?.message ?? ''}',
      UsbDetectionStatus.failed => 'USB 功能异常：${reason?.message ?? ''}',
    };
  }

  Timer? _scanTimer;
  bool _disposed = false;

  Future<void> initialize() async {
    capabilities = await _bridge.queryCapabilities();
    if (supported) {
      await refresh();
      startPeriodicScan();
    }
    _notify();
  }

  Future<void> refresh() async {
    listResult = await _bridge.listDevices();
    _notify();
  }

  /// The timer tick body, visible for tests; the timer itself stays private.
  @visibleForTesting
  Future<void> scanTick() => refresh();

  void startPeriodicScan() {
    stopPeriodicScan();
    if (!supported) return;
    _scanTimer = Timer.periodic(scanInterval, (_) => unawaited(scanTick()));
    _notify();
  }

  void stopPeriodicScan() {
    _scanTimer?.cancel();
    if (_scanTimer != null) {
      _scanTimer = null;
      _notify();
    }
  }

  Future<void> loadSystemInfo() async {
    try {
      final info = await DeviceInfoPlugin().deviceInfo;
      final data = info.data;
      final model = data['model'] ?? data['product'] ?? data['name'] ?? '';
      final version = data['version'] ?? data['version.release'] ?? '';
      systemInfo = '系统：$model $version'.trim();
    } catch (e) {
      developer.log(
        'Error getting system info: $e',
        name: 'UsbDetectorSession',
      );
      systemInfo = null;
    }
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    stopPeriodicScan();
    super.dispose();
  }
}
