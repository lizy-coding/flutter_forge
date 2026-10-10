import 'api.dart';

UsbNetworkAdapter createUsbNetworkAdapter() => _UnsupportedAdapter();

final class _UnsupportedAdapter implements UsbNetworkAdapter {
  @override
  Future<List<UsbNetworkInterface>> listInterfaces() async =>
      throw UnsupportedError('USB 网络示例仅支持 Windows/macOS');
  @override
  Future<UsbNetworkConnection> connect(
    UsbNetworkInterface interface, {
    required String host,
    required int port,
    Duration timeout = const Duration(seconds: 8),
  }) async => throw UnsupportedError('USB 网络示例仅支持 Windows/macOS');
}
