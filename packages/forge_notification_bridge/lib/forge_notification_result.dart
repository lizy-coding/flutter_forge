import 'src/notification_channel_contract.dart';

/// Runtime authorization state of the host application. This is a device
/// fact: the module entry stays open by the static matrix regardless of it.
enum NotificationPermissionState {
  granted,
  denied,
  notDetermined,
  provisional,
  unavailable,
}

/// Terminal state of one notification operation. Only
/// [NotificationStatus.available] carries a value.
enum NotificationStatus {
  available,
  permissionDenied,
  notDetermined,
  unsupported,
  unavailable,
  invalidData,
  failed,
}

/// A stable, machine-readable reason with a human-readable explanation.
class NotificationReason {
  const NotificationReason(this.code, this.message);
  final String code;
  final String message;
}

/// Distinguishes a successful operation from absent support and runtime
/// failures; only [NotificationStatus.available] carries a value.
class ForgeNotificationOutcome<T> {
  const ForgeNotificationOutcome._(this.status, this.value, this.reason);

  factory ForgeNotificationOutcome.available(T value) =>
      ForgeNotificationOutcome._(NotificationStatus.available, value, null);

  factory ForgeNotificationOutcome.state(
    NotificationStatus status,
    String code,
    String message,
  ) {
    if (status == NotificationStatus.available) {
      throw ArgumentError.value(status);
    }
    return ForgeNotificationOutcome._(
      status,
      null,
      NotificationReason(
        code.trim().isEmpty ? 'unspecified_reason' : code,
        message.trim().isEmpty ? 'No additional detail' : message,
      ),
    );
  }

  final NotificationStatus status;
  final T? value;
  final NotificationReason? reason;

  bool get isAvailable => status == NotificationStatus.available;

  factory ForgeNotificationOutcome.fromMap(
    Map<Object?, Object?>? map, {
    required T Function(Map<Object?, Object?> map) parseValue,
  }) {
    if (map == null) {
      return ForgeNotificationOutcome.state(
        NotificationStatus.invalidData,
        'null_response',
        'Native adapter returned no result',
      );
    }
    final rawStatus = map[NotificationChannelContract.keyStatus];
    if (rawStatus is! String || rawStatus.isEmpty) {
      return ForgeNotificationOutcome.state(
        NotificationStatus.invalidData,
        'missing_status',
        'Native adapter result has no status',
      );
    }
    if (rawStatus == NotificationStatus.available.name) {
      try {
        return ForgeNotificationOutcome.available(parseValue(map));
      } on FormatException catch (error) {
        return ForgeNotificationOutcome.state(
          NotificationStatus.invalidData,
          'invalid_value',
          error.message,
        );
      }
    }
    for (final status in NotificationStatus.values) {
      if (status.name == rawStatus) {
        return ForgeNotificationOutcome._(
          status,
          null,
          NotificationReason(
            (map[NotificationChannelContract.keyReason] as String?) ??
                'unspecified_reason',
            (map[NotificationChannelContract.keyMessage] as String?) ??
                'No additional detail',
          ),
        );
      }
    }
    return ForgeNotificationOutcome.state(
      NotificationStatus.invalidData,
      'unknown_status',
      'Unknown notification status: $rawStatus',
    );
  }
}

/// Parses a permission state string from the channel into the typed enum.
NotificationPermissionState parsePermissionState(Object? raw) {
  if (raw is String) {
    for (final state in NotificationPermissionState.values) {
      if (state.name == raw) return state;
    }
  }
  throw const FormatException('Unknown permission state');
}

/// Adapter support surface, separate from the runtime permission state.
class NotificationCapabilities {
  const NotificationCapabilities({
    required this.postingSupported,
    required this.permissionQuerySupported,
    required this.permissionRequestSupported,
    required this.cancelSupported,
  });

  const NotificationCapabilities.none()
    : postingSupported = false,
      permissionQuerySupported = false,
      permissionRequestSupported = false,
      cancelSupported = false;

  factory NotificationCapabilities.fromMap(
    Map<Object?, Object?> map,
  ) => NotificationCapabilities(
    postingSupported:
        map[NotificationChannelContract.keyPostingSupported] == true,
    permissionQuerySupported:
        map[NotificationChannelContract.keyPermissionQuerySupported] == true,
    permissionRequestSupported:
        map[NotificationChannelContract.keyPermissionRequestSupported] == true,
    cancelSupported:
        map[NotificationChannelContract.keyCancelSupported] == true,
  );

  final bool postingSupported;
  final bool permissionQuerySupported;
  final bool permissionRequestSupported;
  final bool cancelSupported;

  bool get isSupported => postingSupported;
}

/// User-visible content of one local notification.
class NotificationContent {
  const NotificationContent({required this.title, required this.body});

  final String title;
  final String body;

  Map<Object?, Object?> toMap() => {
    NotificationChannelContract.argTitle: title,
    NotificationChannelContract.argBody: body,
  };
}

/// A delivered local notification; `id` is the stable identifier used to
/// cancel it later.
class PostedNotification {
  const PostedNotification({required this.id});
  final String id;
}
