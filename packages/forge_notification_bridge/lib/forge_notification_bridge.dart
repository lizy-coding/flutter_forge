import 'forge_notification_platform_interface.dart';
import 'forge_notification_result.dart';

export 'forge_notification_method_channel.dart';
export 'forge_notification_platform_interface.dart';
export 'forge_notification_result.dart';
export 'src/notification_channel_contract.dart';

/// Entry point of the bridge: consumers talk to [ForgeNotificationPlatform]
/// and typed results only, never to the method channel directly.
class ForgeNotifications {
  ForgeNotifications({ForgeNotificationPlatform? platform})
    : _platform = platform ?? ForgeNotificationPlatform.instance;

  final ForgeNotificationPlatform _platform;

  Future<NotificationCapabilities> queryCapabilities() =>
      _platform.queryCapabilities();

  /// Device-level authorization fact; complements the static platform matrix.
  Future<ForgeNotificationOutcome<NotificationPermissionState>>
  queryPermissionState() => _platform.queryPermissionState();

  Future<ForgeNotificationOutcome<NotificationPermissionState>>
  requestPermission() => _platform.requestPermission();

  Future<ForgeNotificationOutcome<PostedNotification>> post(
    NotificationContent content,
  ) => _platform.post(content);

  Future<ForgeNotificationOutcome<bool>> cancel(String id) =>
      _platform.cancel(id);
}
