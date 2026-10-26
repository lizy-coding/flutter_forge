import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_forge_app/app/module_discovery_panel.dart';
import 'package:flutter_forge_app/app/module_discovery_replay.dart';
import 'package:flutter_forge_app/app/module_discovery_session.dart';
import 'package:flutter_forge_app/module_registry/app_platform_snapshot.dart';
import 'package:flutter_forge_app/module_registry/module_manifest.dart';
import 'package:flutter_forge_app/shared/genui/model_source.dart';

Map<String, Object?> env(String operation, Map<String, Object?> body) => {
  'version': 'v0.9',
  operation: {'surfaceId': discoverySurface, ...body},
};

Map<String, Object?> createMessage() =>
    env('createSurface', {'catalogId': discoveryCatalog});

Map<String, Object?> updateMessage(List<Map<String, Object?>> components) =>
    env('updateComponents', {'components': components});

class ScriptedSource implements WorkbenchSource {
  ScriptedSource(this.scenes);
  final List<List<Map<String, Object?>>> scenes;
  int calls = 0;

  @override
  String get label => 'scripted';
  @override
  bool get isReplay => false;
  @override
  void dispose() {}

  @override
  Stream<String> generate(
    WorkbenchRequest request,
    CancelToken cancelToken,
  ) async* {
    final index = calls < scenes.length ? calls : scenes.length - 1;
    calls++;
    for (final message in scenes[index]) {
      yield '${jsonEncode(message)}\n';
    }
  }
}

