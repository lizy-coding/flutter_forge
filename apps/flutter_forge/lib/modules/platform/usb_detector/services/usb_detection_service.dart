import 'dart:async';
import 'dart:developer' as developer;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';

import '../models/usb_device_info.dart';

class UsbDetectionService {
  static final UsbDetectionService _instance = UsbDetectionService._internal();
  factory UsbDetectionService() => _instance;
  UsbDetectionService._internal();

  static const MethodChannel _channel = MethodChannel('usb_detector/usb');

  bool _isInitialized = false;
  List<UsbDeviceInfo> _connectedDevices = [];
  Timer? _periodicTimer;

  final StreamController<List<UsbDeviceInfo>> _deviceStreamController =
      StreamController<List<UsbDeviceInfo>>.broadcast();

  final StreamController<String> _statusStreamController =
      StreamController<String>.broadcast();

  Stream<List<UsbDeviceInfo>> get deviceStream =>
      _deviceStreamController.stream;
  Stream<String> get statusStream => _statusStreamController.stream;

  List<UsbDeviceInfo> get connectedDevices =>
      List.unmodifiable(_connectedDevices);

  Future<bool> initialize() async {
    try {
      _statusStreamController.add('正在初始化USB服务...');

      _isInitialized = true;

      if (_isInitialized) {
        _statusStreamController.add('USB服务初始化成功');
        await _refreshDeviceList();
        _startPeriodicScanning();
      } else {
        _statusStreamController.add('USB服务初始化失败');
      }

      return _isInitialized;
    } catch (e) {
      developer.log(
        'USB initialization failed: $e',
        name: 'UsbDetectionService',
      );
      _statusStreamController.add('初始化错误: $e');
      return false;
    }
  }

  Future<void> _refreshDeviceList() async {
    if (!_isInitialized) return;

    try {
      _statusStreamController.add('正在扫描USB设备...');

      final rawDevices = await _channel.invokeMethod<List<dynamic>>(
        'listDevices',
      );
      List<UsbDeviceInfo> deviceInfoList = [];

      for (final rawDevice in rawDevices ?? const <dynamic>[]) {
        Map<String, dynamic> device = const {};
        try {
          device = Map<String, dynamic>.from(rawDevice as Map);
          UsbDeviceInfo deviceInfo = UsbDeviceInfo(
            vendorId: (device['vendorId'] as num?)?.toInt() ?? 0,
            productId: (device['productId'] as num?)?.toInt() ?? 0,
            manufacturer: device['manufacturer'] as String?,
            product: device['product'] as String?,
            serialNumber: device['serialNumber'] as String?,
            status: UsbDeviceStatus.connected,
          );

          deviceInfoList.add(deviceInfo);
        } catch (e) {
          developer.log(
            'Error getting device info: $e',
            name: 'UsbDetectionService',
          );

          UsbDeviceInfo deviceInfo = UsbDeviceInfo(
            vendorId: (device['vendorId'] as num?)?.toInt() ?? 0,
            productId: (device['productId'] as num?)?.toInt() ?? 0,
            status: UsbDeviceStatus.error,
          );
          deviceInfoList.add(deviceInfo);
        }
      }

      _connectedDevices = deviceInfoList;
      _deviceStreamController.add(_connectedDevices);

      _statusStreamController.add('发现 ${_connectedDevices.length} 个USB设备');
    } catch (e) {
      developer.log(
        'Error refreshing device list: $e',
        name: 'UsbDetectionService',
      );
      _statusStreamController.add('扫描错误: $e');
    }
  }

  void _startPeriodicScanning() {
    _periodicTimer?.cancel();
    _periodicTimer = Timer.periodic(
      const Duration(seconds: 3),
      (timer) => _refreshDeviceList(),
    );
  }

  Future<void> refreshDevices() async {
    await _refreshDeviceList();
  }

  bool get isUsbDriverWorking {
    return _isInitialized && _connectedDevices.isNotEmpty;
  }

  String get systemStatus {
    if (!_isInitialized) {
      return 'USB服务未初始化';
    }

    if (_connectedDevices.isEmpty) {
      return 'USB功能正常，但未检测到设备';
    }

    int connectedCount = _connectedDevices
        .where((device) => device.status == UsbDeviceStatus.connected)
        .length;

    int errorCount = _connectedDevices
        .where((device) => device.status == UsbDeviceStatus.error)
        .length;

    if (errorCount > 0) {
      return 'USB功能部分异常：$connectedCount 个设备正常，$errorCount 个设备异常';
    }

    return 'USB功能正常：检测到 $connectedCount 个设备';
  }

  Future<String> getSystemInfo() async {
    try {
      final info = await DeviceInfoPlugin().deviceInfo;
      final data = info.data;
      final model = data['model'] ?? data['product'] ?? data['name'] ?? '';
      final version = data['version'] ?? data['version.release'] ?? '';
      return '系统：$model $version'.trim();
    } catch (e) {
      developer.log(
        'Error getting system info: $e',
        name: 'UsbDetectionService',
      );
    }
    return '系统信息获取失败';
  }

  void dispose() {
    _periodicTimer?.cancel();
    _deviceStreamController.close();
    _statusStreamController.close();

    // USB Serial 不需要显式退出
  }
}
