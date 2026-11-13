import 'package:flutter_test/flutter_test.dart';
import 'package:usb_detector_bridge/usb_detector_bridge.dart';

void main() {
  test('available outcome carries the value', () {
    final outcome = UsbDetectionOutcome<int>.available(7);

    expect(outcome.isAvailable, isTrue);
    expect(outcome.status, UsbDetectionStatus.available);
    expect(outcome.value, 7);
    expect(outcome.reason, isNull);
  });

  test('state outcome rejects the available status', () {
    expect(
      () => UsbDetectionOutcome<int>.state(
        UsbDetectionStatus.available,
        'code',
        'message',
      ),
      throwsArgumentError,
    );
  });

  test('blank reason parts fall back to stable placeholders', () {
    final outcome = UsbDetectionOutcome<int>.state(
      UsbDetectionStatus.failed,
      '  ',
      ' ',
    );

    expect(outcome.reason?.code, 'unspecified_reason');
    expect(outcome.reason?.message, 'No additional detail');
    expect(outcome.isAvailable, isFalse);
    expect(outcome.value, isNull);
  });

  test('none capabilities report no support', () {
    const capabilities = UsbDetectionCapabilities.none();

    expect(capabilities.isSupported, isFalse);
    expect(capabilities.enumerationSupported, isFalse);
    expect(capabilities.permissionStateSupported, isFalse);
  });

  test('capabilities parse a capability map with absent keys degrading', () {
    final capabilities = UsbDetectionCapabilities.fromMap({
      'enumerationSupported': true,
    });

    expect(capabilities.enumerationSupported, isTrue);
    expect(capabilities.permissionStateSupported, isFalse);
    expect(capabilities.isSupported, isTrue);
  });
}
