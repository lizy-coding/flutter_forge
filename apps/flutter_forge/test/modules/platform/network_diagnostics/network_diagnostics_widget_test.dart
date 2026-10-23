import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_forge_app/modules/platform/network_diagnostics/diagnostic_models.dart';
import 'package:flutter_forge_app/modules/platform/network_diagnostics/module_entry.dart';
import 'package:flutter_test/flutter_test.dart';

import 'diagnostic_session_test.dart' show FakeProbe, sample;

void main() {
  testWidgets(
    'compact tool runs only on request, expands evidence and copies the redacted preview',
    (tester) async {
      tester.view.physicalSize = const Size(420, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final probe = FakeProbe();
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await tester.pumpWidget(
        MaterialApp(home: NetworkDiagnosticsEntry(probe: probe)),
      );
      expect(probe.calls, 0);
      await tester.enterText(
        find.byKey(const Key('diagnostic-targets')),
        'https://private.example/secret-path',
      );
      await tester.ensureVisible(find.byKey(const Key('diagnostic-start')));
      await tester.tap(find.byKey(const Key('diagnostic-start')));
      await tester.pumpAndSettle();
      expect(probe.calls, 1);
      expect(find.text('检测完成'), findsOneWidget);
      await tester.ensureVisible(find.text('展开检测证据'));
      await tester.tap(find.text('展开检测证据'));
      await tester.pumpAndSettle();
      expect(find.textContaining('解析地址：10.99.8.7'), findsOneWidget);
      await tester.ensureVisible(find.text('预览／复制报告'));
      await tester.tap(find.text('预览／复制报告'));
      await tester.pumpAndSettle();
      final preview = tester
          .widget<SelectableText>(
            find.byKey(const Key('diagnostic-report-preview')),
          )
          .data!;
      expect(preview, isNot(contains('private.example')));
      expect(preview, isNot(contains('192.168.7.9')));
      await tester.tap(find.text('复制报告'));
      await tester.pumpAndSettle();
      expect(copied, preview);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'invalid input makes no requests; cancel then retry stays interactive',
    (tester) async {
      final pending = Completer<ProbeSample>();
      final probe = FakeProbe()..action = (_, _) => pending.future;
      await tester.pumpWidget(
        MaterialApp(home: NetworkDiagnosticsEntry(probe: probe)),
      );
      await tester.enterText(
        find.byKey(const Key('diagnostic-targets')),
        'https://user:secret@example.com',
      );
      await tester.tap(find.byKey(const Key('diagnostic-start')));
      await tester.pump();
      expect(find.textContaining('不包含账号'), findsOneWidget);
      expect(probe.calls, 0);
      await tester.enterText(
        find.byKey(const Key('diagnostic-targets')),
        'https://example.com',
      );
      await tester.tap(find.byKey(const Key('diagnostic-start')));
      await tester.pump();
      expect(find.text('取消检测'), findsOneWidget);
      await tester.tap(find.text('取消检测'));
      await tester.pumpAndSettle();
      expect(find.text('已取消，保留已完成观测'), findsOneWidget);
      probe.action = null;
      await tester.tap(find.byKey(const Key('diagnostic-start')));
      await tester.pumpAndSettle();
      pending.complete(
        sample(DiagnosticTarget.parseLines('https://example.com').single, 1),
      );
      await tester.pump();
      expect(find.text('检测完成'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
