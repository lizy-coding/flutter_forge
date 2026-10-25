import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'forge_notification_method_channel.dart';
import 'forge_notification_result.dart';

abstract class ForgeNotificationPlatform extends PlatformInterface {
  ForgeNotificationPlatform() : super(token: _token);

  static final Object _token = Object();

  static ForgeNotificationPlatform _instance = MethodChannelForgeNotification();

  /// The default instance of [ForgeNotificationPlatform] to use.
  ///
  /// Defaults to [MethodChannelForgeNotification].
  static ForgeNotificationPlatform get instance => _instance;

  static set instance(ForgeNotificationPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Never throws: an adapter without posting support reports no capabilities.
  Future<NotificationCapabilities> queryCapabilities() async =>
      const NotificationCapabilities.none();

  Future<ForgeNotificationOutcome<NotificationPermissionState>>
  queryPermissionState() async => ForgeNotificationOutcome.state(
    NotificationStatus.unsupported,
    'platform_unsupported',
    '当前平台未提供通知适配',
  );

  Future<ForgeNotificationOutcome<NotificationPermissionState>>
  requestPermission() async => ForgeNotificationOutcome.state(
    NotificationStatus.unsupported,
    'platform_unsupported',
    '当前平台未提供通知适配',
  );

  Future<ForgeNotificationOutcome<PostedNotification>> post(
    NotificationContent content,
  ) async => ForgeNotificationOutcome.state(
    NotificationStatus.unsupported,
    'platform_unsupported',
    '当前平台未提供通知适配',
  );

  Future<ForgeNotificationOutcome<bool>> cancel(String id) async =>
      ForgeNotificationOutcome.state(
        NotificationStatus.unsupported,
        'platform_unsupported',
        '当前平台未提供通知适配',
      );
}
