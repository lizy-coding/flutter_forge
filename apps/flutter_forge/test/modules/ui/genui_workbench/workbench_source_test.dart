import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_forge_app/modules/ui/genui_workbench/genui_session.dart';
import 'package:flutter_forge_app/modules/ui/genui_workbench/workbench_protocol.dart';
import 'package:flutter_forge_app/modules/ui/genui_workbench/workbench_source.dart';

class FakeAdapter implements HttpClientAdapter {
  FakeAdapter(this.body, {this.status = 200});
  final String body;
  final int status;
  RequestOptions? request;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    request = options;
    final bytes = utf8.encode(body);
    return ResponseBody(
      Stream.fromIterable([
        for (var i = 0; i < bytes.length; i += 7)
          Uint8List.fromList(
            bytes.sublist(i, i + 7 > bytes.length ? bytes.length : i + 7),
          ),
      ]),
      status,
      headers: {
        'content-type': ['text/event-stream'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

WorkbenchRequest request() => const WorkbenchRequest(
  prompt: '解释当前结果',
  snapshot: {'actualWidth': 120},
  components: [],
  systemPrompt: 'catalog',
);

void main() {
  test('HTTP authentication and bridge errors expose no credentials', () async {
    for (final status in [401, 502]) {
      final session = GenuiSession(
        source: OpenAiWorkbenchSource(
          endpoint: Uri.parse('https://example.invalid/v1/chat/completions'),
          model: 'test',
          token: 'never-log-this-token',
          dio: Dio()..httpClientAdapter = FakeAdapter('', status: status),
        ),
      );
      await session.submit('公开约束问题');
      expect(session.error, contains(status == 401 ? '拒绝认证' : 'Codex 调用失败'));
      expect(session.records.join(), isNot(contains('never-log-this-token')));
      session.dispose();
    }
  });
  test(
    'SSE survives split UTF-8 bytes and includes snapshot without recording credentials',
    () async {
      final event = jsonEncode({
        'choices': [
          {
            'delta': {'content': '约束消息'},
          },
        ],
      });
      final adapter = FakeAdapter('data: $event\n\ndata: [DONE]\n\n');
      final source = OpenAiWorkbenchSource(
        endpoint: Uri.parse('https://example.invalid/v1/chat/completions'),
        model: 'test-model',
        token: 'test-token',
        dio: Dio()..httpClientAdapter = adapter,
      );
      expect(await source.generate(request(), CancelToken()).join(), '约束消息');
      expect(adapter.request!.headers['Authorization'], 'Bearer test-token');
      final body = adapter.request!.data as Map;
      expect(jsonEncode(body), contains('actualWidth'));
      expect(jsonEncode(body), isNot(contains('test-token')));
      source.dispose();
    },
  );

  test(
    'incomplete SSE and partial A2UI are errors, never replay success',
    () async {
      final source = OpenAiWorkbenchSource(
        endpoint: Uri.parse('http://127.0.0.1:8766/v1/chat/completions'),
        model: 'test',
        token: '',
        dio: Dio()..httpClientAdapter = FakeAdapter('data: {"choices":[]}\n\n'),
      );
      await expectLater(
        source.generate(request(), CancelToken()).drain<void>(),
        throwsFormatException,
      );
      source.dispose();
      final session = GenuiSession(source: _BrokenSource());
      await session.submit('first');
      expect(session.error, isNotNull);
      expect(session.isReplay, isFalse);
      // A failed response may have created a surface without a preview; retry
      // must remain possible rather than waiting forever for an absent layout.
      await session.submit('retry');
      expect(session.lastPrompt, 'retry');
      expect(session.busy, isFalse);
      session.dispose();
    },
  );
}

class _BrokenSource implements WorkbenchSource {
  @override
  String get label => 'broken';
  @override
  bool get isReplay => false;
  @override
  Stream<String> generate(
    WorkbenchRequest request,
    CancelToken cancelToken,
  ) async* {
    yield '${jsonEncode(initialMessages().first)}\n';
    yield '{"version":"v0.9","updateComponents":';
  }

  @override
  void dispose() {}
}
