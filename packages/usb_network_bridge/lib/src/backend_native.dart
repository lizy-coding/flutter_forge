import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import 'api.dart';

typedef _EnumerateNative = Uint32 Function(Pointer<Uint8>, Uint32);
typedef _Enumerate = int Function(Pointer<Uint8>, int);
typedef _OpenNative =
    Pointer<Void> Function(
      Pointer<Void>,
      Uint32,
      Pointer<Utf8>,
      Pointer<Utf8>,
      Uint16,
      Pointer<Uint8>,
      Pointer<Uint16>,
      Pointer<Int32>,
    );
typedef _Open =
    Pointer<Void> Function(
      Pointer<Void>,
      int,
      Pointer<Utf8>,
      Pointer<Utf8>,
      int,
      Pointer<Uint8>,
      Pointer<Uint16>,
      Pointer<Int32>,
    );

UsbNetworkAdapter createUsbNetworkAdapter() => _NativeAdapter();

final class _Bindings {
  _Bindings() {
    if (!Platform.isWindows && !Platform.isMacOS) {
      throw UnsupportedError('USB 网络示例仅支持 Windows/macOS');
    }
    final library = Platform.isWindows
        ? DynamicLibrary.open('usb_network_bridge.dll')
        : DynamicLibrary.process();
    enumerate = library.lookupFunction<_EnumerateNative, _Enumerate>(
      Platform.isWindows
          ? 'ForgeUsbNetInterfacesEnumerate'
          : 'ForgeUsbMacNcmInterfacesEnumerate',
    );
    final prefix = Platform.isWindows
        ? 'ForgeUsbBoundTcp'
        : 'ForgeUsbMacBoundTcp';
    open = library.lookupFunction<_OpenNative, _Open>('${prefix}Open');
    status = library
        .lookupFunction<
          Int32 Function(Pointer<Void>),
          int Function(Pointer<Void>)
        >('${prefix}Status');
    close = library
        .lookupFunction<
          Void Function(Pointer<Void>),
          void Function(Pointer<Void>)
        >('${prefix}Close');
  }
  late final _Enumerate enumerate;
  late final _Open open;
  late final int Function(Pointer<Void>) status;
  late final void Function(Pointer<Void>) close;
}

final class _NativeAdapter implements UsbNetworkAdapter {
  late final _bindings = _Bindings();

  @override
  Future<List<UsbNetworkInterface>> listInterfaces() async {
    final capacity = _bindings.enumerate(nullptr, 0);
    if (capacity == 0xffffffff || capacity > 4096) {
      throw const SocketException('网卡枚举失败');
    }
    if (capacity == 0) return const [];
    final recordSize = Platform.isWindows ? 222 : 28;
    final buffer = calloc<Uint8>(capacity * recordSize);
    try {
      final count = _bindings.enumerate(buffer, capacity);
      if (count == 0xffffffff || count > capacity) {
        throw const SocketException('网卡列表已变化，请重新扫描');
      }
      final records = <UsbNetworkInterface>[];
      for (var i = 0; i < count; i++) {
        final base = i * recordSize;
        // Windows kind 2 means NCM; macOS native enumeration returns only NCM.
        if (Platform.isWindows && _u32(buffer, base + 4) != 2) continue;
        final addressOffset = base + (Platform.isWindows ? 12 : 8);
        final address = List.generate(
          4,
          (j) => buffer[addressOffset + j],
        ).join('.');
        final id = Platform.isWindows
            ? _utf16(buffer, base + 16, 39)
            : _ascii(buffer, base + 12, 16);
        records.add(
          UsbNetworkInterface(
            id: id,
            name: Platform.isWindows ? _utf16(buffer, base + 94, 64) : id,
            index: _u32(buffer, base),
            address: address,
            prefix: _u32(buffer, base + (Platform.isWindows ? 8 : 4)),
          ),
        );
      }
      return List.unmodifiable(records);
    } finally {
      calloc.free(buffer);
    }
  }

