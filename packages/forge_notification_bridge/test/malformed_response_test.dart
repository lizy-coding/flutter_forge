import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forge_notification_bridge/forge_notification_bridge.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel(NotificationChannelContract.methodChannel);
  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null),
  );
  test('available cancellation and id require typed values', () async {
    final adapter = MethodChannelForgeNotification();
    for (final payload in [
      {'status': 'available'},
      {'status': 'available', 'cancelled': 'true'},
      {'status': 'available', 'notificationId': 42},
    ]) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (_) async => payload);
      expect(
        (await adapter.cancel('id')).status,
        NotificationStatus.invalidData,
      );
      expect(
        (await adapter.post(
          const NotificationContent(title: 'title', body: 'body'),
        )).status,
        NotificationStatus.invalidData,
      );
    }
  });
  for (final payload in <Object?>[
    42,
    'wrong',
    [],
    {'status': 'failed', 'reason': 42},
    {'status': 'failed', 'message': []},
  ]) {
    test('malformed reply $payload resolves to invalidData', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (_) async => payload);
      final adapter = MethodChannelForgeNotification();
      final result = await adapter.queryPermissionState();
      expect(result.status, NotificationStatus.invalidData);
    });
  }
}
