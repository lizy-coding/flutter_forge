import 'package:flutter/services.dart';
import 'package:flutter_forge_app/modules/platform/usb_detector/services/usb_detection_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('keeps Android listDevices channel contract', () async {
    const channel = MethodChannel('usb_detector/usb-test-android');
    final service = UsbDetectionService.forTesting(channel: channel);
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
