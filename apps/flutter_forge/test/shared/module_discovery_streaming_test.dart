import 'dart:convert';
import 'dart:io';

import 'package:flutter_forge_app/app/module_discovery_session.dart';
import 'package:flutter_forge_app/module_registry/app_platform_snapshot.dart';
import 'package:flutter_forge_app/module_registry/module_manifest.dart';
import 'package:flutter_forge_app/shared/genui/model_source.dart';
import 'package:flutter_test/flutter_test.dart';

// Streaming delivery contract over a real loopback SSE server: the client
// pipeline must accept fragmented content chunks and SSE comment keepalives
// with zero client changes, and must demand the terminal [DONE] marker.
// Real event loop on purpose — FakeAsync can leave async* replay streams
// unclosed (see GENUI_MODULE_DISCOVERY-P0P1-20261024).
void main() {
  late HttpServer server;

  setUp(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  });

  tearDown(() async {
    await server.close(force: true);
  });

  String endpoint() => 'http://127.0.0.1:${server.port}/v1/chat/completions';

  void serveSse(Future<void> Function(HttpResponse response) script) {
    server.listen((request) async {
      final response = request.response;
      response.bufferOutput = false;
      response.headers.contentType = ContentType(
        'text',
        'event-stream',
        charset: 'utf-8',
      );
      await script(response);
      await response.close();
    });
  }

  Future<void> sendComment(HttpResponse response, {int count = 2}) async {
    for (var i = 0; i < count; i++) {
      response.write(': keepalive\n\n');
      await response.flush();
      await Future<void>.delayed(const Duration(milliseconds: 15));
    }
  }

  Future<void> sendDelta(HttpResponse response, String content) async {
    final event = jsonEncode({
      'choices': [
        {
          'delta': {'content': content},
        },
      ],
    });
    response.write('data: $event\n\n');
    await response.flush();
  }

  const firstMessage =
      '{"version":"v0.9","createSurface":{"surfaceId":"module-discovery","catalogId":"dev.flutterforge.module-menu"}}';
  const secondMessage =
      '{"version":"v0.9","updateComponents":{"surfaceId":"module-discovery","components":['
      '{"id":"root","component":"Group","layout":"list","children":["card"]},'
      '{"id":"card","component":"ModuleCard","moduleId":"/constraint-layout","reason":"观察约束如何影响尺寸"}]}}';

  Future<ModuleDiscoverySession> newSession() async {
    final session = ModuleDiscoverySession(
      modules: moduleManifest,
      platform: const AppPlatformSnapshot(platform: AppTargetPlatform.macOS),
      openModule: (_) {},
      source: OpenAiWorkbenchSource(
        endpoint: Uri.parse(endpoint()),
        model: 'test-model',
        token: 'bridge-token',
      ),
    );
    addTearDown(session.dispose);
    return session;
  }

  test(
    'fragmented deltas and keepalive comments render the full surface',
    () async {
      serveSse((response) async {
        await sendComment(response);
        const payload = '$firstMessage\n$secondMessage\n';
        // Deliver one JSON protocol stream as many tiny content fragments the
        // way an incremental transport would.
        for (var i = 0; i < payload.length; i += 24) {
          await sendDelta(
            response,
            payload.substring(
              i,
              i + 24 > payload.length ? payload.length : i + 24,
            ),
          );
          await Future<void>.delayed(const Duration(milliseconds: 2));
        }
        await sendComment(response, count: 1);
        response.write('data: [DONE]\n\n');
        await response.flush();
      });
      final session = await newSession();
      await session.submit('推荐一个布局模块');
      expect(session.error, isNull);
      expect(session.hasSurface, isTrue);
      expect(session.components['root']?['component'], 'Group');
      expect(session.components['card']?['moduleId'], '/constraint-layout');
    },
  );

  test('a stream without the terminal DONE marker fails loudly', () async {
    serveSse((response) async {
      await sendDelta(response, '$firstMessage\n');
      // No [DONE]: the connection just dies.
    });
    final session = await newSession();
    await session.submit('推荐一个布局模块');
    expect(session.error, '流式响应未完整结束，请重试。');
  });

  test('invalid tail over the wire keeps the applied prefix', () async {
    serveSse((response) async {
      await sendDelta(response, '$firstMessage\n$secondMessage\n');
      await sendDelta(response, '这不是协议文本');
      response.write('data: [DONE]\n\n');
      await response.flush();
    });
    final session = await newSession();
    await session.submit('推荐一个布局模块');
    expect(session.error, '响应不是完整的界面协议');
    expect(session.hasSurface, isTrue);
    expect(session.components['card']?['moduleId'], '/constraint-layout');
  });
}
