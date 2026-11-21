import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_forge_app/modules/platform/webview/core/webview_session.dart';
import 'package:flutter_forge_app/modules/platform/webview/platforms/webview_flutter_backend.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('WKWebView loads, navigates, reloads and reopens', (
    tester,
  ) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final requests = <String>[];
    server.listen((request) async {
      requests.add(request.uri.path);
      request.response.headers.contentType = ContentType.html;
      request.response.write(
        '<html><head><title>Forge WebView</title></head>'
        '<body><h1>Forge WKWebView ${request.uri.path}</h1></body></html>',
      );
      await request.response.close();
    });
    addTearDown(() => server.close(force: true));
    final base = 'http://127.0.0.1:${server.port}';

    Future<void> waitFor(bool Function() condition) async {
      for (var i = 0; i < 150; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 200)),
        );
        await tester.pump();
        if (condition()) return;
      }
      fail('Native WKWebView condition timed out');
    }

    for (var attempt = 0; attempt < 2; attempt++) {
      final backend = WebViewFlutterBackend();
      final session = WebViewSession(backend)..url = '$base/first';
      await session.start();
      expect(session.initialized, isTrue, reason: session.error);
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: backend.buildView())),
      );
      await waitFor(() => !session.loading && session.progress == 1);
      expect(session.error, isNull);
      expect(requests, contains('/first'));
      await session.navigate('$base/second');
      await waitFor(() => !session.loading && session.canBack);
      expect(requests, contains('/second'));
      await session.back();
      await waitFor(() => session.url.endsWith('/first') && session.canForward);
      await session.forward();
      await waitFor(() => session.url.endsWith('/second') && !session.loading);
      final previous = requests.where((p) => p == '/second').length;
      await session.reload();
      await waitFor(
        () =>
            !session.loading &&
            requests.where((p) => p == '/second').length > previous,
      );
      expect(session.error, isNull);
      await tester.pumpWidget(const SizedBox());
      session.dispose();
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
    }
  }, skip: !Platform.isMacOS);
}
