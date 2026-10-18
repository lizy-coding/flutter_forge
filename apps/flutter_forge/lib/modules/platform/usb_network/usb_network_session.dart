import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:usb_network_bridge/usb_network_bridge.dart';

/// Page-owned learning session; no global state, retry, discovery or protocol.
class UsbNetworkSession extends ChangeNotifier {
  UsbNetworkSession(this.adapter);
  final UsbNetworkAdapter adapter;
  List<UsbNetworkInterface> interfaces = const [];
  UsbNetworkInterface? selected;
  final List<String> _logs = [];
  List<String> get logs => List.unmodifiable(_logs);
  String status = '未连接';
  bool busy = false;
  bool sending = false;
  bool get connected => _connection != null;
  UsbNetworkConnection? _connection;
  // Ownership is released through a local alias or the owner teardown; covered by lifecycle tests.
  // ignore: cancel_subscriptions
  StreamSubscription<Uint8List>? _subscription;
  Future<void>? _opening;
  Future<void>? _closing;
  int _generation = 0;
  bool _disposed = false;

  void _log(String message) {
    if (_disposed) return;
    _logs.add(message);
    if (_logs.length > 100) _logs.removeAt(0);
    notifyListeners();
  }

  Future<void> scan() async {
    if (_disposed || busy || connected || _closing != null) return;
    busy = true;
    status = '扫描中';
    notifyListeners();
    try {
      final result = await adapter.listInterfaces();
      if (_disposed) return;
      interfaces = result;
      final previous = selected?.key;
      selected =
          result.where((item) => item.key == previous).firstOrNull ??
          result.firstOrNull;
      status = result.isEmpty ? '未发现可用 NCM 网卡' : '发现 ${result.length} 个 NCM 接口';
      _log(status);
    } catch (error) {
      if (_disposed) return;
      interfaces = const [];
      selected = null;
      status = '扫描失败';
      _log('$status：$error');
    } finally {
      busy = false;
      if (!_disposed) notifyListeners();
    }
  }

  void select(String key) {
    if (_disposed || busy || connected) return;
    selected = interfaces.where((item) => item.key == key).firstOrNull;
    notifyListeners();
  }

  Future<void> connect(String host, String portText) async {
    if (_disposed || busy || connected || _closing != null) return;
    final interface = selected;
    final port = int.tryParse(portText.trim());
    host = host.trim();
    if (interface == null ||
        !isUsbNetworkIpv4(host) ||
        port == null ||
        port < 1 ||
        port > 65535) {
      status = '请选择网卡并填写有效 IPv4 和端口';
      _log(status);
      return;
    }
    busy = true;
    status = '连接中';
    final generation = ++_generation;
    notifyListeners();
    final opening = _connect(interface, host, port, generation);
    _opening = opening;
    try {
      await opening;
    } finally {
      if (identical(_opening, opening)) _opening = null;
      busy = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> _connect(
    UsbNetworkInterface interface,
    String host,
    int port,
    int generation,
  ) async {
    try {
      final connection = await adapter.connect(
        interface,
        host: host,
        port: port,
      );
      if (_disposed || generation != _generation) {
        await connection.close();
        return;
      }
      _connection = connection;
      _subscription = connection.received.listen(
        (bytes) {
          if (_disposed || generation != _generation) return;
          final preview = bytes.take(512).toList();
          final hex = preview
              .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
              .join(' ');
          _log(
            '接收 ${bytes.length} B：${utf8.decode(preview, allowMalformed: true)}\nHEX $hex${bytes.length > 512 ? ' …' : ''}',
          );
        },
        onError: (Object error) {
          if (_disposed || generation != _generation) return;
          _log('接收失败：$error');
          unawaited(disconnect());
        },
        onDone: () {
          if (!_disposed && generation == _generation) unawaited(disconnect());
        },
        cancelOnError: true,
      );
      status = '已连接';
      _log('已连接 $host:$port，经 ${interface.name} / ${interface.address}');
    } catch (error) {
      if (_disposed || generation != _generation) return;
      status = '连接失败';
      _log('$status：$error');
    }
  }

  Future<void> send(String text, {bool appendNewline = true}) async {
    final connection = _connection;
    if (_disposed || connection == null || sending || text.isEmpty) return;
    final generation = _generation;
    final bytes = Uint8List.fromList(
      utf8.encode('$text${appendNewline ? '\n' : ''}'),
    );
    if (bytes.length > 4096) {
      _log('发送失败：单次最多 4096 字节');
      return;
    }
    sending = true;
    notifyListeners();
    try {
      await connection.send(bytes);
      if (!_disposed && generation == _generation) {
        _log('发送 ${bytes.length} B：$text');
      }
    } catch (error) {
      if (!_disposed && generation == _generation) {
        _log('发送失败：$error');
        await disconnect();
      }
    } finally {
      sending = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> disconnect() {
    if (_closing != null) return _closing!;
    ++_generation;
    status = '断开中';
    if (!_disposed) notifyListeners();
    final closing = _disconnect();
    _closing = closing;
    return closing.whenComplete(() {
      if (identical(_closing, closing)) _closing = null;
    });
  }

  Future<void> _disconnect() async {
    await _opening;
    final connection = _connection;
    final subscription = _subscription;
    _connection = null;
    _subscription = null;
    try {
      // Stop the transport before waiting for listener cancellation.
      await connection?.close();
    } catch (error) {
      _log('关闭失败：$error');
    } finally {
      await subscription?.cancel();
      status = '未连接';
      _log('连接已关闭');
    }
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(disconnect());
    super.dispose();
  }
}
