import 'dart:async';
import 'dart:convert';

import 'package:a2ui_core/a2ui_core.dart' as a2ui;
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_forge_app/shared/genui/model_source.dart';
import 'package:flutter_forge_app/shared/genui/session_core.dart';

/// Minimal concrete session: records applied messages instead of rendering,
/// so the core's run machinery is exercised without a surface catalog.
class CoreTestSession extends GenuiSessionCore {
  CoreTestSession(
    WorkbenchSource source, {
    super.recordLimit,
    this.silentEmptyPrompt = false,
    this.maxGeneratedChars = 48000,
  }) : _source = source;

  final WorkbenchSource _source;

  @override
  final bool silentEmptyPrompt;
  @override
  final int maxGeneratedChars;

  final applied = <String>[];
  String? startedPrompt;
  String? successPrompt;
  int? successCount;
  int cancelCount = 0;

  @override
  WorkbenchSource get activeSource => _source;

  @override
  String? submitGuard(String prompt) =>
      prompt.isEmpty || prompt.contains('deny') ? 'guard 拒绝了该问题' : null;

  @override
  WorkbenchRequest buildRequest(String prompt) => WorkbenchRequest(
    prompt: prompt,
    snapshot: const {},
    components: const [],
    systemPrompt: 'core-test',
  );

  @override
  void applyStreamMessage(a2ui.A2uiMessage message) {
    if (message is a2ui.UpdateComponentsMessage &&
        message.components.any((component) => component['id'] == 'bad')) {
      throw const FormatException('无效组件');
    }
    applied.add(
      message is a2ui.CreateSurfaceMessage
          ? 'create:${message.catalogId}'
          : 'update:${(message as a2ui.UpdateComponentsMessage).components.length}',
    );
  }

  @override
  String get fallbackError => '兜底错误';

  @override
  void onRunStarted(String prompt) => startedPrompt = prompt;

  @override
  void onSuccess(String prompt, int appliedMessages) {
    successPrompt = prompt;
    successCount = appliedMessages;
  }

  @override
  void onCancelled() => cancelCount++;
}

class ScriptSource implements WorkbenchSource {
  ScriptSource(this.lines);
  final List<String> lines;
  int calls = 0;

  @override
  String get label => 'script';
  @override
  bool get isReplay => true;
  @override
  void dispose() {}

  @override
  Stream<String> generate(WorkbenchRequest request, CancelToken token) async* {
    calls++;
    for (final line in lines) {
      yield line;
    }
  }
}

class HeldSource implements WorkbenchSource {
  final streams = <StreamController<String>>[];

  @override
  String get label => 'held';
  @override
  bool get isReplay => false;
  @override
  void dispose() {}

  @override
  Stream<String> generate(WorkbenchRequest request, CancelToken token) {
    final stream = StreamController<String>();
    streams.add(stream);
    return stream.stream;
  }
}

String envelope(String operation, Map<String, Object?> body) => jsonEncode({
  'version': 'v0.9',
  operation: {'surfaceId': 'core-test', ...body},
});

const createLine =
    '{"version":"v0.9","createSurface":{"surfaceId":"core-test","catalogId":"cat"}}';
String updateLine(int count) => envelope('updateComponents', {
  'components': [
    for (var i = 0; i < count; i++) {'id': 'c$i', 'component': 'Note'},
  ],
});

void main() {
  test(
    'guard rejection reports the message and never opens the stream',
    () async {
      final source = ScriptSource([createLine]);
      final session = CoreTestSession(source);
      addTearDown(session.dispose);
      await session.submit('deny this');
      expect(session.error, 'guard 拒绝了该问题');
      expect(session.busy, isFalse);
      expect(source.calls, 0);
      expect(session.startedPrompt, isNull);
    },
  );

  test('empty prompt is silent only when the session opts in', () async {
    final reporting = CoreTestSession(ScriptSource([createLine]));
    addTearDown(reporting.dispose);
    await reporting.submit('   ');
    expect(reporting.error, 'guard 拒绝了该问题');
    expect(reporting.startedPrompt, isNull);

    final silent = CoreTestSession(
      ScriptSource([createLine]),
      silentEmptyPrompt: true,
    );
    addTearDown(silent.dispose);
    await silent.submit('   ');
    expect(silent.error, isNull);
    expect(silent.startedPrompt, isNull);
  });

  test('whitespace-only response reports the empty-result message', () async {
    final session = CoreTestSession(ScriptSource(['   \n']));
    addTearDown(session.dispose);
    await session.submit('hello');
    expect(session.error, '没有收到推荐界面');
    expect(session.successCount, isNull);
  });

  test('plain text leak reports the protocol error', () async {
    final session = CoreTestSession(ScriptSource(['普通文本\n']));
    addTearDown(session.dispose);
    await session.submit('hello');
    expect(session.error, '响应不是完整的界面协议');
  });

  test('generation budget throws the overflow message', () async {
    final session = CoreTestSession(
      ScriptSource([updateLine(1)]),
      maxGeneratedChars: 50,
    );
    addTearDown(session.dispose);
    await session.submit('hello');
    expect(session.error, '生成内容过长');
    expect(session.applied, isEmpty);
  });

  test(
    'progressive apply keeps earlier messages when the tail is invalid',
    () async {
      final session = CoreTestSession(
        ScriptSource([
          createLine,
          updateLine(1),
          envelope('updateComponents', {
            'components': [
              {'id': 'bad', 'component': 'Note'},
            ],
          }),
        ]),
      );
      addTearDown(session.dispose);
      await session.submit('hello');
      expect(session.error, '无效组件');
      expect(session.applied, ['create:cat', 'update:1']);
      expect(session.successCount, isNull);
      expect(session.busy, isFalse);
    },
  );

  test('onSuccess receives the prompt and applied message count', () async {
    final session = CoreTestSession(ScriptSource([createLine, updateLine(2)]));
    addTearDown(session.dispose);
    await session.submit('  hello  ');
    expect(session.error, isNull);
    expect(session.startedPrompt, 'hello');
    expect(session.successPrompt, 'hello');
    expect(session.successCount, 2);
  });

  test('cancel bumps the epoch so late stream events are dropped', () async {
    final source = HeldSource();
    final session = CoreTestSession(source);
    final pending = session.submit('hello');
    expect(session.busy, isTrue);
    session.cancel();
    expect(session.cancelCount, 1);
    expect(session.busy, isFalse);
    source.streams.single.add(createLine);
    await source.streams.single.close();
    await pending;
    expect(session.applied, isEmpty);
    expect(session.error, isNull);
    session.dispose();
  });

  test('records truncate entries and stay bounded by recordLimit', () async {
    final session = CoreTestSession(ScriptSource([createLine]), recordLimit: 3);
    addTearDown(session.dispose);
    session.addRecord('a' * 5000);
    expect(session.records.single, '${'a' * 4000}…');
    session.addRecord('second');
    session.addRecord('third');
    session.addRecord('fourth');
    expect(session.records.length, 3);
    expect(session.records.first, 'second');
    expect(session.records.last, 'fourth');
  });

  test('non-protocol failures keep the fallback message', () async {
    final session = CoreTestSession(HeldSource());
    addTearDown(session.dispose);
    expect(session.describeError(const FormatException('格式')), '格式');
    expect(
      session.describeError(
        DioException(requestOptions: RequestOptions(path: '/')),
      ),
      '兜底错误',
    );
  });
}
