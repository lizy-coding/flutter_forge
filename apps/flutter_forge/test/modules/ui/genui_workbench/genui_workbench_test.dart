import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';
import 'package:flutter_forge_app/modules/ui/genui_workbench/genui_session.dart';
import 'package:flutter_forge_app/modules/ui/genui_workbench/genui_workbench_page.dart';
import 'package:flutter_forge_app/modules/ui/genui_workbench/workbench_protocol.dart';
import 'package:flutter_forge_app/modules/ui/genui_workbench/workbench_source.dart';

class ControlledSource implements WorkbenchSource {
  final streams = <StreamController<String>>[];
  final requests = <WorkbenchRequest>[];
  @override
  String get label => '测试传输';
  @override
  bool get isReplay => false;
  @override
  Stream<String> generate(WorkbenchRequest request, CancelToken cancelToken) {
    requests.add(request);
    final stream = StreamController<String>();
    streams.add(stream);
    return stream.stream;
  }

  @override
  void dispose() {}
}

void main() {
  test(
    'replay uses official parser and preserves parameters across follow-ups',
    () async {
      final session = GenuiSession();
      addTearDown(session.dispose);
      await session.submit('为什么设置宽度却没有生效？');
      expect(session.error, isNull);
      expect(session.hasSurface, isTrue);
      expect(
        session.controller
            .contextFor(workbenchSurfaceId)
            .definition
            .value!
            .components,
        contains('preview'),
      );
      session.updateParameter('requestedWidth', 190.0);
      session.observe(session.revision, 190, 60);
      await session.submit('换成紧约束看看');
      expect(session.error, isNull);
      expect(session.value('tight'), isTrue);
      expect(session.value('requestedWidth'), 190.0);
      expect(session.observationReady, isFalse);
      session.observe(session.revision, 240, 60);
      await session.submit('解释当前结果');
      expect(session.error, isNull);
      expect(session.explanationRevision, session.revision);
      session.updateParameter('parentWidth', 210);
      expect(session.explanationStale, isTrue);
      expect(
        () => session.updateParameter('parentWidth', double.infinity),
        throwsFormatException,
      );
      expect(
        () => session.updateParameter('arbitrary', 80),
        throwsFormatException,
      );
      session.reset();
      expect(session.hasSurface, isFalse);
      expect(session.records, isEmpty);
    },
  );

  test(
    'reset ignores delayed response; new request and disposal are independent',
    () async {
      final source = ControlledSource();
      final session = GenuiSession(source: source);
      final old = session.submit('first');
      session.reset();
      final current = session.submit('second');
      for (final message in initialMessages()) {
        source.streams[0].add('${jsonEncode(message)}\n');
        source.streams[1].add('${jsonEncode(message)}\n');
      }
      await source.streams[0].close();
      await source.streams[1].close();
      await Future.wait([old, current]);
      expect(session.hasSurface, isTrue);
      expect(session.lastPrompt, 'second');
      session.observe(session.revision, 120, 60);
      final pending = session.submit('third');
      session.dispose();
      source.streams.last.add('${jsonEncode(initialMessages().first)}\n');
      await source.streams.last.close();
      await pending;
    },
  );

  test(
    'cyclic references, unknown components and invalid state are rejected',
    () {
      expect(
        () => validateComponents([
          {
            'id': 'root',
            'component': 'LabColumn',
            'children': ['root'],
          },
        ], {}),
        throwsFormatException,
      );
      expect(
        () => validateComponents([
          {'id': 'root', 'component': 'WebView'},
        ], {}),
        throwsFormatException,
      );
      expect(
        () => validateComponents([
          {
            'id': 'root',
            'component': 'LabColumn',
            'children': ['missing'],
          },
        ], {}),
        throwsFormatException,
      );
      expect(
        () => validateExperimentValue('tight', 'yes'),
        throwsFormatException,
      );
    },
  );

  test('malformed versioned messages are caught by the SDK parser', () async {
    final source = ControlledSource();
    final session = GenuiSession(source: source);
    final pending = session.submit('generate');
    source.streams.single.add('{"version":"v0.8","createSurface":{}}');
    await source.streams.single.close();
    await pending;
    expect(session.error, isNotNull);
    expect(session.hasSurface, isFalse);
    expect(session.busy, isFalse);
    session.dispose();
  });

  testWidgets(
    'SDK Surface renders real layout and generated action returns current snapshot',
    (tester) async {
      final session = GenuiSession();
      await tester.runAsync(() => session.submit('为什么设置宽度却没有生效？'));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ColoredBox(
              color: Colors.white,
              child: GenuiWorkbenchPage(session: session),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(Surface), findsOneWidget);
      expect(session.actualWidth, 120);
      final slider = tester.widget<Slider>(
        find.byKey(const ValueKey('genui-requestedWidth')),
      );
      slider.onChanged!(280);
      await tester.pumpAndSettle();
      expect(session.actualWidth, 240);
      final explain = find.text('解释当前结果');
      await tester.ensureVisible(explain);
      await tester.tap(explain);
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 30)),
      );
      for (var i = 0; i < 20 && session.busy; i++) {
        await tester.pump(const Duration(milliseconds: 10));
      }
      expect(
        session.busy,
        isFalse,
        reason: '${session.error}\n${session.records.join('\n')}',
      );
      await tester.pumpAndSettle();
      expect(session.error, isNull);
      expect(
        session.records.any(
          (record) =>
              record.startsWith('事件') &&
              record.contains('"requestedWidth":280.0') &&
              record.contains('"actualWidth":240.0'),
        ),
        isTrue,
      );
      expect(session.explanationRevision, session.revision);
      await tester.pumpWidget(const SizedBox.shrink());
      session.dispose();
    },
  );

  testWidgets('360dp and large text can reach controls without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final session = GenuiSession();
    await tester.runAsync(() => session.submit('换成紧约束看看'));
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.5)),
          child: child!,
        ),
        home: Scaffold(body: GenuiWorkbenchPage(session: session)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('解释当前结果'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(session.actualWidth, 240);
    await tester.pumpWidget(const SizedBox.shrink());
    session.dispose();
  });
}
