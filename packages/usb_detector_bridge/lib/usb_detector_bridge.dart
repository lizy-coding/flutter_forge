import 'models/usb_device_info.dart';
import 'usb_detector_platform_interface.dart';
import 'usb_detector_result.dart';

export 'models/usb_device_info.dart';
export 'usb_detector_method_channel.dart';
export 'usb_detector_platform_interface.dart';
export 'usb_detector_result.dart';

/// Consumption seam for the usb_detector learning module: capability probing
/// and typed enumeration outcomes, with the platform adapter behind
/// [UsbDetectorPlatform].
class UsbDetectorBridge {
  UsbDetectorBridge({UsbDetectorPlatform? platform})
    : _platform = platform ?? UsbDetectorPlatform.instance;

  final UsbDetectorPlatform _platform;

  Future<UsbDetectionCapabilities> queryCapabilities() =>
      _platform.queryCapabilities();

  Future<UsbDetectionOutcome<List<UsbDeviceInfo>>> listDevices() =>
      _platform.listDevices();
}
