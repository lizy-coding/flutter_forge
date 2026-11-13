import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_forge_app/modules/platform/usb_detector/usb_detector_session.dart';
import 'package:usb_detector_bridge/usb_detector_bridge.dart';

class _FakeBridge implements UsbDetectorBridge {
  _FakeBridge({
    UsbDetectionCapabilities? capabilities,
    UsbDetectionOutcome<List<UsbDeviceInfo>> Function()? listDevices,
  }) : _capabilities = capabilities ?? const UsbDetectionCapabilities.none(),
       _listDevices = listDevices;

  final UsbDetectionCapabilities _capabilities;
  final UsbDetectionOutcome<List<UsbDeviceInfo>> Function()? _listDevices;

  int listCalls = 0;

  @override
  Future<UsbDetectionCapabilities> queryCapabilities() async => _capabilities;

  @override
  Future<UsbDetectionOutcome<List<UsbDeviceInfo>>> listDevices() async {
    listCalls++;
    final respond = _listDevices;
    return respond != null
        ? respond()
        : UsbDetectionOutcome.available(const []);
  }
}

UsbDeviceInfo _device(
  int index, {
  UsbDeviceStatus status = UsbDeviceStatus.connected,
}) => UsbDeviceInfo(
  vendorId: index,
  productId: index * 10,
  product: 'Device $index',
  status: status,
);

void main() {
  test('unsupported host never lists devices', () async {
    final bridge = _FakeBridge();
    final session = UsbDetectorSession(bridge: bridge);
    addTearDown(session.dispose);

    await session.initialize();

    expect(session.supported, isFalse);
    expect(session.devices, isEmpty);
    expect(session.listResult, isNull);
    expect(bridge.listCalls, 0);
    expect(session.statusText, contains('不支持'));
    expect(session.scanning, isFalse);
  });

  test('supported host exposes the enumerated devices', () async {
    final bridge = _FakeBridge(
      capabilities: const UsbDetectionCapabilities(
        enumerationSupported: true,
        permissionStateSupported: true,
      ),
      listDevices: () =>
          UsbDetectionOutcome.available([_device(1), _device(2)]),
    );
    final session = UsbDetectorSession(bridge: bridge);
    addTearDown(session.dispose);

    await session.initialize();

    expect(session.supported, isTrue);
    expect(session.devices, hasLength(2));
    expect(session.statusText, 'USB功能正常：检测到 2 个设备');
    expect(session.scanning, isTrue);
    expect(bridge.listCalls, 1);
  });

  test('error entries surface a partial failure status', () async {
    final bridge = _FakeBridge(
      capabilities: const UsbDetectionCapabilities(
        enumerationSupported: true,
        permissionStateSupported: false,
      ),
      listDevices: () => UsbDetectionOutcome.available([
        _device(1),
        _device(2, status: UsbDeviceStatus.error),
      ]),
    );
    final session = UsbDetectorSession(bridge: bridge);
    addTearDown(session.dispose);

    await session.initialize();

    expect(session.errorCount, 1);
    expect(session.statusText, 'USB功能部分异常：1 个设备正常，1 个设备异常');
  });

  test('unavailable outcomes keep their reason visible', () async {
    final bridge = _FakeBridge(
      capabilities: const UsbDetectionCapabilities(
        enumerationSupported: true,
        permissionStateSupported: false,
      ),
      listDevices: () => UsbDetectionOutcome.state(
        UsbDetectionStatus.unavailable,
        'missing_plugin',
        '宿主未注册通道',
      ),
    );
    final session = UsbDetectorSession(bridge: bridge);
    addTearDown(session.dispose);

    await session.initialize();

    expect(session.devices, isEmpty);
    expect(session.reason?.code, 'missing_plugin');
    expect(session.statusText, contains('USB 服务不可用'));
  });

  test('periodic scan ticks refresh and stop cleanly', () async {
    final bridge = _FakeBridge(
      capabilities: const UsbDetectionCapabilities(
        enumerationSupported: true,
        permissionStateSupported: true,
      ),
    );
    final session = UsbDetectorSession(bridge: bridge);
    addTearDown(session.dispose);

    await session.initialize();
    expect(session.scanning, isTrue);

    await session.scanTick();
    await session.scanTick();
    expect(bridge.listCalls, 3); // initialize + two ticks

    session.stopPeriodicScan();
    expect(session.scanning, isFalse);

    session.dispose();
    expect(session.scanning, isFalse);
  });

  test('loadSystemInfo completes without throwing in the test host', () async {
    final session = UsbDetectorSession(bridge: _FakeBridge());
    addTearDown(session.dispose);

    await session.loadSystemInfo();

    expect(session.capabilityResolved, isFalse);
  });
}
