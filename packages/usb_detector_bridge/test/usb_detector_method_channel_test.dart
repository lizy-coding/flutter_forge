import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:usb_detector_bridge/usb_detector_bridge.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('usb_detector/usb');
  String? invokedMethod;

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    invokedMethod = null;
  });

  MethodChannel mockResponses(Object? Function(String method) respond) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          invokedMethod = call.method;
          return respond(call.method);
        });
    return channel;
  }

  test('malformed capabilities remain non-throwing', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    mockResponses((_) => {'enumerationSupported': 'yes'});
    expect(
      (await MethodChannelUsbDetector().queryCapabilities()).isSupported,
      isFalse,
    );
  });

  test('Android listDevices keeps the channel contract', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final detector = MethodChannelUsbDetector();
    mockResponses(
      (_) => [
        {
          'vendorId': 18,
          'productId': 52,
          'manufacturer': 'Android USB',
          'product': 'Test Device',
          'serialNumber': 'SN-1',
          'hasPermission': true,
          'id': 'usb0',
        },
      ],
    );

    final outcome = await detector.listDevices();

    expect(invokedMethod, 'listDevices');
    expect(outcome.isAvailable, isTrue);
    final device = outcome.value!.single;
    expect(device.displayName, 'Test Device');
    expect(device.serialNumber, 'SN-1');
    expect(device.hasPermission, isTrue);
    expect(device.platformDeviceId, 'usb0');
  });

  test(
    'entries without descriptors stay listed via the name fallback',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final detector = MethodChannelUsbDetector();
      mockResponses(
        (_) => [
          {'vendorId': 1, 'productId': 2, 'name': 'permission-required'},
        ],
      );

      final outcome = await detector.listDevices();

      expect(outcome.isAvailable, isTrue);
      expect(outcome.value!.single.displayName, 'permission-required');
    },
  );

  test(
    'a malformed entry degrades to an error entry, not a lost list',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final detector = MethodChannelUsbDetector();
      mockResponses(
        (_) => [
          {'vendorId': 1, 'productId': 2, 'product': 'ok-device'},
          'not-a-map',
        ],
      );

      final outcome = await detector.listDevices();

      expect(outcome.isAvailable, isTrue);
      expect(outcome.value, hasLength(2));
      expect(outcome.value!.last.status, UsbDeviceStatus.error);
    },
  );

  test('a non-list payload becomes invalidData', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final detector = MethodChannelUsbDetector();
    mockResponses((_) => {'unexpected': true});

    final outcome = await detector.listDevices();

    expect(outcome.status, UsbDetectionStatus.invalidData);
    expect(outcome.reason?.code, 'invalid_payload');
  });

  test('a missing native plugin becomes unavailable', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final detector = MethodChannelUsbDetector();

    final outcome = await detector.listDevices();

    expect(outcome.status, UsbDetectionStatus.unavailable);
    expect(outcome.reason?.code, 'missing_plugin');
  });

  test(
    'non-Android hosts stay unsupported without touching the channel',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      final detector = MethodChannelUsbDetector();

      final capabilities = await detector.queryCapabilities();
      final outcome = await detector.listDevices();

      expect(capabilities.isSupported, isFalse);
      expect(outcome.status, UsbDetectionStatus.unsupported);
      expect(outcome.reason?.code, 'platform_unsupported');
      expect(invokedMethod, isNull);
    },
  );

  test('queryCapabilities parses the native capability map', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final detector = MethodChannelUsbDetector();
    mockResponses(
      (method) => method == 'queryCapabilities'
          ? {'enumerationSupported': true, 'permissionStateSupported': true}
          : null,
    );

    final capabilities = await detector.queryCapabilities();

    expect(invokedMethod, 'queryCapabilities');
    expect(capabilities.enumerationSupported, isTrue);
    expect(capabilities.permissionStateSupported, isTrue);
  });

  test(
    'queryCapabilities degrades to none without the native plugin',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final detector = MethodChannelUsbDetector();

      final capabilities = await detector.queryCapabilities();

      expect(capabilities.isSupported, isFalse);
    },
  );
}
