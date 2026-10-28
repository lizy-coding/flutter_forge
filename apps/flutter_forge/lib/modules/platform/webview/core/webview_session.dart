import 'dart:async';
import 'package:flutter/foundation.dart';
import 'webview_backend.dart';
import 'offline_documents.dart';
import '../../../../shared/platform/build_features.dart';

// Adapted from webview_plugin's loading manager and navigation controller.
class WebViewSession extends ChangeNotifier {
  WebViewSession(this.backend, {this.timeout = const Duration(seconds: 3)});
  final WebViewBackend backend;
  final Duration timeout;
  StreamSubscription<WebViewEvent>? _subscription;
  Timer? _timer;
  bool _disposed = false;
  bool initialized = false;
  bool busy = false;
  bool contentVisible = false;
  bool loading = false;
  bool canBack = false;
  bool canForward = false;
  double progress = 0;
  String url = offlineEdition ? offlineOverviewUrl : 'https://example.com';
  String? error;
  int _generation = 0;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> start() async {
    if (_disposed || busy || initialized) return;
    busy = true;
    error = null;
    _notify();
    _subscription ??= backend.events.listen(
      _event,
      onError: (Object e) => _fail(e),
    );
    try {
      await backend.initialize();
      if (_disposed) return;
      initialized = true;
      busy = false;
      await navigate(url);
    } catch (e) {
      _fail(e);
    } finally {
      busy = false;
      _notify();
    }
  }

  void _begin() {
    _generation++;
    error = null;
    progress = 0;
    contentVisible = false;
    loading = true;
    _timer?.cancel();
    _timer = Timer(timeout, () {
      if (_disposed) return;
      contentVisible = true;
      _notify();
    });
    _notify();
  }

  void _fail(Object e) {
    if (_disposed) return;
    _timer?.cancel();
    error = e.toString();
    loading = false;
    _notify();
  }

  void _event(WebViewEvent event) {
    if (_disposed) return;
    if (event.url != null) url = event.url!;
    switch (event.kind) {
      case WebViewEventKind.started:
        _begin();
      case WebViewEventKind.progress:
        progress = event.progress.clamp(0, 1);
        if (progress >= 0.3) contentVisible = true;
      case WebViewEventKind.finished:
        _timer?.cancel();
        progress = 1;
        loading = false;
        contentVisible = true;
        unawaited(_history());
      case WebViewEventKind.error:
        _fail(event.message ?? '网页加载失败');
    }
    _notify();
  }

  Future<void> _history() async {
    final generation = _generation;
    try {
      final back = await backend.canGoBack();
      final forward = await backend.canGoForward();
      if (_disposed || generation != _generation) return;
      canBack = back;
      canForward = forward;
      _notify();
    } catch (e) {
      _fail(e);
    }
  }

  Future<void> navigate(String value) async {
    if (_disposed || !initialized) return;
    if (offlineEdition
        ? !isOfflineDocument(value.trim())
        : !isWebUrl(value.trim())) {
      _fail(offlineEdition ? '请选择内置教学页' : '请输入有效的 http 或 https 地址');
      return;
    }
    url = value.trim();
    _begin();
    await _command(() => backend.loadUrl(url));
  }

  Future<void> _command(Future<void> Function() action) async {
    if (_disposed || !initialized) return;
    try {
      await action();
    } catch (e) {
      _fail(e);
    }
  }

  Future<void> back() => _command(backend.goBack);
  Future<void> forward() => _command(backend.goForward);
  Future<void> reload() async {
    if (_disposed || !initialized) return;
    _begin();
    await _command(backend.reload);
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    unawaited(_subscription?.cancel());
    unawaited(
      backend.dispose().catchError((Object e) {
        debugPrint('WebView cleanup failed: $e');
      }),
    );
    super.dispose();
  }
}
