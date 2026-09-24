import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_forge_app/app/router/app_route_table.dart';
import 'package:flutter_forge_app/module_registry/app_platform_snapshot.dart';
import 'package:flutter_forge_app/module_registry/module_catalog_utils.dart';
import 'package:flutter_forge_app/modules/platform/webview/module_root.dart';
import 'webview_session_test.dart' show FakeWebViewBackend;

void main() {
  test('catalog enables Android, macOS and Windows WebView backends', () {
    final module = AppRouteTable.modules.singleWhere(
      (m) => m.path == '/webview',
    );
    for (final platform in [
      AppTargetPlatform.android,
      AppTargetPlatform.macOS,
      AppTargetPlatform.windows,
    ]) {
      expect(
        isModuleAvailable(module, AppPlatformSnapshot(platform: platform)),
        isTrue,
      );
    }
    for (final platform in [AppTargetPlatform.iOS, AppTargetPlatform.web]) {
      expect(
        isModuleAvailable(module, AppPlatformSnapshot(platform: platform)),
        isFalse,
      );
    }
  });
  testWidgets(
    'teaching page fits compact viewport and rejects invalid navigation',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final backend = FakeWebViewBackend();
      await tester.pumpWidget(MaterialApp(home: WebViewPage(backend: backend)));
      await tester.pump();
      expect(find.text('网页容器与跨平台导航'), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('webview-url')),
        'javascript:alert(1)',
      );
      await tester.tap(find.text('打开'));
      await tester.pump();
      expect(find.byKey(const ValueKey('webview-error')), findsOneWidget);
      expect(backend.calls, ['https://example.com']);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      expect(backend.disposed, isTrue);
    },
  );
}
