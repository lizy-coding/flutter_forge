import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_forge_app/modules/platform/usb_network/usb_network_session.dart';
import 'package:usb_network_bridge/usb_network_bridge.dart';

import 'fake_usb_network.dart';

void main() {
  test(
    'selected route, target and bytes pass through without device protocol',
    () async {
      final adapter = FakeUsbAdapter();
      final session = UsbNetworkSession(adapter);
      await session.scan();
      await session.connect('192.168.7.2', '1234');
      expect(adapter.interface, same(testInterface));
      expect(adapter.host, '192.168.7.2');
      expect(adapter.port, 1234);
      await session.send('hello');
      expect(utf8.decode(adapter.connection.sent.single), 'hello\n');
      adapter.connection.incoming.add(Uint8List.fromList(utf8.encode('world')));
      await Future<void>.delayed(Duration.zero);
      expect(session.logs.any((line) => line.contains('world')), isTrue);
      await session.disconnect();
      expect(session.connected, isFalse);
      expect(adapter.connection.closeCalls, 1);
      session.dispose();
    },
  );
  test(
    'empty scan, native error and invalid input remain observable',
    () async {
      final adapter = FakeUsbAdapter()..interfaces = [];
      final session = UsbNetworkSession(adapter);
      await session.scan();
      expect(session.status, '未发现可用 NCM 网卡');
      adapter.scanError = StateError('native unavailable');
      await session.scan();
      expect(session.status, '扫描失败');
      adapter.scanError = null;
      adapter.interfaces = [testInterface];
      await session.scan();
      await session.connect('localhost', '1234');
      await session.connect('192.168.7.2', '0');
      expect(adapter.connectCalls, 0);
      adapter.connectError = StateError('connection refused');
      await session.connect('192.168.7.2', '1234');
      expect(session.status, '连接失败');
      expect(session.connected, isFalse);
      session.dispose();
    },
  );
  test(
    'disconnect during opening awaits and closes the late connection',
    () async {
      final adapter = FakeUsbAdapter()
        ..pending = Completer<UsbNetworkConnection>();
      final session = UsbNetworkSession(adapter);
      await session.scan();
      final opening = session.connect('192.168.7.2', '1234');
      final closing = session.disconnect();
      adapter.pending!.complete(adapter.connection);
      await opening;
      await closing;
      expect(session.connected, isFalse);
      expect(adapter.connection.closeCalls, 1);
      expect(session.status, '未连接');
      session.dispose();
    },
  );
  test(
    'dispose suppresses late callbacks and releases an opening connection',
    () async {
      final adapter = FakeUsbAdapter()
        ..pending = Completer<UsbNetworkConnection>();
      final session = UsbNetworkSession(adapter);
      await session.scan();
      var changes = 0;
      session.addListener(() => changes++);
      final opening = session.connect('192.168.7.2', '1234');
      session.dispose();
      final before = changes;
      adapter.pending!.complete(adapter.connection);
      await opening;
      await Future<void>.delayed(Duration.zero);
      expect(changes, before);
      expect(adapter.connection.closeCalls, 1);
    },
  );
  test('peer loss disconnects and never schedules reconnect', () async {
    final adapter = FakeUsbAdapter();
    final session = UsbNetworkSession(adapter);
    await session.scan();
    await session.connect('192.168.7.2', '1234');
    await adapter.connection.incoming.close();
    await Future<void>.delayed(Duration.zero);
    expect(session.connected, isFalse);
    expect(adapter.connectCalls, 1);
    expect(adapter.connection.closeCalls, 1);
    session.dispose();
  });
  test('sending and log history have bounded size', () async {
    final adapter = FakeUsbAdapter();
    final session = UsbNetworkSession(adapter);
    await session.scan();
    await session.connect('192.168.7.2', '1234');
    await session.send('a' * 4096);
    expect(adapter.connection.sent, isEmpty);
    for (var i = 0; i < 110; i++) {
      await session.send('$i', appendNewline: false);
    }
    expect(session.logs.length, 100);
    expect(utf8.decode(adapter.connection.sent.last), '109');
    await session.disconnect();
    session.dispose();
  });
}
