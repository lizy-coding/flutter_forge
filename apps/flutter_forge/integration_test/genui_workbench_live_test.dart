import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_forge_app/modules/ui/genui_workbench/genui_session.dart';
import 'package:flutter_forge_app/modules/ui/genui_workbench/genui_workbench_page.dart';
import 'package:flutter_forge_app/modules/ui/genui_workbench/workbench_protocol.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const enabled = bool.fromEnvironment('GENUI_LIVE');
  const token = String.fromEnvironment('GENUI_LIVE_TOKEN');
  testWidgets(
    'Codex generates and updates a real GenUI experiment',
    (tester) async {
      expect(
        token,
        isNotEmpty,
        reason: 'Pass a temporary bridge token explicitly.',
      );
      final session = GenuiSession();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: GenuiWorkbenchPage(session: session)),
        ),
      );
      await tester.tap(find.text('连接模型服务'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('genui-service-token')),
        token,
      );
      await tester.tap(find.text('使用此服务'));
      await tester.pumpAndSettle();
      expect(session.isReplay, isFalse);
      await tester.runAsync(() => session.submit('为什么子组件设置了宽度却没有生效？请生成松约束实验。'));
      expect(session.error, isNull);
      await tester.pumpAndSettle();
      expect(find.byType(Surface), findsOneWidget);
      expect(session.hasExperiment, isTrue);
      expect(session.isReplay, isFalse);
      expect(session.observationReady, isTrue);
      session.updateParameter('requestedWidth', 180.0);
      await tester.pumpAndSettle();
      final before = session.snapshot;
      await tester.runAsync(
        () => session.submit('换成紧约束看看，只修改 tight，保留父宽度、期望宽度和其他组件。'),
      );
      expect(session.error, isNull);
      await tester.pumpAndSettle();
      expect(session.value('tight'), isTrue);
      expect(session.value('requestedWidth'), before['requestedWidth']);
      expect(session.value('parentWidth'), before['parentWidth']);
      expect(session.actualWidth, session.value('parentWidth'));
      final explain = find.text('解释当前结果');
      await tester.ensureVisible(explain);
      await tester.pumpAndSettle();
      final explainButton = tester.widget<FilledButton>(
        find.ancestor(of: explain, matching: find.byType(FilledButton)).first,
      );
      expect(
        explainButton.onPressed,
        isNotNull,
        reason: jsonEncode(session.snapshot),
      );
      await tester.tap(explain);
      await tester.pump();
      // onSubmit is asynchronous: wait for both request start and completion.
      // Checking busy before the SDK dispatches the event can skip the wait.
      await tester.runAsync(() async {
        for (var i = 0; i < 210; i++) {
          if (session.lastPrompt == '解释当前结果' && !session.busy) return;
          await Future<void>.delayed(const Duration(milliseconds: 500));
        }
      });
      expect(session.lastPrompt, '解释当前结果');
      expect(session.busy, isFalse);
      expect(session.error, isNull, reason: jsonEncode(session.records));
      await tester.pumpAndSettle();
      expect(session.explanationRevision, session.revision);
      expect(
        session.records.any(
          (record) =>
              record.startsWith('事件') && record.contains('"actualWidth":240.0'),
        ),
        isTrue,
      );
      debugPrint(
        'GENUI_LIVE_RESULT:${jsonEncode({'source': session.sourceLabel, 'before': before, 'after': session.snapshot, 'surface': session.controller.contextFor(workbenchSurfaceId).definition.value!.toJson(), 'records': session.records})}',
      );
      await tester.pumpWidget(const SizedBox.shrink());
      session.dispose();
    },
    skip: !enabled,
    timeout: const Timeout(Duration(minutes: 6)),
  );
}
