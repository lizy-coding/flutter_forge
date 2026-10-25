import 'package:flutter_test/flutter_test.dart';
import 'package:forge_notification_bridge/forge_notification_bridge.dart';

void main() {
  group(ForgeNotificationOutcome, () {
    test('available carries a value', () {
      final outcome = ForgeNotificationOutcome<PostedNotification>.available(
        const PostedNotification(id: 'n-1'),
      );

      expect(outcome.isAvailable, isTrue);
      expect(outcome.value!.id, 'n-1');
      expect(outcome.reason, isNull);
    });

    test('state outcomes never carry a value', () {
      final outcome = ForgeNotificationOutcome<bool>.state(
        NotificationStatus.permissionDenied,
        'notifications_disabled',
        '应用通知已被系统关闭',
      );

      expect(outcome.isAvailable, isFalse);
      expect(outcome.value, isNull);
      expect(outcome.reason?.code, 'notifications_disabled');
    });

    test('available is not constructible as a state outcome', () {
      expect(
        () => ForgeNotificationOutcome<bool>.state(
          NotificationStatus.available,
          'invalid',
          'available must carry a value',
        ),
        throwsArgumentError,
      );
    });

    test('blank reason codes collapse to unspecified_reason', () {
      final outcome = ForgeNotificationOutcome<bool>.state(
        NotificationStatus.failed,
        '',
        '  ',
      );

      expect(outcome.reason?.code, 'unspecified_reason');
      expect(outcome.reason?.message, 'No additional detail');
    });

    test('fromMap keeps every field of an available reply', () {
      final outcome = ForgeNotificationOutcome.fromMap(
        {'status': 'available', 'notificationId': 'n-9'},
        parseValue: (map) =>
            PostedNotification(id: map['notificationId'] as String),
      );

      expect(outcome.isAvailable, isTrue);
      expect(outcome.value!.id, 'n-9');
    });
  });

  group(NotificationCapabilities, () {
    test('none reports no support', () {
      const capabilities = NotificationCapabilities.none();

      expect(capabilities.isSupported, isFalse);
      expect(capabilities.permissionQuerySupported, isFalse);
      expect(capabilities.permissionRequestSupported, isFalse);
      expect(capabilities.cancelSupported, isFalse);
    });

    test('fromMap parses the capability map', () {
      final capabilities = NotificationCapabilities.fromMap({
        'postingSupported': true,
        'permissionQuerySupported': true,
        'permissionRequestSupported': false,
        'cancelSupported': true,
      });

      expect(capabilities.isSupported, isTrue);
      expect(capabilities.permissionRequestSupported, isFalse);
    });
  });

  test('parsePermissionState rejects unknown values', () {
    expect(
      parsePermissionState('granted'),
      NotificationPermissionState.granted,
    );
    expect(() => parsePermissionState('vendor_state'), throwsFormatException);
    expect(() => parsePermissionState(42), throwsFormatException);
  });

  test('content serializes the visible fields', () {
    const content = NotificationContent(title: '教学通知', body: '正文');

    expect(content.toMap(), {'title': '教学通知', 'body': '正文'});
  });
}
