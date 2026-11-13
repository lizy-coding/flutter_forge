import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'models/usb_device_info.dart';
import 'usb_detector_method_channel.dart';
import 'usb_detector_result.dart';

abstract class UsbDetectorPlatform extends PlatformInterface {
  /// Constructs a UsbDetectorPlatform.
  UsbDetectorPlatform() : super(token: _token);

  static final Object _token = Object();

  static UsbDetectorPlatform _instance = MethodChannelUsbDetector();

  /// The default instance of [UsbDetectorPlatform] to use.
  ///
  /// Defaults to [MethodChannelUsbDetector].
  static UsbDetectorPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [UsbDetectorPlatform] when
  /// they register themselves.
  static set instance(UsbDetectorPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Never throws: an adapter without enumeration reports no capabilities.
  Future<UsbDetectionCapabilities> queryCapabilities() async =>
      const UsbDetectionCapabilities.none();

  Future<UsbDetectionOutcome<List<UsbDeviceInfo>>> listDevices() async =>
      UsbDetectionOutcome.state(
        UsbDetectionStatus.unsupported,
        'platform_unsupported',
        '当前平台未提供 USB 设备枚举适配',
      );
}
