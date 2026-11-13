import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forge_notification_bridge/forge_notification_bridge.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(NotificationChannelContract.methodChannel);

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  void mockResponses(Object? Function(String method, Object? args) respond) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          return respond(call.method, call.arguments);
        });
  }

  test('queryCapabilities keeps the channel contract', () async {
    final adapter = MethodChannelForgeNotification();
    mockResponses((method, _) {
      expect(method, NotificationChannelContract.queryCapabilities);
      return {
        'postingSupported': true,
        'permissionQuerySupported': true,
        'permissionRequestSupported': true,
        'cancelSupported': true,
      };
    });

    final capabilities = await adapter.queryCapabilities();

    expect(capabilities.isSupported, isTrue);
    expect(capabilities.permissionRequestSupported, isTrue);
    expect(capabilities.cancelSupported, isTrue);
  });

  test('queryPermissionState maps every state string', () async {
    const states = {
      'granted': NotificationPermissionState.granted,
      'denied': NotificationPermissionState.denied,
      'notDetermined': NotificationPermissionState.notDetermined,
      'provisional': NotificationPermissionState.provisional,
      'unavailable': NotificationPermissionState.unavailable,
    };
    for (final entry in states.entries) {
      final adapter = MethodChannelForgeNotification();
      mockResponses((method, _) {
        expect(method, NotificationChannelContract.queryPermissionState);
        return {'status': 'available', 'state': entry.key};
      });

      final outcome = await adapter.queryPermissionState();

      expect(outcome.isAvailable, isTrue, reason: entry.key);
      expect(outcome.value, entry.value, reason: entry.key);
    }
  });

  test('requestPermission passes the request through', () async {
    final adapter = MethodChannelForgeNotification();
    mockResponses((method, _) {
      expect(method, NotificationChannelContract.requestPermission);
      return {'status': 'available', 'state': 'granted'};
    });

    final outcome = await adapter.requestPermission();

    expect(outcome.value, NotificationPermissionState.granted);
  });

  test('post serializes content and parses the returned id', () async {
    final adapter = MethodChannelForgeNotification();
    const content = NotificationContent(title: '教学通知', body: '这是一条本地通知');
    mockResponses((method, args) {
      expect(method, NotificationChannelContract.post);
      expect((args as Map<Object?, Object?>)['title'], '教学通知');
      return {'status': 'available', 'notificationId': 'notification-1'};
    });

    final outcome = await adapter.post(content);

    expect(outcome.isAvailable, isTrue);
    expect(outcome.value!.id, 'notification-1');
  });

  test('a post reply without an id degrades to invalidData', () async {
    final adapter = MethodChannelForgeNotification();
    mockResponses((_, _) => {'status': 'available'});

    final outcome = await adapter.post(
      const NotificationContent(title: '教学通知', body: '内容'),
    );

    expect(outcome.status, NotificationStatus.invalidData);
    expect(outcome.reason?.code, 'invalid_value');
  });

  test('cancel keeps the identifier argument contract', () async {
    final adapter = MethodChannelForgeNotification();
    mockResponses((method, args) {
      expect(method, NotificationChannelContract.cancel);
      expect(
        (args as Map<Object?, Object?>)[NotificationChannelContract
            .argNotificationId],
        'notification-1',
      );
      return {'status': 'available', 'cancelled': true};
    });

    final outcome = await adapter.cancel('notification-1');

    expect(outcome.isAvailable, isTrue);
    expect(outcome.value, isTrue);
  });

  test('native failure statuses map to typed outcomes', () async {
    const statuses = {
      'permissionDenied': NotificationStatus.permissionDenied,
      'notDetermined': NotificationStatus.notDetermined,
      'unavailable': NotificationStatus.unavailable,
      'failed': NotificationStatus.failed,
    };
    for (final entry in statuses.entries) {
      final adapter = MethodChannelForgeNotification();
      mockResponses(
        (_, _) => {
          'status': entry.key,
          'reason': 'native_reason',
          'message': 'native message',
        },
      );

      final outcome = await adapter.post(
        const NotificationContent(title: '教学通知', body: '内容'),
      );

      expect(outcome.status, entry.value, reason: entry.key);
      expect(outcome.reason?.code, 'native_reason');
    }
  });

  test('a null permission reply becomes invalidData', () async {
    final adapter = MethodChannelForgeNotification();
    mockResponses((_, _) => null);

    final outcome = await adapter.queryPermissionState();

    expect(outcome.status, NotificationStatus.invalidData);
    expect(outcome.reason?.code, 'null_response');
  });

  test('a PlatformException becomes unavailable, not a throw', () async {
    final adapter = MethodChannelForgeNotification();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          throw PlatformException(code: 'boom', message: 'native crash');
        });

    final outcome = await adapter.queryPermissionState();
    final capabilities = await adapter.queryCapabilities();

    expect(outcome.status, NotificationStatus.unavailable);
    expect(outcome.reason?.code, 'platform_exception');
    expect(capabilities.isSupported, isFalse);
  });

  test('missing plugin keeps every query non-throwing', () async {
    final adapter = MethodChannelForgeNotification();

    final capabilities = await adapter.queryCapabilities();
    final permission = await adapter.queryPermissionState();
    final post = await adapter.post(
      const NotificationContent(title: '教学通知', body: '内容'),
    );
    final cancel = await adapter.cancel('notification-1');

    expect(capabilities, const NotificationCapabilities.none());
    expect(permission.status, NotificationStatus.unsupported);
    expect(post.status, NotificationStatus.unsupported);
    expect(cancel.status, NotificationStatus.unsupported);
  });
}
