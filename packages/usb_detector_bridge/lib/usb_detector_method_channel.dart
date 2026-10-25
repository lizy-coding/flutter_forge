import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'models/usb_device_info.dart';
import 'src/usb_channel_contract.dart';
import 'usb_detector_platform_interface.dart';
import 'usb_detector_result.dart';

/// The Android adapter. Hosts without the native plugin — or without an
/// Android UsbManager — degrade to typed outcomes instead of throwing.
class MethodChannelUsbDetector extends UsbDetectorPlatform {
  @visibleForTesting
  final MethodChannel methodChannel = const MethodChannel(
    UsbChannelContract.methodChannel,
  );

  static bool get _isAndroidHost =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  Future<UsbDetectionCapabilities> queryCapabilities() async {
    if (!_isAndroidHost) return const UsbDetectionCapabilities.none();
    try {
      final result = await methodChannel.invokeMapMethod<String, bool>(
        UsbChannelContract.queryCapabilities,
      );
      if (result == null) return const UsbDetectionCapabilities.none();
      return UsbDetectionCapabilities.fromMap(result);
    } on MissingPluginException {
      return const UsbDetectionCapabilities.none();
    } on PlatformException {
      return const UsbDetectionCapabilities.none();
    }
  }

  @override
  Future<UsbDetectionOutcome<List<UsbDeviceInfo>>> listDevices() async {
    if (!_isAndroidHost) {
      return UsbDetectionOutcome.state(
        UsbDetectionStatus.unsupported,
        'platform_unsupported',
        'USB 设备枚举仅在 Android 宿主提供',
      );
    }
    try {
      final raw = await methodChannel.invokeMethod<List<dynamic>>(
        UsbChannelContract.listDevices,
      );
      if (raw == null) {
        return UsbDetectionOutcome.state(
          UsbDetectionStatus.unavailable,
          'empty_response',
          '宿主适配器未返回设备列表',
        );
      }
      return UsbDetectionOutcome.available(raw.map(_parseDevice).toList());
    } on MissingPluginException {
      return UsbDetectionOutcome.state(
        UsbDetectionStatus.unavailable,
        'missing_plugin',
        '宿主未注册 ${UsbChannelContract.methodChannel} 通道',
      );
    } on TypeError {
      return UsbDetectionOutcome.state(
        UsbDetectionStatus.invalidData,
        'invalid_payload',
        '设备列表负载不是预期的列表结构',
      );
    } on PlatformException catch (error) {
      return UsbDetectionOutcome.state(
        UsbDetectionStatus.failed,
        'channel_error',
        error.message ?? error.code,
      );
    }
  }

  /// A malformed entry degrades to an error-status entry so the remaining
  /// devices stay visible.
  UsbDeviceInfo _parseDevice(dynamic raw) {
    try {
      final device = Map<String, dynamic>.from(raw! as Map);
      return UsbDeviceInfo(
        vendorId: (device['vendorId'] as num?)?.toInt() ?? 0,
        productId: (device['productId'] as num?)?.toInt() ?? 0,
        manufacturer: device['manufacturer']?.toString(),
        product: (device['product'] ?? device['name'])?.toString(),
        serialNumber: device['serialNumber']?.toString(),
        hasPermission: (device['hasPermission'] as bool?),
        platformDeviceId: device['id']?.toString(),
        bus: device['bus']?.toString(),
        port: device['port']?.toString(),
        status: UsbDeviceStatus.connected,
      );
    } on Object {
      return UsbDeviceInfo(
        vendorId: 0,
        productId: 0,
        status: UsbDeviceStatus.error,
      );
    }
  }
}
