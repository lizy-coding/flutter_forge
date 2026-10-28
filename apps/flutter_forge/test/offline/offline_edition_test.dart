import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_forge_app/app/creator_home_page.dart';
import 'package:flutter_forge_app/modules/platform/dio_interceptor/lesson_session.dart';
import 'package:flutter_forge_app/modules/platform/webview/core/offline_documents.dart';
import 'package:flutter_forge_app/modules/platform/webview/core/webview_backend.dart';
import 'package:flutter_forge_app/modules/platform/webview/core/webview_session.dart';
import 'package:flutter_forge_app/modules/platform/webview/module_root.dart';
import 'package:flutter_forge_app/modules/ui/genui_workbench/genui_session.dart';
import 'package:flutter_forge_app/modules/ui/genui_workbench/genui_workbench_page.dart';
import 'package:flutter_forge_app/modules/ui/workflow_workbench/module_entry.dart';
import 'package:flutter_forge_app/shared/platform/build_features.dart';
import 'package:flutter_forge_app/shared/workflows/hub_client.dart';
import '../modules/platform/webview/webview_session_test.dart'
    show FakeWebViewBackend;

class NoNetwork extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) =>
      throw StateError('Test forbids all network clients');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group(
    'offline distribution',
    () {
      test(
        'Dio login, pagination and create work without any socket server',
        () async {
          await HttpOverrides.runWithHttpOverrides(() async {
            final lease = LessonSession.acquire();
            try {
              await lease.ready;
              final login = await lease.api.login('admin', 'password123');
              lease.api.setToken((login['data'] as Map)['token'] as String);
              final before = await lease.api.getArticles(pageSize: 3);
              expect((before['data'] as Map)['articles'], hasLength(3));
              await lease.api.createArticle('离线文章', '本机内容');
              final after = await lease.api.getArticles(page: 3, pageSize: 10);
              expect(
                ((after['data'] as Map)['articles'] as List).single['title'],
                '离线文章',
              );
            } finally {
              await lease.close();
            }
          }, NoNetwork());
        },
      );

      test('WebView accepts only bundled lesson identifiers', () async {
        final backend = FakeWebViewBackend();
        final session = WebViewSession(backend);
        await session.start();
        await session.navigate('https://example.com');
        expect(session.error, isNotNull);
        expect(backend.calls, [offlineOverviewUrl]);
        await session.navigate(offlineCounterUrl);
        expect(session.error, isNull);
        expect(backend.calls.last, offlineCounterUrl);
        expect(
          offlineDocumentHtml(offlineCounterUrl),
          contains("connect-src 'none'"),
        );
        session.dispose();
      });

      testWidgets('offline WebView exposes local pages, not a URL editor', (
        tester,
      ) async {
        final backend = FakeWebViewBackend();
        await tester.pumpWidget(
          MaterialApp(home: WebViewPage(backend: backend)),
        );
        await tester.pump();
        backend.controller.add(const WebViewEvent(WebViewEventKind.finished));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('webview-url')), findsNothing);
        await tester.tap(find.text('页面交互'));
        await tester.pump();
        backend.controller.add(const WebViewEvent(WebViewEventKind.finished));
        await tester.pumpAndSettle();
        expect(backend.calls.last, offlineCounterUrl);
        await tester.pumpWidget(const SizedBox());
      });

      testWidgets('GenUI replay remains usable without connection controls', (
        tester,
      ) async {
        final session = GenuiSession();
        await tester.runAsync(() => session.submit('为什么设置宽度却没有生效？'));
        expect(session.hasSurface, isTrue);
        await tester.pumpWidget(
          MaterialApp(home: GenuiWorkbenchPage(session: session)),
        );
        await tester.pumpAndSettle();
        expect(find.text('连接模型服务'), findsNothing);
        await tester.pumpWidget(const SizedBox());
        session.dispose();
        expect(
          () => WorkflowHubClient(
            endpoint: Uri.parse('https://example.com'),
            token: '',
          ),
          throwsStateError,
        );
      });

      testWidgets(
        'local workflow supports failure, retry, filtering and cancellation',
        (tester) async {
          await tester.pumpWidget(
            const MaterialApp(home: WorkflowWorkbenchEntry()),
          );
          await tester.pumpAndSettle();
          expect(find.text('连接 Agent Hub'), findsNothing);
          await tester.tap(find.byType(Switch));
          await tester.tap(find.text('执行本地流程'));
          await tester.pumpAndSettle(const Duration(milliseconds: 100));
          expect(find.textContaining('教学故障：请求失败'), findsOneWidget);
          await tester.tap(find.byType(Switch));
          await tester.enterText(find.byType(TextField), 'admin');
          await tester.tap(find.text('执行本地流程'));
          await tester.pumpAndSettle(const Duration(milliseconds: 100));
          expect(find.text('执行完成'), findsOneWidget);
          expect(find.text('文章标题 2'), findsOneWidget);
          expect(find.text('文章标题 1'), findsNothing);
          await tester.tap(find.text('执行本地流程'));
          await tester.pump();
          await tester.tap(find.text('取消执行'));
          await tester.pumpAndSettle(const Duration(milliseconds: 100));
          expect(find.text('已取消'), findsOneWidget);
          await tester.pumpWidget(const SizedBox());
        },
      );

      testWidgets(
        'about exposes local privacy and removes external destinations',
        (tester) async {
          await tester.pumpWidget(
            const MaterialApp(home: Scaffold(body: CreatorHomePage())),
          );
          await tester.pumpAndSettle();
          expect(
            find.byKey(const ValueKey('profile-github-link')),
            findsNothing,
          );
          await tester.ensureVisible(find.text('隐私说明与权限用途'));
          await tester.tap(find.text('隐私说明与权限用途'));
          await tester.pumpAndSettle();
          expect(
            find.textContaining('Android 离线发行包不声明互联网访问权限'),
            findsOneWidget,
          );
          await tester.pumpWidget(const SizedBox());
        },
      );
    },
    skip: !offlineEdition ? 'Run with --dart-define=FORGE_OFFLINE=true' : false,
  );
}
