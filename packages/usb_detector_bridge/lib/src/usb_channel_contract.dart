/// Channel contract shared by the Dart adapter and the Android plugin.
abstract final class UsbChannelContract {
  static const String methodChannel = 'usb_detector/usb';

  static const String listDevices = 'listDevices';
  static const String queryCapabilities = 'queryCapabilities';

  static const String capabilityEnumeration = 'enumerationSupported';
  static const String capabilityPermissionState = 'permissionStateSupported';
}
