import 'dart:typed_data';

/// One active IPv4 interface identified by the OS as USB CDC-NCM.
final class UsbNetworkInterface {
  const UsbNetworkInterface({
    required this.id,
    required this.name,
    required this.index,
    required this.address,
    required this.prefix,
  });
  final String id;
  final String name;
  final int index;
  final String address;
  final int prefix;
  String get key => '$id:$index:$address';
}

/// OS adapter only; it neither installs drivers nor discovers device protocols.
abstract interface class UsbNetworkAdapter {
  Future<List<UsbNetworkInterface>> listInterfaces();
  Future<UsbNetworkConnection> connect(
    UsbNetworkInterface interface, {
    required String host,
    required int port,
    Duration timeout = const Duration(seconds: 8),
  });
}

/// Caller-owned raw TCP connection. Received chunks are not message boundaries.
abstract interface class UsbNetworkConnection {
  Stream<Uint8List> get received;
  Future<void> send(Uint8List bytes);
  Future<void> close();
}

/// This example accepts literal IPv4 targets, never hostnames or IPv6.
bool isUsbNetworkIpv4(String value) {
  final parts = value.split('.');
  return parts.length == 4 &&
      parts.every((part) {
        if (!RegExp(r'^\d{1,3}$').hasMatch(part)) return false;
        final number = int.parse(part);
        return number <= 255;
      });
}
