import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:forge_notification_bridge/forge_notification_bridge.dart';
import 'package:flutter_forge_app/modules/platform/system_notification/notification_session.dart';

class PendingPlatform extends ForgeNotificationPlatform {
  final pending = Completer<NotificationCapabilities>();
  @override
  Future<NotificationCapabilities> queryCapabilities() => pending.future;
}

class ControlledPlatform extends ForgeNotificationPlatform {
  String stage = '';
  int requests = 0;
  final permission =
      Completer<ForgeNotificationOutcome<NotificationPermissionState>>();
  final posted = Completer<ForgeNotificationOutcome<PostedNotification>>();
  final cancelled = Completer<ForgeNotificationOutcome<bool>>();
  @override
  Future<NotificationCapabilities> queryCapabilities() async =>
      const NotificationCapabilities(
        postingSupported: true,
        permissionQuerySupported: true,
        permissionRequestSupported: true,
        cancelSupported: true,
      );
  @override
  Future<ForgeNotificationOutcome<NotificationPermissionState>>
  queryPermissionState() => stage == 'query'
      ? permission.future
      : Future.value(
          ForgeNotificationOutcome.available(
            NotificationPermissionState.granted,
          ),
        );
  @override
  Future<ForgeNotificationOutcome<NotificationPermissionState>>
  requestPermission() {
    requests++;
    return permission.future;
  }

  @override
  Future<ForgeNotificationOutcome<PostedNotification>> post(
    NotificationContent content,
  ) => posted.future;
  @override
  Future<ForgeNotificationOutcome<bool>> cancel(String id) => cancelled.future;
}

void main() {
  for (final stage in ['query', 'request', 'post', 'cancel']) {
    test(
      'dispose while $stage settles the session future and ignores late updates',
      () async {
        final platform = ControlledPlatform()..stage = stage;
        final session = NotificationSession(
          ForgeNotifications(platform: platform),
        );
        if (stage != 'query') await session.initialize();
        final operation = switch (stage) {
          'query' => session.initialize(),
          'request' => session.requestPermission(),
          'post' => session.post('title', 'body'),
          _ => session.cancel('id'),
        };
        final logs = List.of(session.logs);
        var notifications = 0;
        session.addListener(() => notifications++);
        session.dispose();
        session.dispose();
        await operation.timeout(const Duration(seconds: 1));
        platform.permission.complete(
          ForgeNotificationOutcome.available(
            NotificationPermissionState.denied,
          ),
        );
        platform.posted.complete(
          ForgeNotificationOutcome.available(
            const PostedNotification(id: 'late'),
          ),
        );
        platform.cancelled.complete(ForgeNotificationOutcome.available(true));
        await Future<void>.delayed(Duration.zero);
        expect(session.logs, logs);
        expect(session.loading, isFalse);
        expect(notifications, 0);
        await session.requestPermission();
        await session.post('closed', 'closed');
        await session.cancel('closed');
      },
    );
  }
  test(
    'duplicate request and initialize cannot overwrite a pending request; failure allows retry',
    () async {
      final platform = ControlledPlatform();
      final session = NotificationSession(
        ForgeNotifications(platform: platform),
      );
      await session.initialize();
      final pending = session.requestPermission();
      await session.requestPermission();
      await session.initialize();
      expect(platform.requests, 1);
      platform.permission.complete(
        ForgeNotificationOutcome.state(
          NotificationStatus.unavailable,
          'activity_detached',
          'detached',
        ),
      );
      await pending;
      expect(session.loading, isFalse);
      expect(
        session.permissionState,
        NotificationPermissionState.granted,
        reason: 'request error does not erase a fresh system permission fact',
      );
      await session.initialize();
      expect(session.permissionState, NotificationPermissionState.granted);
      session.dispose();
    },
  );

  test('dispose during query ignores late result and future calls', () async {
    final platform = PendingPlatform();
    final session = NotificationSession(ForgeNotifications(platform: platform));
    final opening = session.initialize();
    session.dispose();
    await opening.timeout(const Duration(seconds: 1));
    platform.pending.complete(const NotificationCapabilities.none());
    await opening;
    expect(session.capabilities, isNull);
    await session.initialize();
  });
}
