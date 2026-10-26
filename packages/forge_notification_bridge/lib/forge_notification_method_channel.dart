import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'forge_notification_platform_interface.dart';
import 'forge_notification_result.dart';
import 'src/notification_channel_contract.dart';

/// Method channel adapter; every failure path resolves to a typed outcome
/// instead of throwing across the channel boundary.
class MethodChannelForgeNotification extends ForgeNotificationPlatform {
  @visibleForTesting
  final methodChannel = const MethodChannel(
    NotificationChannelContract.methodChannel,
  );

  @override
  Future<NotificationCapabilities> queryCapabilities() async {
    try {
      final map = await methodChannel.invokeMethod<Object?>(
        NotificationChannelContract.queryCapabilities,
      );
      if (map is Map<Object?, Object?> &&
          [
            'postingSupported',
            'permissionQuerySupported',
            'permissionRequestSupported',
            'cancelSupported',
          ].every((key) => map[key] == null || map[key] is bool)) {
        return NotificationCapabilities.fromMap(map);
      }
      return const NotificationCapabilities.none();
    } on PlatformException {
      return const NotificationCapabilities.none();
    } on MissingPluginException {
      return const NotificationCapabilities.none();
    }
  }

  Future<ForgeNotificationOutcome<NotificationPermissionState>>
  _permissionOutcome(String method) async {
    try {
      final map = await methodChannel.invokeMethod<Object?>(method);
      return ForgeNotificationOutcome.fromMap(
        map,
        parseValue: (value) =>
            parsePermissionState(value[NotificationChannelContract.keyState]),
      );
    } on PlatformException catch (error) {
      return ForgeNotificationOutcome.state(
        NotificationStatus.unavailable,
        'platform_exception',
        error.message ?? 'Platform channel reported an error',
      );
    } on MissingPluginException {
      return ForgeNotificationOutcome.state(
        NotificationStatus.unsupported,
        'platform_unsupported',
        '当前平台未提供通知适配',
      );
    }
  }

  @override
  Future<ForgeNotificationOutcome<NotificationPermissionState>>
  queryPermissionState() =>
      _permissionOutcome(NotificationChannelContract.queryPermissionState);

  @override
  Future<ForgeNotificationOutcome<NotificationPermissionState>>
  requestPermission() =>
      _permissionOutcome(NotificationChannelContract.requestPermission);

  @override
  Future<ForgeNotificationOutcome<PostedNotification>> post(
    NotificationContent content,
  ) async {
    try {
      final map = await methodChannel.invokeMethod<Object?>(
        NotificationChannelContract.post,
        content.toMap(),
      );
      return ForgeNotificationOutcome.fromMap(
        map,
        parseValue: (value) {
          final id = value[NotificationChannelContract.keyNotificationId];
          if (id is! String || id.trim().isEmpty) {
            throw const FormatException('Native adapter returned no id');
          }
          return PostedNotification(id: id);
        },
      );
    } on PlatformException catch (error) {
      return ForgeNotificationOutcome.state(
        NotificationStatus.unavailable,
        'platform_exception',
        error.message ?? 'Platform channel reported an error',
      );
    } on MissingPluginException {
      return ForgeNotificationOutcome.state(
        NotificationStatus.unsupported,
        'platform_unsupported',
        '当前平台未提供通知适配',
      );
    }
  }

  @override
  Future<ForgeNotificationOutcome<bool>> cancel(String id) async {
    try {
      final map = await methodChannel.invokeMethod<Object?>(
        NotificationChannelContract.cancel,
        {NotificationChannelContract.argNotificationId: id},
      );
      return ForgeNotificationOutcome.fromMap(
        map,
        parseValue: (value) {
          final cancelled = value[NotificationChannelContract.keyCancelled];
          if (cancelled is! bool) {
            throw const FormatException(
              'Expected cancellation acknowledgement',
            );
          }
          return cancelled;
        },
      );
    } on PlatformException catch (error) {
      return ForgeNotificationOutcome.state(
        NotificationStatus.unavailable,
        'platform_exception',
        error.message ?? 'Platform channel reported an error',
      );
    } on MissingPluginException {
      return ForgeNotificationOutcome.state(
        NotificationStatus.unsupported,
        'platform_unsupported',
        '当前平台未提供通知适配',
      );
    }
  }
}
