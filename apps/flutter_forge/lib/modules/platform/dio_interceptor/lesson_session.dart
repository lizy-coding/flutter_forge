import 'dart:async';

import 'mock_server/mock_server.dart'
    if (dart.library.js_interop) 'mock_server/mock_server_web.dart';
import 'network/api/api_service.dart';
import 'network/http_client.dart';
import '../../../shared/platform/build_features.dart';

// The pool is isolate-local: separate window engines never share a TCP port.
// Each mounted lesson/login page retains a lease until it leaves navigation.
class LessonSession {
  LessonSession._(this._server) {
    api = ApiService(_client);
    ready = _start();
    // A page can leave before FutureBuilder observes a failed startup.
    unawaited(ready.then<void>((_) {}, onError: (Object _, StackTrace __) {}));
  }

  static LessonSession? _active;
  final MockServer _server;
  final _client = HttpClient(baseUrl: 'http://lesson.local');
  late final ApiService api;
  late final Future<void> ready;
  int _leases = 0;
  bool _closed = false;
  bool _failed = false;

  static LessonLease acquire({MockServer Function()? createServer}) {
    if (_active == null || _active!._closed || _active!._failed) {
      _active = LessonSession._(createServer?.call() ?? MockServer());
    }
    final owner = _active!;
    owner._leases++;
    return LessonLease._(owner);
  }

  Future<void> _start() async {
    if (offlineEdition) return;
    try {
      await _server.start();
      if (_closed) throw StateError('学习会话已关闭');
      _client.dio.options.baseUrl = _server.baseUrl;
    } catch (_) {
      _failed = true;
      rethrow;
    }
  }

  Future<void> _release() async {
    if (--_leases > 0) return;
    _closed = true;
    if (identical(_active, this)) _active = null;
    _client.dispose();
    await _server.stop();
  }
}

class LessonLease {
  LessonLease._(this._owner);
  final LessonSession _owner;
  Future<void>? _closing;
  ApiService get api {
    if (_closing != null) throw StateError('学习会话租约已关闭');
    return _owner.api;
  }

  Future<void> get ready {
    if (_closing != null) throw StateError('学习会话租约已关闭');
    return _owner.ready;
  }

  Future<void> close() => _closing ??= _owner._release();
}
