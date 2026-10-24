import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_forge_app/shared/table/scroll_table.dart';
import 'package:flutter_forge_app/shared/workflows/hub_client.dart';
import 'package:flutter_forge_app/modules/ui/workflow_workbench/workflow_page.dart';
import 'package:flutter_forge_app/modules/ui/workflow_workbench/workflow_session.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const enabled = bool.fromEnvironment('WORKFLOW_E2E');
  const token = String.fromEnvironment('WORKFLOW_HUB_TOKEN');
  testWidgets(
    'Hub and Forge share success, failure, retry and remote cancellation',
    (tester) async {
      expect(token, isNotEmpty);
      final endpoint = Uri.parse('http://127.0.0.1:8768');
      final session = WorkflowSession(
        executorId: 'forge-e2e-${DateTime.now().microsecondsSinceEpoch}',
      );
      final admin = WorkflowHubClient(endpoint: endpoint, token: token);
      final evidence = <Map<String, dynamic>>[];
      await tester.runAsync(
        () => session.connect(
          WorkflowHubClient(endpoint: endpoint, token: token),
        ),
      );
      expect(session.error, isNull);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: WorkflowPage(session: session)),
        ),
      );
      await tester.pumpAndSettle();
      Future<void> waitFor(String state) async {
        await tester.runAsync(() async {
          for (var i = 0; i < 150; i++) {
            if (session.state == state &&
                (state == 'running' || !session.busy)) {
              return;
            }
            await Future<void>.delayed(const Duration(milliseconds: 100));
          }
        });
        expect(
          session.state,
          state,
          reason: '${session.error} ${jsonEncode(session.current)}',
        );
        if (state == 'running') {
          await tester.pump();
        } else {
          await tester.pumpAndSettle();
        }
      }

      session.parameter('query', 'admin');
      session.parameter('delayMs', 0);
      await tester.runAsync(session.submit);
      await waitFor('succeeded');
      expect(find.byType(ScrollTable), findsOneWidget);
      expect((session.current!['result'] as Map)['rows'], hasLength(5));
      evidence.add(Map.of(session.current!));

      // This run is submitted outside the Forge session; polling must claim it.
      final external = await tester.runAsync(
        () => admin.create(
          session.executorId,
          'external',
          session.definition!,
          {...session.inputs, 'query': '标题 1'},
        ),
      );
      await tester.runAsync(() async {
        for (var i = 0; i < 150; i++) {
          if (session.current?['id'] == external!['id'] &&
              session.state == 'succeeded') {
            return;
          }
          await Future<void>.delayed(const Duration(milliseconds: 100));
        }
      });
      expect(session.current!['id'], external!['id']);
      expect(session.state, 'succeeded');
      evidence.add(Map.of(session.current!));

      session.parameter('simulateFailure', true);
      await tester.runAsync(session.submit);
      await waitFor('failed');
      final failedId = session.current!['id'];
      evidence.add(Map.of(session.current!));
      session.parameter('simulateFailure', false);
      await tester.runAsync(session.submit);
      await waitFor('succeeded');
      expect(session.current!['retryOf'], failedId);
      expect(
        (await tester.runAsync(() => admin.run(failedId as String)))!['state'],
        'failed',
      );
      evidence.add(Map.of(session.current!));

      session.parameter('delayMs', 4000);
      await tester.runAsync(session.submit);
      await waitFor('running');
      final cancelledId = session.current!['id'] as String;
      final cancelResponse = await tester.runAsync(
        () => admin.cancel(cancelledId),
      );
      expect(cancelResponse!['state'], 'cancelling');
      await waitFor('cancelled');
      evidence.add(Map.of(session.current!));
      expect(
        session.current!['events'].where(
          (e) => e['kind'] == 'step_started' && e['stepId'] == 'organize',
        ),
        isEmpty,
      );
      debugPrint(
        'WORKFLOW_E2E_RESULT:${jsonEncode({'executorId': session.executorId, 'runs': evidence})}',
      );
      await tester.pumpWidget(const SizedBox.shrink());
      session.dispose();
      admin.close();
    },
    skip: !enabled,
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
