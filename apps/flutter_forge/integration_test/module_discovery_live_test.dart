import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_forge_app/app/module_discovery_session.dart';
import 'package:flutter_forge_app/app/module_discovery_panel.dart';
import 'package:flutter_forge_app/module_registry/module_manifest.dart';
import 'package:flutter_forge_app/module_registry/app_platform_snapshot.dart';
import 'package:flutter_forge_app/shared/genui/model_source.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const enabled = bool.fromEnvironment('DISCOVERY_LIVE');
  const token = String.fromEnvironment('DISCOVERY_TOKEN');
  testWidgets('live intent, SDK clarification and local module navigation', (
    tester,
  ) async {
    var opened = '';
    late final GoRouter router;
    final session = ModuleDiscoverySession(
      modules: moduleManifest,
      platform: const AppPlatformSnapshot(platform: AppTargetPlatform.macOS),
      openModule: (path) {
        opened = path;
        router.go(path);
      },
      source: OpenAiWorkbenchSource(
        endpoint: Uri.parse('http://127.0.0.1:8766/v1/chat/completions'),
        model: 'codex-default',
        token: token,
      ),
    );
    router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: ModuleDiscoveryPanel(
                  modules: moduleManifest,
                  platform: session.platform,
                  session: session,
                ),
              ),
            ),
          ),
        ),
        for (final module in moduleManifest)
          GoRoute(
            path: module.path,
            builder: (context, _) => module.builder(context),
          ),
      ],
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.runAsync(
      () => session.submit(
        '我想学习 Flutter 异步任务为什么会卡界面。请推荐最多两个真实模块，使用 compare 分组，并提供一个 RefineChoice 让我选择偏好。',
      ),
    );
    expect(session.error, isNull);
    await tester.pumpAndSettle();
    expect(
      session.components.values.any((n) => n['component'] == 'ModuleCard'),
      isTrue,
    );
    final choice =
        session.components.values.firstWhere(
              (n) => n['component'] == 'RefineChoice',
            )['label']
            as String;
    await tester.ensureVisible(find.text(choice));
    await tester.pumpAndSettle();
    final choiceButton = tester.widget<OutlinedButton>(
      find.ancestor(
        of: find.text(choice),
        matching: find.byType(OutlinedButton),
      ),
    );
    choiceButton.onPressed!();
    await tester.pump();
    await tester.runAsync(() async {
      for (var i = 0; i < 220; i++) {
        if (session.records.where((r) => r.startsWith('请求：')).length >= 2 &&
            !session.busy) {
          return;
        }
        await Future<void>.delayed(const Duration(milliseconds: 500));
      }
    });
    expect(session.error, isNull);
    expect(session.records.any((r) => r.startsWith('SDK 澄清动作')), isTrue);
    await tester.pumpAndSettle();
    final open = find.text('进入模块').first;
    await tester.ensureVisible(open);
    await tester.pumpAndSettle();
    final count = session.records.where((r) => r.startsWith('请求：')).length;
    final openButton = tester.widget<FilledButton>(
      find.ancestor(of: open, matching: find.byType(FilledButton)),
    );
    openButton.onPressed!();
    await tester.pumpAndSettle();
    expect(moduleManifest.any((m) => m.path == opened), isTrue);
    expect(router.routeInformationProvider.value.uri.path, opened);
    expect(find.byKey(const ValueKey('discovery-question')), findsNothing);
    expect(session.records.where((r) => r.startsWith('请求：')).length, count);
    debugPrint(
      'DISCOVERY_LIVE_PASS requests=$count opened=$opened components=${session.components.length}',
    );
    await tester.pumpWidget(const SizedBox());
    session.dispose();
    router.dispose();
  }, skip: !enabled);
}
