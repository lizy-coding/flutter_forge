import 'dart:async';
import 'dart:typed_data';

import 'package:usb_network_bridge/usb_network_bridge.dart';

const testInterface = UsbNetworkInterface(
  id: 'en7',
  name: 'USB NCM',
  index: 7,
  address: '192.168.7.1',
  prefix: 24,
);

class FakeUsbAdapter implements UsbNetworkAdapter {
  List<UsbNetworkInterface> interfaces = [testInterface];
  Object? scanError;
  Object? connectError;
  Completer<UsbNetworkConnection>? pending;
  final connection = FakeUsbConnection();
  int connectCalls = 0;
  String? host;
  int? port;
  UsbNetworkInterface? interface;
  @override
  Future<List<UsbNetworkInterface>> listInterfaces() async {
    if (scanError != null) throw scanError!;
    return interfaces;
  }

  @override
  Future<UsbNetworkConnection> connect(
    UsbNetworkInterface interface, {
    required String host,
    required int port,
    Duration timeout = const Duration(seconds: 8),
  }) async {
    connectCalls++;
    this.interface = interface;
    this.host = host;
    this.port = port;
    if (connectError != null) throw connectError!;
    return pending == null ? connection : await pending!.future;
  }
}

class FakeUsbConnection implements UsbNetworkConnection {
  final incoming = StreamController<Uint8List>();
  final sent = <Uint8List>[];
  int closeCalls = 0;
  @override
  Stream<Uint8List> get received => incoming.stream;
  @override
  Future<void> send(Uint8List bytes) async => sent.add(bytes);
  @override
  Future<void> close() async {
    closeCalls++;
    unawaited(incoming.close());
  }
}
