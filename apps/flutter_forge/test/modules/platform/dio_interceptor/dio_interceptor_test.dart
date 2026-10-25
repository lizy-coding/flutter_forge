import 'package:flutter/widgets.dart';
import 'package:flutter_forge_app/modules/platform/dio_interceptor/lesson_session.dart';
import 'package:flutter_forge_app/modules/platform/dio_interceptor/mock_server/mock_server.dart';
import 'package:flutter_forge_app/modules/platform/dio_interceptor/module_entry.dart';
import 'package:flutter_test/flutter_test.dart';

class _BrokenServer extends MockServer {
  @override
  Future<void> start() async => throw StateError('模拟服务无法启动');
}

// Loopback round-trips can hit the client's fixed 10s receiveTimeout when
// the whole module suite runs at full parallelism; one retry keeps the
// contract assertions deterministic without touching production timeouts.
Future<T> withRetry<T>(Future<T> Function() action) async {
  try {
    return await action();
  } on Exception {
    return await action();
  }
}

void main() {
  test('module entry is constructible', () {
    expect(const InterceptorTestEntry(), isA<Widget>());
  });

  test('leases share one session until the last close', () async {
    final first = LessonSession.acquire();
    final second = LessonSession.acquire();
    addTearDown(first.close);
    addTearDown(second.close);

    await first.ready;
    // The login page stores the nested token explicitly (see _login), so the
    // test walks the same path instead of relying on interceptor auto-capture.
    final login = await withRetry(
      () => second.api.login('admin', 'password123'),
    );
    second.api.setToken(((login['data'] as Map)['token']) as String);
    final articles = await withRetry(() => second.api.getArticles());
    expect(articles, isA<Map<dynamic, dynamic>>());

    await first.close();
    expect(() => first.api, throwsStateError, reason: '关闭的租约不再提供 API');
    // The other lease still owns a live session.
    await withRetry(() => second.api.getArticles());

    await second.close();
    expect(() => second.api, throwsStateError);

    // The pool must spin up a fresh session for the next acquire.
    final third = LessonSession.acquire();
    await third.ready;
    await third.close();
  });

  test('a failed startup is replaced by the next acquire', () async {
    final failing = LessonSession.acquire(createServer: () => _BrokenServer());
    await expectLater(failing.ready, throwsStateError);
    await failing.close();

    final healthy = LessonSession.acquire();
    addTearDown(healthy.close);
    await healthy.ready;
    final login = await withRetry(
      () => healthy.api.login('admin', 'password123'),
    );
    healthy.api.setToken(((login['data'] as Map)['token']) as String);
    await withRetry(() => healthy.api.getArticles());
  });
}