  @override
  Future<UsbNetworkConnection> connect(
    UsbNetworkInterface interface, {
    required String host,
    required int port,
    Duration timeout = const Duration(seconds: 8),
  }) async {
    if (!isUsbNetworkIpv4(host) ||
        port < 1 ||
        port > 65535 ||
        interface.index <= 0 ||
        interface.id.isEmpty ||
        !isUsbNetworkIpv4(interface.address) ||
        timeout <= Duration.zero) {
      throw ArgumentError('请选择有效网卡并填写 IPv4 和 1–65535 端口');
    }
    final bindings = _bindings;
    final name = Platform.isWindows
        ? (interface.id.startsWith('{') ? interface.id : '{${interface.id}}')
              .toNativeUtf16()
              .cast<Void>()
        : interface.id.toNativeUtf8().cast<Void>();
    final source = interface.address.toNativeUtf8();
    final target = host.toNativeUtf8();
    final token = calloc<Uint8>(16);
    final localPort = calloc<Uint16>();
    final error = calloc<Int32>();
    Pointer<Void> handle = nullptr;
    Socket? socket;
    final clock = Stopwatch()..start();
    try {
      final random = Random.secure();
      final secret = Uint8List.fromList(
        List.generate(16, (_) => random.nextInt(256)),
      );
      token.asTypedList(16).setAll(0, secret);
      handle = bindings.open(
        name,
        interface.index,
        source,
        target,
        port,
        token,
        localPort,
        error,
      );
      if (handle == nullptr) {
        throw SocketException(
          'USB 接口绑定失败，请检查接口或重新扫描',
          osError: OSError('native', error.value),
        );
      }
      socket = await Socket.connect(
        InternetAddress.loopbackIPv4,
        localPort.value,
        timeout: timeout,
      );
      socket.add(secret);
      await socket.flush().timeout(timeout - clock.elapsed);
      while (bindings.status(handle) == 0 && clock.elapsed < timeout) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
      final state = bindings.status(handle);
      if (state != 1 || clock.elapsed >= timeout) {
        throw SocketException(
          '设备连接失败或超时',
          osError: OSError('native', state < 0 ? -state : 60),
        );
      }
      final connection = _TcpConnection(socket, handle, bindings);
      handle = nullptr;
      socket = null;
      return connection;
    } finally {
      socket?.destroy();
      if (handle != nullptr) bindings.close(handle);
      calloc.free(name);
      calloc.free(source);
      calloc.free(target);
      calloc.free(token);
      calloc.free(localPort);
      calloc.free(error);
    }
  }
}

final class _TcpConnection implements UsbNetworkConnection {
  _TcpConnection(this._socket, this._handle, this._bindings);
  final Socket _socket;
  Pointer<Void> _handle;
  final _Bindings _bindings;
  bool _closed = false;
  @override
  Stream<Uint8List> get received => _socket;
  @override
  Future<void> send(Uint8List bytes) async {
    if (_closed) throw StateError('连接已关闭');
    _socket.add(bytes);
    await _socket.flush().timeout(const Duration(seconds: 5));
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    _socket.destroy();
    _bindings.close(_handle);
    _handle = nullptr;
  }
}

int _u32(Pointer<Uint8> data, int offset) =>
    data[offset] |
    (data[offset + 1] << 8) |
    (data[offset + 2] << 16) |
    (data[offset + 3] << 24);
String _ascii(Pointer<Uint8> data, int offset, int length) =>
    String.fromCharCodes(
      List.generate(
        length,
        (i) => data[offset + i],
      ).takeWhile((unit) => unit != 0),
    );
String _utf16(Pointer<Uint8> data, int offset, int length) =>
    String.fromCharCodes(
      List.generate(
        length,
        (i) => data[offset + i * 2] | (data[offset + i * 2 + 1] << 8),
      ).takeWhile((unit) => unit != 0),
    );
