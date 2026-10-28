import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../core/webview_backend.dart';
import '../core/offline_documents.dart';
import '../../../../shared/platform/build_features.dart';

// webview_flutter selects Android WebView or macOS WKWebView at registration.
class WebViewFlutterBackend implements WebViewBackend {
  final _events = StreamController<WebViewEvent>.broadcast();
  WebViewController? _controller;
  bool _disposed = false;
  final _offlineHistory = <String>[];
  int _offlineIndex = -1;
  @override
  Stream<WebViewEvent> get events => _events.stream;
  void _emit(WebViewEvent event) {
    if (!_disposed) _events.add(event);
  }

  @override
  Future<void> initialize() async {
    final controller = WebViewController();
    _controller = controller;
    await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    if (_disposed) return;
    await controller.setNavigationDelegate(
      NavigationDelegate(
        onNavigationRequest: (request) =>
            (offlineEdition
                ? request.url == 'about:blank'
                : isWebUrl(request.url))
            ? NavigationDecision.navigate
            : NavigationDecision.prevent,
        onPageStarted: (url) =>
            _emit(WebViewEvent(WebViewEventKind.started, url: url)),
        onProgress: (progress) => _emit(
          WebViewEvent(WebViewEventKind.progress, progress: progress / 100),
        ),
        onPageFinished: (url) =>
            _emit(WebViewEvent(WebViewEventKind.finished, url: url)),
        onWebResourceError: (error) {
          if (error.isForMainFrame != false) {
            _emit(
              WebViewEvent(WebViewEventKind.error, message: error.description),
            );
          }
        },
      ),
    );
  }

  @override
  Widget buildView() => WebViewWidget(controller: _controller!);
  @override
  Future<void> loadUrl(String url) async {
    if (!offlineEdition) return _controller!.loadRequest(Uri.parse(url));
    if (!isOfflineDocument(url)) throw ArgumentError.value(url, 'url');
    _offlineHistory.removeRange(_offlineIndex + 1, _offlineHistory.length);
    _offlineHistory.add(url);
    _offlineIndex++;
    await _controller!.loadHtmlString(offlineDocumentHtml(url));
  }

  @override
  Future<bool> canGoBack() async =>
      offlineEdition ? _offlineIndex > 0 : await _controller!.canGoBack();
  @override
  Future<bool> canGoForward() async => offlineEdition
      ? _offlineIndex + 1 < _offlineHistory.length
      : await _controller!.canGoForward();
  @override
  Future<void> goBack() async {
    if (!offlineEdition) return _controller!.goBack();
    if (_offlineIndex > 0) {
      await _controller!.loadHtmlString(
        offlineDocumentHtml(_offlineHistory[--_offlineIndex]),
      );
    }
  }

  @override
  Future<void> goForward() async {
    if (!offlineEdition) return _controller!.goForward();
    if (_offlineIndex + 1 < _offlineHistory.length) {
      await _controller!.loadHtmlString(
        offlineDocumentHtml(_offlineHistory[++_offlineIndex]),
      );
    }
  }

  @override
  Future<void> reload() async {
    if (!offlineEdition) return _controller!.reload();
    if (_offlineIndex >= 0) {
      await _controller!.loadHtmlString(
        offlineDocumentHtml(_offlineHistory[_offlineIndex]),
      );
    }
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    // webview_flutter owns native disposal through WebViewWidget unmount.
    await _events.close();
  }
}
