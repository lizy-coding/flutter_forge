import 'package:flutter/material.dart';
import 'package:flutter_forge_app/modules/platform/system_notification/module_entry.dart';
import 'package:flutter_forge_app/modules/platform/system_notification/notification_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forge_notification_bridge/forge_notification_bridge.dart';

class FakeNotificationPlatform extends ForgeNotificationPlatform {
  NotificationCapabilities capabilities = const NotificationCapabilities(
    postingSupported: true,
    permissionQuerySupported: true,
    permissionRequestSupported: true,
    cancelSupported: true,
  );
  NotificationPermissionState state = NotificationPermissionState.notDetermined;
  ForgeNotificationOutcome<PostedNotification> postOutcome =
      ForgeNotificationOutcome.available(const PostedNotification(id: 'n-1'));
  final postedContent = <NotificationContent>[];
  final cancelledIds = <String>[];

  @override
  Future<NotificationCapabilities> queryCapabilities() async => capabilities;

  @override
  Future<ForgeNotificationOutcome<NotificationPermissionState>>
  queryPermissionState() async => ForgeNotificationOutcome.available(state);

  @override
  Future<ForgeNotificationOutcome<NotificationPermissionState>>
  requestPermission() async {
    state = NotificationPermissionState.granted;
    return ForgeNotificationOutcome.available(state);
  }

  @override
  Future<ForgeNotificationOutcome<PostedNotification>> post(
    NotificationContent content,
  ) async {
    postedContent.add(content);
    return postOutcome;
  }

  @override
  Future<ForgeNotificationOutcome<bool>> cancel(String id) async {
    cancelledIds.add(id);
    return ForgeNotificationOutcome.available(true);
  }
}

ForgeNotifications fakeBridge(FakeNotificationPlatform platform) =>
    ForgeNotifications(platform: platform);

void main() {
  group(NotificationSession, () {
    test('initialize reads capability and permission facts', () async {
      final platform = FakeNotificationPlatform();
      final session = NotificationSession(fakeBridge(platform));

      await session.initialize();

      expect(
        session.permissionState,
        NotificationPermissionState.notDetermined,
      );
      expect(session.permissionText, contains('未决定'));
      expect(session.permissionStateName, 'notDetermined');
    });

    test('requestPermission refreshes the stored state', () async {
      final platform = FakeNotificationPlatform();
      final session = NotificationSession(fakeBridge(platform));
      await session.initialize();

      await session.requestPermission();

      expect(session.permissionState, NotificationPermissionState.granted);
      expect(session.logs.single, contains('granted'));
    });

    test('post records the delivered id', () async {
      final platform = FakeNotificationPlatform();
      final session = NotificationSession(fakeBridge(platform));

      await session.post('教学通知', '正文');

      expect(platform.postedContent.single.title, '教学通知');
      expect(session.logs.single, contains('投递成功'));
      expect(session.logs.single, contains('n-1'));
    });

    test('a denied post surfaces its reason code', () async {
      final platform = FakeNotificationPlatform()
        ..postOutcome = ForgeNotificationOutcome.state(
          NotificationStatus.permissionDenied,
          'post_notifications_denied',
          '系统未授予通知权限',
        );
      final session = NotificationSession(fakeBridge(platform));

      await session.post('教学通知', '正文');

      expect(session.logs.single, contains('permissionDenied'));
      expect(session.logs.single, contains('post_notifications_denied'));
    });

    test('cancel forwards the identifier', () async {
      final platform = FakeNotificationPlatform();
      final session = NotificationSession(fakeBridge(platform));

      await session.cancel('n-1');

      expect(platform.cancelledIds, ['n-1']);
      expect(session.logs.single, contains('撤回成功'));
    });
  });

  testWidgets('entry renders permission state and delivers a post', (
    tester,
  ) async {
    final platform = FakeNotificationPlatform();
    await tester.pumpWidget(
      MaterialApp(
        home: SystemNotificationEntry(notifications: fakeBridge(platform)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('未决定'), findsWidgets);
    expect(find.textContaining('notDetermined'), findsWidgets);

    await tester.tap(find.text('投递通知'));
    await tester.pumpAndSettle();

    expect(find.textContaining('投递成功'), findsOneWidget);
    expect(platform.postedContent, hasLength(1));
  });

  testWidgets('entry hides the request button when the platform cannot ask', (
    tester,
  ) async {
    final platform = FakeNotificationPlatform()
      ..capabilities = const NotificationCapabilities(
        postingSupported: true,
        permissionQuerySupported: true,
        permissionRequestSupported: false,
        cancelSupported: true,
      );
    await tester.pumpWidget(
      MaterialApp(
        home: SystemNotificationEntry(notifications: fakeBridge(platform)),
      ),
    );
    await tester.pumpAndSettle();

    final requestButton = tester.widget<OutlinedButton>(
      find.ancestor(
        of: find.text('请求授权'),
        matching: find.byType(OutlinedButton),
      ),
    );
    expect(requestButton.onPressed, isNull);
  });
}
