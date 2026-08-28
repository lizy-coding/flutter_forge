import 'package:flutter/services.dart';
import 'package:flutter_forge_app/modules/platform/usb_detector/services/usb_detection_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UsbDetectionService Windows', () {
    late MethodChannel channel;
    late UsbDetectionService service;

    setUp(() {
      channel = const MethodChannel('usb_detector/usb-test-windows');
      service = UsbDetectionService.forTesting(
        platform: TargetPlatform.windows,
        channel: channel,
      );
    });

    tearDown(() => service.dispose());

    test('enumerates devices and refreshes on native hotplug event', () async {
      final deviceEvents = <List<dynamic>>[];
      final statuses = <String>[];
      final deviceSubscription = service.deviceStream.listen(deviceEvents.add);
      final statusSubscription = service.statusStream.listen(statuses.add);
      var enumerateCount = 0;

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (call.method == 'enumerate') {
              enumerateCount++;
              return [
                {'id': 'USB\\VID_1234&PID_5678', 'name': 'USB Test Device'},
              ];
            }
            return null;
          });

      expect(await service.initialize(), isTrue);
      await Future<void>.delayed(Duration.zero);
      expect(
        deviceEvents.single.single.deviceId,
        equals('USB\\VID_1234&PID_5678'),
      );
      expect(deviceEvents.single.single.product, equals('USB Test Device'));

      await service.handleNativeMethodCall(
        const MethodCall('onDevicesChanged', <dynamic>[]),
      );
      await Future<void>.delayed(Duration.zero);

      expect(enumerateCount, equals(2));
      expect(deviceEvents, hasLength(2));
      expect(statuses, contains('USB服务初始化成功'));
      expect(statuses, contains('发现 1 个USB设备'));

      await deviceSubscription.cancel();
      await statusSubscription.cancel();
    });
  });

  test('keeps Android listDevices channel contract', () async {
    const channel = MethodChannel('usb_detector/usb-test-android');
    final service = UsbDetectionService.forTesting(
      platform: TargetPlatform.android,
      channel: channel,
    );
    addTearDown(service.dispose);

    String? invokedMethod;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          invokedMethod = call.method;
          return [
            {
              'vendorId': 18,
              'productId': 52,
              'manufacturer': 'Android USB',
              'product': 'Test Device',
            },
          ];
        });

    expect(await service.initialize(), isTrue);
    expect(invokedMethod, equals('listDevices'));
    expect(service.connectedDevices.single.displayName, equals('Test Device'));
  });
}
