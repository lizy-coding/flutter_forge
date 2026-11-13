/// Channel contract shared by the Dart adapter, the Android plugin and the
/// macOS plugin. Keep every string in sync with all native adapters.
abstract final class NotificationChannelContract {
  static const String methodChannel = 'forge_notification/notifications';

  static const String queryCapabilities = 'queryCapabilities';
  static const String queryPermissionState = 'queryPermissionState';
  static const String requestPermission = 'requestPermission';
  static const String post = 'post';
  static const String cancel = 'cancel';

  static const String argTitle = 'title';
  static const String argSubtitle = 'subtitle';
  static const String argBody = 'body';
  static const String argNotificationId = 'notificationId';

  static const String keyPostingSupported = 'postingSupported';
  static const String keyPermissionQuerySupported = 'permissionQuerySupported';
  static const String keyPermissionRequestSupported =
      'permissionRequestSupported';
  static const String keyCancelSupported = 'cancelSupported';

  static const String keyStatus = 'status';
  static const String keyReason = 'reason';
  static const String keyMessage = 'message';
  static const String keyState = 'state';
  static const String keyNotificationId = 'notificationId';
  static const String keyCancelled = 'cancelled';
}