Future<void> settle(WidgetTester tester, ModuleDiscoverySession session) async {
  await tester.runAsync(() async {
    for (var i = 0; i < 300 && session.busy; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
  });
  await tester.pumpAndSettle();
}

Future<void> pumpUntilFound(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 50 && finder.evaluate().isEmpty; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  await tester.pumpAndSettle();
}

Widget host(Widget child) => MaterialApp(
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

const macOSPlatform = AppPlatformSnapshot(platform: AppTargetPlatform.macOS);

void main() {
  testWidgets('local filter narrows composite entries and restores them', (
    tester,
  ) async {
    final source = ScriptedSource([
      [
        createMessage(),
        updateMessage([
          {
            'id': 'root',
            'component': 'Group',
            'children': ['compare', 'path', 'recent', 'choice'],
          },
          {
            'id': 'compare',
            'component': 'CompareTable',
            'moduleIds': ['/microtask', '/isolate-basic', '/constraint-layout'],
            'focus': '比较执行位置',
          },
          {
            'id': 'path',
            'component': 'LearningPath',
            'steps': [
              {'moduleId': '/microtask', 'goal': '理解事件队列'},
              {'moduleId': '/isolate-basic', 'goal': '比较并发'},
              {'moduleId': '/constraint-layout', 'goal': '理解约束'},
            ],
          },
          {'id': 'recent', 'component': 'RecentHint'},
          {
            'id': 'choice',
            'component': 'RefineChoice',
            'label': '只看基础',
            'filter': {'by': 'category', 'value': '基础机制'},
          },
        ]),
      ],
    ]);
    final session = ModuleDiscoverySession(
      modules: moduleManifest,
      platform: macOSPlatform,
      recentPaths: const ['/isolate-basic', '/microtask', '/constraint-layout'],
      openModule: (_) {},
      source: source,
    );
    await tester.pumpWidget(
      host(
        ModuleDiscoveryPanel(
          modules: moduleManifest,
          platform: macOSPlatform,
          session: session,
        ),
      ),
    );
    await tester.runAsync(() => session.submit('异步'));
    await settle(tester, session);
    final original = jsonEncode(session.components);
    await tester.ensureVisible(find.text('只看基础'));
    await tester.tap(find.text('只看基础'));
    await tester.pumpAndSettle();
    expect(session.error, isNull);
    expect(session.components['compare']!['moduleIds'], [
      '/microtask',
      '/constraint-layout',
    ]);
    expect((session.components['path']!['steps'] as List).length, 2);
    expect(find.text('Isolate 并发对比'), findsNothing);

    session.applyLocalFilter(by: 'concept', value: 'Microtask', label: '微任务');
    await tester.pumpAndSettle();
    for (final id in ['compare', 'path']) {
      expect(session.components[id]!['component'], 'ModuleCard');
      expect(session.components[id]!['moduleId'], '/microtask');
    }
    expect(session.components['path']!['reason'], '理解事件队列');
    expect(session.components['recent']!['moduleIds'], ['/microtask']);
    expect(find.text('Isolate 并发对比'), findsNothing);
    expect(find.text('事件循环与微任务'), findsNWidgets(3));
    expect(source.calls, 1);
    expect(tester.takeException(), isNull);
    session.clearLocalFilter();
    await tester.pumpAndSettle();
    expect(jsonEncode(session.components), original);
    expect(find.text('Isolate 并发对比'), findsNWidgets(3));
    expect(source.calls, 1);
    await tester.pumpWidget(const SizedBox());
    session.dispose();
  });

  for (final (question, difficulty, retainedPath) in [
    ('网络诊断', '进阶', '/dio-interceptor'),
    ('异步卡界面', '入门', '/microtask'),
  ]) {
    testWidgets('replay $question filters by the difficulty in its button', (
      tester,
    ) async {
      final session = ModuleDiscoverySession(
        modules: moduleManifest,
        platform: macOSPlatform,
        openModule: (_) {},
        source: ReplayDiscoverySource(
          modules: moduleManifest,
          platform: macOSPlatform,
        ),
      );
      await tester.pumpWidget(
        host(
          ModuleDiscoveryPanel(
            modules: moduleManifest,
            platform: macOSPlatform,
            session: session,
          ),
        ),
      );
      await tester.runAsync(() => session.submit(question));
      await settle(tester, session);
      final label = '只看$difficulty难度（本地执行）';
      await tester.ensureVisible(find.text(label));
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      expect(session.error, isNull);
      expect(session.localFilterLabel, label);
      final cards = session.components.values.where(
        (node) => node['component'] == 'ModuleCard',
      );
      expect(cards, isNotEmpty);
      expect(cards.map((node) => node['moduleId']), everyElement(retainedPath));
      expect(
        session.records.where((record) => record.startsWith('请求：')).length,
        1,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      session.dispose();
    });
  }

  testWidgets('progressive apply keeps the valid prefix on invalid tail', (
    tester,
  ) async {
    final source = ScriptedSource([
      [
        createMessage(),
        updateMessage([
          {
            'id': 'root',
            'component': 'Group',
            'children': ['note', 'card'],
          },
          {'id': 'note', 'component': 'Note', 'text': '第一条说明'},
          {
            'id': 'card',
            'component': 'ModuleCard',
            'moduleId': '/constraint-layout',
            'reason': '看约束如何决定尺寸',
          },
        ]),
      ],
      [
        updateMessage([
          {'id': 'mystery', 'component': 'Mystery'},
        ]),
      ],
    ]);
    final session = ModuleDiscoverySession(
      modules: moduleManifest,
      platform: macOSPlatform,
      openModule: (_) {},
      source: source,
    );
    await tester.pumpWidget(
      host(
        ModuleDiscoveryPanel(
          modules: moduleManifest,
          platform: macOSPlatform,
          session: session,
        ),
      ),
    );
    await tester.runAsync(() => session.submit('宽度问题'));
    await settle(tester, session);
    expect(session.error, isNull);
    expect(find.text('约束与声明式布局'), findsOneWidget);
    await tester.runAsync(() => session.submit('继续'));
    await settle(tester, session);
    expect(session.error, contains('未知探索组件'));
    expect(session.components.containsKey('card'), isTrue);
    expect(find.text('约束与声明式布局'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    session.dispose();
  });

  testWidgets('local filter narrows cards on-device and clears without calls', (
    tester,
  ) async {
    final source = ScriptedSource([
      [
        createMessage(),
        updateMessage([
          {
            'id': 'root',
            'component': 'Group',
            'children': ['note', 'cardA', 'cardB', 'choice'],
          },
          {'id': 'note', 'component': 'Note', 'text': '两个候选'},
          {
            'id': 'cardA',
            'component': 'ModuleCard',
            'moduleId': '/microtask',
            'reason': '入门的事件循环',
          },
          {
            'id': 'cardB',
            'component': 'ModuleCard',
            'moduleId': '/isolate-basic',
            'reason': '进阶的 Isolate 对比',
          },
          {
            'id': 'choice',
            'component': 'RefineChoice',
            'label': '只看入门难度',
            'filter': {'by': 'difficulty', 'value': '入门'},
          },
        ]),
      ],
    ]);
    final session = ModuleDiscoverySession(
      modules: moduleManifest,
      platform: macOSPlatform,
      openModule: (_) {},
      source: source,
    );
    await tester.pumpWidget(
      host(
        ModuleDiscoveryPanel(
          modules: moduleManifest,
          platform: macOSPlatform,
          session: session,
        ),
      ),
    );
    await tester.runAsync(() => session.submit('异步'));
    await settle(tester, session);
    expect(find.text('事件循环与微任务'), findsOneWidget);
    expect(find.text('Isolate 并发对比'), findsOneWidget);
    await tester.ensureVisible(find.text('只看入门难度'));
    await tester.tap(find.text('只看入门难度'));
    await tester.pumpAndSettle();
    expect(find.text('事件循环与微任务'), findsOneWidget);
    expect(find.text('Isolate 并发对比'), findsNothing);
    expect(source.calls, 1, reason: '本地过滤不得触发模型请求');
    expect(session.records.any((r) => r.contains('本地过滤')), isTrue);
    expect(find.byKey(const ValueKey('discovery-filter-chip')), findsOneWidget);
    await tester.tap(
      find
          .descendant(
            of: find.byKey(const ValueKey('discovery-filter-chip')),
            matching: find.byIcon(Icons.close),
          )
          .first,
    );
    await tester.pumpAndSettle();
    expect(find.text('事件循环与微任务'), findsOneWidget);
    expect(find.text('Isolate 并发对比'), findsOneWidget);
    expect(source.calls, 1);
    expect(find.byKey(const ValueKey('discovery-filter-chip')), findsNothing);
    await tester.pumpWidget(const SizedBox());
    session.dispose();
  });

  testWidgets('local filter without a match keeps the tree and explains', (
    tester,
  ) async {
    final source = ScriptedSource([
      [
        createMessage(),
        updateMessage([
          {
            'id': 'root',
            'component': 'Group',
            'children': ['card', 'note', 'choice', 'recent'],
          },
          {
            'id': 'card',
            'component': 'ModuleCard',
            'moduleId': '/microtask',
            'reason': '入门的事件循环',
          },
          {'id': 'note', 'component': 'Note', 'text': '说明不会作为匹配模块'},
          {'id': 'recent', 'component': 'RecentHint'},
          {
            'id': 'choice',
            'component': 'RefineChoice',
            'label': '只看实战',
            'filter': {'by': 'difficulty', 'value': '实战'},
          },
        ]),
      ],
    ]);
    final session = ModuleDiscoverySession(
      modules: moduleManifest,
      platform: macOSPlatform,
      openModule: (_) {},
      source: source,
    );
    await tester.pumpWidget(
      host(
        ModuleDiscoveryPanel(
          modules: moduleManifest,
          platform: macOSPlatform,
          session: session,
        ),
      ),
    );
    await tester.runAsync(() => session.submit('异步'));
    await settle(tester, session);
    final original = jsonEncode(session.components);
    session.applyLocalFilter(by: 'difficulty', value: '实战', label: '只看实战难度');
    await tester.pumpAndSettle();
    expect(session.error, contains('没有匹配'));
    expect(jsonEncode(session.components), original);
    expect(find.text('事件循环与微任务'), findsOneWidget);
    expect(session.localFilterLabel, isNull);
    expect(find.byKey(const ValueKey('discovery-filter-chip')), findsNothing);
    await tester.pumpWidget(const SizedBox());
    session.dispose();
  });

  testWidgets('compare table, learning path and recent hint work at 360dp', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final source = ScriptedSource([
      [
        createMessage(),
        updateMessage([
          {
            'id': 'root',
            'component': 'Group',
            'children': ['compare', 'path', 'recent'],
          },
          {
            'id': 'compare',
            'component': 'CompareTable',
            'moduleIds': ['/constraint-layout', '/tree-state'],
            'focus': '约束与三棵树',
          },
          {
            'id': 'path',
            'component': 'LearningPath',
            'title': '建议顺序',
            'steps': [
              {'moduleId': '/microtask', 'goal': '先看排队规则'},
              {'moduleId': '/isolate-basic', 'goal': '再对比执行位置'},
            ],
          },
          {'id': 'recent', 'component': 'RecentHint'},
        ]),
      ],
    ]);
    var opened = '';
    final session = ModuleDiscoverySession(
      modules: moduleManifest,
      platform: macOSPlatform,
      recentPaths: const ['/constraint-layout'],
      openModule: (path) => opened = path,
      source: source,
    );
    await tester.pumpWidget(
      host(
        ModuleDiscoveryPanel(
          modules: moduleManifest,
          platform: macOSPlatform,
          session: session,
        ),
      ),
    );
    await tester.runAsync(() => session.submit('宽度与三棵树'));
    await settle(tester, session);
    expect(tester.takeException(), isNull);
    expect(find.text('对比重点：约束与三棵树'), findsOneWidget);
    // Two compare-table columns and two path steps, all supported on macOS.
    expect(find.byTooltip('进入模块'), findsNWidgets(4));
    expect(find.text('建议顺序'), findsOneWidget);
    expect(find.text('继续上次'), findsOneWidget);
    await tester.ensureVisible(find.byTooltip('进入模块').at(2));
    await tester.tap(find.byTooltip('进入模块').at(2));
    expect(opened, '/microtask');
    await tester.ensureVisible(find.text('约束与声明式布局').last);
    await tester.tap(find.text('约束与声明式布局').last);
    expect(opened, '/constraint-layout');
    await tester.pumpWidget(const SizedBox());
    session.dispose();
  });

  test('validation rejects invented references and bad filters', () {
    final session = ModuleDiscoverySession(
      modules: moduleManifest,
      platform: macOSPlatform,
      openModule: (_) {},
    );
    addTearDown(session.dispose);
    expect(
      () => session.validate([
        {
          'id': 'root',
          'component': 'Group',
          'children': ['cmp'],
        },
        {
          'id': 'cmp',
          'component': 'CompareTable',
          'moduleIds': ['/constraint-layout', '/invented'],
        },
      ], {}),
      throwsFormatException,
    );
    expect(
      () => session.validate([
        {
          'id': 'root',
          'component': 'Group',
          'children': ['path'],
        },
        {
          'id': 'path',
          'component': 'LearningPath',
          'steps': [
            {'moduleId': '/invented', 'goal': '第一步'},
            {'moduleId': '/microtask', 'goal': '第二步'},
          ],
        },
      ], {}),
      throwsFormatException,
    );
    expect(
      () => session.validate([
        {
          'id': 'root',
          'component': 'Group',
          'children': ['choice'],
        },
        {
          'id': 'choice',
          'component': 'RefineChoice',
          'label': '按年份',
          'filter': {'by': 'year', 'value': '2026'},
        },
      ], {}),
      throwsFormatException,
    );
  });

  testWidgets('offline replay drives the panel end to end', (tester) async {
    final session = ModuleDiscoverySession(
      modules: moduleManifest,
      platform: macOSPlatform,
      recentPaths: const ['/constraint-layout'],
      openModule: (_) {},
      source: ReplayDiscoverySource(
        modules: moduleManifest,
        platform: macOSPlatform,
      ),
    );
    await tester.pumpWidget(
      host(
        ModuleDiscoveryPanel(
          modules: moduleManifest,
          platform: macOSPlatform,
          session: session,
        ),
      ),
    );
    expect(find.text('固定回放 · 未调用模型'), findsOneWidget);
    // Streams and SDK event delivery settle reliably in a real event loop;
    // wait for busy to rise and fall, then render the result.
    Future<void> realZoneIdle() => tester.runAsync(() async {
      var started = false;
      for (var i = 0; i < 200; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        if (session.busy) started = true;
        if (started && !session.busy) return;
      }
    });

    await tester.enterText(
      find.byKey(const ValueKey('discovery-question')),
      '异步任务为什么会卡界面？',
    );
    await tester.ensureVisible(find.byKey(const ValueKey('discovery-submit')));
    await tester.runAsync(() async {
      await tester.tap(find.byKey(const ValueKey('discovery-submit')));
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('discovery-replay-badge')),
      findsOneWidget,
    );
    expect(find.text('事件循环与微任务'), findsWidgets);
    expect(find.text('Isolate 并发对比'), findsWidgets);
    expect(find.text('继续上次'), findsOneWidget);
    expect(find.text('约束与声明式布局'), findsOneWidget);
    await tester.ensureVisible(find.text('想看网络请求卡住的场景'));
    await tester.tap(find.text('想看网络请求卡住的场景'));
    await tester.pump();
    await realZoneIdle();
    await tester.pumpAndSettle();
    // The partial update is asserted on session state: the fake-async zone of
    // widget tests swallows the SDK surface repaint for updates applied in
    // the subscription zone, which does not happen in a real single-zone run.
    expect(
      (session.components['note']?['text'] as String?) ?? '',
      contains('已收到你的补充偏好'),
    );
    expect(
      session.components.values.where(
        (node) => node['moduleId'] == '/isolate-basic',
      ),
      isNotEmpty,
      reason: '澄清只更新 note，第一轮卡片必须保留',
    );
    // Partial update: cards from the first round survive the clarification.
    expect(find.text('Isolate 并发对比'), findsWidgets);
    await tester.enterText(
      find.byKey(const ValueKey('discovery-question')),
      '随便问点什么',
    );
    await tester.ensureVisible(find.byKey(const ValueKey('discovery-submit')));
    await tester.runAsync(() async {
      await tester.tap(find.byKey(const ValueKey('discovery-submit')));
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pumpAndSettle();
    expect(find.textContaining('回放仅覆盖'), findsOneWidget);
    expect(find.text('Isolate 并发对比'), findsWidgets);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    session.dispose();
  });

  testWidgets('panel without a session defaults to the labelled replay', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        ModuleDiscoveryPanel(
          modules: moduleManifest,
          platform: macOSPlatform,
          recentPaths: const [],
        ),
      ),
    );
    expect(find.text('固定回放 · 未调用模型'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('discovery-question')),
      '为什么设置宽度后没有生效？',
    );
    await tester.runAsync(() async {
      await tester.tap(find.byKey(const ValueKey('discovery-submit')));
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('discovery-replay-badge')),
      findsOneWidget,
    );
    expect(find.textContaining('对比重点'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('android replay recommends only platform-available modules', (
    tester,
  ) async {
    const android = AppPlatformSnapshot(platform: AppTargetPlatform.android);
    final session = ModuleDiscoverySession(
      modules: moduleManifest,
      platform: android,
      openModule: (_) {},
      source: ReplayDiscoverySource(modules: moduleManifest, platform: android),
    );
    await tester.pumpWidget(
      host(
        ModuleDiscoveryPanel(
          modules: moduleManifest,
          platform: android,
          session: session,
        ),
      ),
    );
    await tester.runAsync(() => session.submit('想学习如何判断网络故障'));
    await settle(tester, session);
    expect(session.error, isNull, reason: session.records.join(' | '));
    // /network-diagnostics is excluded on Android: no card, no path step.
    expect(
      session.components.values.where(
        (node) => node['moduleId'] == '/network-diagnostics',
      ),
      isEmpty,
    );
    expect(find.text('Dio 拦截器链路'), findsOneWidget);
    // The path collapsed below two supported steps and degraded to the card.
    expect(find.text('建议顺序'), findsNothing);
    expect(find.text('进入模块'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    session.dispose();
  });

  testWidgets('web replay drops the platform-excluded isolate module', (
    tester,
  ) async {
    const web = AppPlatformSnapshot(platform: AppTargetPlatform.web);
    final session = ModuleDiscoverySession(
      modules: moduleManifest,
      platform: web,
      openModule: (_) {},
      source: ReplayDiscoverySource(modules: moduleManifest, platform: web),
    );
    await tester.pumpWidget(
      host(
        ModuleDiscoveryPanel(
          modules: moduleManifest,
          platform: web,
          session: session,
        ),
      ),
    );
    await tester.runAsync(() => session.submit('异步任务为什么会卡界面？'));
    await settle(tester, session);
    expect(session.error, isNull, reason: session.records.join(' | '));
    expect(
      session.components.values.where(
        (node) => node['moduleId'] == '/isolate-basic',
      ),
      isEmpty,
    );
    expect(find.text('事件循环与微任务'), findsOneWidget);
    expect(find.text('Isolate 并发对比'), findsNothing);
    expect(find.text('建议顺序'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    session.dispose();
  });

  testWidgets('learning path labels excluded steps as platform notices', (
    tester,
  ) async {
    final source = ScriptedSource([
      [
        createMessage(),
        updateMessage([
          {
            'id': 'root',
            'component': 'Group',
            'children': ['path'],
          },
          {
            'id': 'path',
            'component': 'LearningPath',
            'steps': [
              {'moduleId': '/network-diagnostics', 'goal': '先采集证据'},
              {'moduleId': '/dio-interceptor', 'goal': '再学拦截器'},
            ],
          },
        ]),
      ],
    ]);
    final session = ModuleDiscoverySession(
      modules: moduleManifest,
      platform: const AppPlatformSnapshot(platform: AppTargetPlatform.android),
      openModule: (_) {},
      source: source,
    );
    await tester.pumpWidget(
      host(
        ModuleDiscoveryPanel(
          modules: moduleManifest,
          platform: const AppPlatformSnapshot(
            platform: AppTargetPlatform.android,
          ),
          session: session,
        ),
      ),
    );
    await tester.runAsync(() => session.submit('网络排查'));
    await settle(tester, session);
    expect(find.byTooltip('查看平台限制'), findsOneWidget);
    expect(find.byTooltip('进入模块'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    session.dispose();
  });
}
