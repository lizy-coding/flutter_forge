import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_forge_app/modules/ui/genui_workbench/genui_session.dart';
import 'package:flutter_forge_app/modules/ui/genui_workbench/genui_workbench_page.dart';

/// macOS AX 语义压力浸泡：ensureSemantics 会像 VoiceOver 等 AX 客户端一样
/// 打开引擎语义管线，真实 embedder 的 AccessibilityBridge 随每帧提交更新。
/// 用固定回放驱动多轮流式重建，验证该路径不再出现 SIGSEGV
/// （docs/reports/MACOS_AX_BRIDGE_CRASH-20261025.md，上游 flutter#193588）。
/// 运行：flutter test integration_test/genui_ax_soak_test.dart -d macos
///       --dart-define=FORGE_AX_SOAK=true
/// 轮数可用 FORGE_AX_SOAK_ROUNDS 覆盖（默认 24）。
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const enabled = bool.fromEnvironment('FORGE_AX_SOAK');
  const rounds = int.fromEnvironment('FORGE_AX_SOAK_ROUNDS', defaultValue: 24);
  testWidgets(
    'AX semantics soak survives replay streaming churn',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final session = GenuiSession();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: GenuiWorkbenchPage(session: session)),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('观察生成过程'));
      await tester.pumpAndSettle();

      final prompts = <String>['为什么设置宽度却没有生效？', '换成紧约束看看', '换成松约束看看'];
      var submitted = 0;
      for (var round = 0; round < rounds; round++) {
        await tester.runAsync(() => session.submit(prompts[round % 3]));
        submitted++;
        await tester.pumpAndSettle();
        expect(
          session.error,
          isNull,
          reason: 'round $round: ${session.records.join('\n')}',
        );
        expect(session.hasExperiment, isTrue);
        session.updateParameter('requestedWidth', 60.0 + 60.0 * (round % 5));
        await tester.pumpAndSettle();
        expect(session.observationReady, isTrue, reason: 'round $round');
        if (round % 4 == 3) {
          await tester.runAsync(() => session.submit('解释当前结果'));
          submitted++;
          await tester.pumpAndSettle();
          expect(session.error, isNull, reason: 'explain after round $round');
        }
        if (round % 40 == 39) {
          debugPrint('AX_SOAK_PROGRESS:${jsonEncode({'round': round})}');
        }
      }
      expect(session.hasExperiment, isTrue);
      expect(session.observationReady, isTrue);
      expect(session.records, isNotEmpty);
      debugPrint(
        'AX_SOAK_RESULT:${jsonEncode({'rounds': rounds, 'submitted': submitted, 'revision': session.revision, 'records': session.records.length, 'surfaceIds': session.controller.activeSurfaceIds.toList()})}',
      );
      await tester.pumpWidget(const SizedBox.shrink());
      session.dispose();
      semantics.dispose();
    },
    skip: !enabled,
    timeout: const Timeout(Duration(minutes: 20)),
  );
}
