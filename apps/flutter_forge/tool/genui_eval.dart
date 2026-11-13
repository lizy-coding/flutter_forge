// GenUI module-discovery evaluation harness.
//
// Runs a small fixed prompt set through the real ModuleDiscoverySession
// pipeline (live model source, progressive parse/validate/apply) and checks
// the invariants the system prompt promises. Use it to judge how an actual
// model answers the current prompt before shipping prompt changes:
//
//   GENUI_EVAL_LIVE=1 flutter test tool/genui_eval.dart
//
// Optional overrides: GENUI_EVAL_ENDPOINT, GENUI_EVAL_MODEL, GENUI_EVAL_TOKEN.
// Without GENUI_EVAL_LIVE the run is skipped, so the quality gate stays green.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_forge_app/app/module_discovery_session.dart';
import 'package:flutter_forge_app/module_registry/app_platform_snapshot.dart';
import 'package:flutter_forge_app/module_registry/module_manifest.dart';
import 'package:flutter_forge_app/shared/genui/model_source.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final env = Platform.environment;
  final live = env['GENUI_EVAL_LIVE'] == '1';
  final endpoint =
      env['GENUI_EVAL_ENDPOINT'] ?? 'http://127.0.0.1:8766/v1/chat/completions';
  final model = env['GENUI_EVAL_MODEL'] ?? 'codex-default';
  final token = env['GENUI_EVAL_TOKEN'] ?? '';

  Future<EvalOutcome> runCase(EvalCase test) async {
    final session = ModuleDiscoverySession(
      modules: moduleManifest,
      platform: const AppPlatformSnapshot(platform: AppTargetPlatform.macOS),
      openModule: (_) {},
      recentPaths: test.recentPaths,
      source: OpenAiWorkbenchSource(
        endpoint: Uri.parse(endpoint),
        model: model,
        token: token,
      ),
    );
    final stopwatch = Stopwatch()..start();
    try {
      await session.submit(test.prompt).timeout(const Duration(seconds: 150));
    } finally {
      stopwatch.stop();
    }
    final outcome = EvalOutcome.fromSession(test, session, stopwatch.elapsed);
    session.dispose();
    return outcome;
  }

  group('genui module-discovery evaluation', () {
    for (final evalCase in evalCases) {
      test(
        evalCase.name,
        () async {
          final outcome = await runCase(evalCase);
          // Machine-readable line for diffing prompt revisions against each other.
          debugPrint('GENUI_EVAL|${jsonEncode(outcome.toJson())}');
          expect(outcome.error, isNull, reason: outcome.failureSummary);
          expect(outcome.hasSurface, isTrue, reason: outcome.failureSummary);
          expect(outcome.rootIsGroup, isTrue, reason: outcome.failureSummary);
          expect(
            outcome.moduleCards,
            inInclusiveRange(1, 3),
            reason: '一般推荐 1~3 个模块：${outcome.failureSummary}',
          );
          expect(
            outcome.refineChoices,
            inInclusiveRange(0, 3),
            reason: '澄清选项最多 3 个：${outcome.failureSummary}',
          );
          expect(
            outcome.referencedTitles,
            isNotEmpty,
            reason: '推荐必须引用真实模块：${outcome.failureSummary}',
          );
        },
        // The harness's own 150s case budget only matters if the per-test
        // timeout allows it; flutter's 30s default murders slower models
        // and leaves the bridge slot occupied for the rest of the round.
        timeout: const Timeout(Duration(seconds: 150)),
        skip: live ? false : 'GENUI_EVAL_LIVE=1 才运行（需要本机模型桥接）',
      );
    }
  });
}

class EvalCase {
  const EvalCase(this.name, this.prompt, {this.recentPaths = const []});
  final String name;
  final String prompt;
  final List<String> recentPaths;
}

const evalCases = [
  EvalCase('recommends for a layout question', '我想理解为什么设置宽度不生效，推荐从哪个模块入门？'),
  EvalCase('compares two modules for intent', '想对比两个模块帮我决定先学网络调试还是异步基础'),
  EvalCase(
    'continues from recent history',
    '继续上次的学习',
    recentPaths: ['/constraint-layout'],
  ),
];

class EvalOutcome {
  const EvalOutcome({
    required this.name,
    required this.error,
    required this.hasSurface,
    required this.rootIsGroup,
    required this.appliedMessages,
    required this.componentCount,
    required this.moduleCards,
    required this.refineChoices,
    required this.referencedTitles,
    required this.elapsedMs,
  });

  factory EvalOutcome.fromSession(
    EvalCase evalCase,
    ModuleDiscoverySession session,
    Duration elapsed,
  ) {
    int count(String component) => session.components.values
        .where((node) => node['component'] == component)
        .length;
    final byPath = {for (final module in moduleManifest) module.path: module};
    final referencedTitles = [
      for (final node in session.components.values)
        if (node['component'] == 'ModuleCard' ||
            node['component'] == 'CompareTable')
          ..._referencedPaths(node).map((path) => byPath[path]?.title ?? path),
    ];
    return EvalOutcome(
      name: evalCase.name,
      error: session.error,
      hasSurface: session.hasSurface,
      rootIsGroup: session.components['root']?['component'] == 'Group',
      appliedMessages: session.records
          .where((record) => record.startsWith('界面更新：'))
          .length,
      componentCount: session.components.length,
      moduleCards: count('ModuleCard'),
      refineChoices: count('RefineChoice'),
      referencedTitles: referencedTitles.toSet().toList(),
      elapsedMs: elapsed.inMilliseconds,
    );
  }

  static Iterable<String> _referencedPaths(Map<String, dynamic> node) => [
    if (node['moduleId'] case final String path) path,
    if (node['moduleIds'] case final List ids)
      for (final id in ids.whereType<String>()) id,
    if (node['steps'] case final List steps)
      for (final step in steps.whereType<Map>())
        if (step['moduleId'] case final String path) path,
  ];

  final String name;
  final String? error;
  final bool hasSurface;
  final bool rootIsGroup;
  final int appliedMessages;
  final int componentCount;
  final int moduleCards;
  final int refineChoices;
  final List<String> referencedTitles;
  final int elapsedMs;

  String get failureSummary =>
      'error=$error surface=$hasSurface root=$rootIsGroup '
      'components=$componentCount cards=$moduleCards '
      'choices=$refineChoices refs=$referencedTitles ${elapsedMs}ms';

  Map<String, Object?> toJson() => {
    'name': name,
    'error': error,
    'hasSurface': hasSurface,
    'rootIsGroup': rootIsGroup,
    'appliedMessages': appliedMessages,
    'components': componentCount,
    'moduleCards': moduleCards,
    'refineChoices': refineChoices,
    'referencedTitles': referencedTitles,
    'elapsedMs': elapsedMs,
  };
}
