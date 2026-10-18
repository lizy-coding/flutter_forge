import 'package:flutter_test/flutter_test.dart';
import 'package:usb_network_bridge/usb_network_bridge.dart';

void main() {
  test('literal IPv4 validation rejects names, IPv6 and invalid octets', () {
    for (final value in ['192.168.7.2', '169.254.1.10', '10.0.0.1']) {
      expect(isUsbNetworkIpv4(value), isTrue);
    }
    for (final value in [
      '',
      'localhost',
      '::1',
      '256.1.1.1',
      '1.2.3',
      '1.2.3.-1',
      '1.2.3.4 ',
      '1.2.3.x',
    ]) {
      expect(isUsbNetworkIpv4(value), isFalse);
    }
  });
  test('physical route identity distinguishes local address changes', () {
    const first = UsbNetworkInterface(
      id: 'en7',
      name: 'en7',
      index: 7,
      address: '192.168.7.1',
      prefix: 24,
    );
    const changed = UsbNetworkInterface(
      id: 'en7',
      name: 'en7',
      index: 7,
      address: '192.168.8.1',
      prefix: 24,
    );
    expect(first.key, isNot(changed.key));
  });
  test('invalid target is rejected before loading native bindings', () async {
    final adapter = createUsbNetworkAdapter();
    const interface = UsbNetworkInterface(
      id: 'en7',
      name: 'en7',
      index: 7,
      address: '192.168.7.1',
      prefix: 24,
    );
    await expectLater(
      adapter.connect(interface, host: 'localhost', port: 1234),
      throwsArgumentError,
    );
    await expectLater(
      adapter.connect(interface, host: '192.168.7.2', port: 65536),
      throwsArgumentError,
    );
  });
}
