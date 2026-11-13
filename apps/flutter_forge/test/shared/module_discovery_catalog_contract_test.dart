import 'package:flutter_forge_app/app/module_discovery_session.dart';
import 'package:flutter_forge_app/module_registry/app_platform_snapshot.dart';
import 'package:flutter_forge_app/module_registry/module_manifest.dart';
import 'package:flutter_test/flutter_test.dart';

// Extension contract for the restricted discovery catalog (P1-3): adding a
// component means touching the catalog, the validate() whitelist, the system
// prompt list and this sample map. These tests fail until all four agree, so
// the extension path stays a checklist instead of folklore.
void main() {
  const platform = AppPlatformSnapshot(platform: AppTargetPlatform.macOS);
  late final ModuleDiscoverySession session;
  setUpAll(() {
    session = ModuleDiscoverySession(
      modules: moduleManifest,
      platform: platform,
      openModule: (_) {},
    );
    addTearDown(session.dispose);
  });

  final paths = [
    for (final module in moduleManifest)
      if (module.isSupportedOn(platform)) module.path,
  ];

  // One whitelist-valid sample per component, keyed by component name.
  final samples = <String, List<Map<String, dynamic>>>{
    'Group': [
      {
        'id': 'sample-group',
        'component': 'Group',
        'children': ['sample-note'],
      },
      {'id': 'sample-note', 'component': 'Note', 'text': '示例说明'},
    ],
    'Note': [
      {'id': 'sample-note', 'component': 'Note', 'text': '示例说明'},
    ],
    'ModuleCard': [
      {
        'id': 'sample-card',
        'component': 'ModuleCard',
        'moduleId': paths.first,
        'reason': '示例理由',
      },
    ],
    'CompareTable': [
      {
        'id': 'sample-compare',
        'component': 'CompareTable',
        'moduleIds': paths.take(2).toList(),
      },
    ],
    'LearningPath': [
      {
        'id': 'sample-path',
        'component': 'LearningPath',
        'steps': [
          {'moduleId': paths[0], 'goal': '第一步'},
          {'moduleId': paths[1], 'goal': '第二步'},
        ],
      },
    ],
    'RecentHint': [
      {'id': 'sample-recent', 'component': 'RecentHint'},
    ],
    'RefineChoice': [
      {
        'id': 'sample-choice',
        'component': 'RefineChoice',
        'label': '缩小范围',
        'filter': {'by': 'difficulty', 'value': '入门'},
      },
    ],
  };

  Map<String, Map<String, dynamic>> rooted() => {
    'root': {'id': 'root', 'component': 'Group', 'children': <String>[]},
  };

  test('every catalog component has exactly one whitelist-valid sample', () {
    final names = session.catalog.items.map((item) => item.name).toSet();
    expect(
      names,
      samples.keys.toSet(),
      reason: '目录有而样本无 = 缺校验样本；样本有而目录无 = 组件已删但校验残留',
    );
    for (final entry in samples.entries) {
      expect(
        () => session.validate(entry.value, rooted()),
        returnsNormally,
        reason: '${entry.key} 的样本必须通过 validate()',
      );
    }
  });

  test('unknown components stay rejected by the whitelist', () {
    expect(
      () => session.validate([
        {'id': 'mystery', 'component': 'MysteryWidget'},
      ], {}),
      throwsFormatException,
    );
  });

  test('the system prompt lists every catalog component', () {
    final prompt = session.systemPrompt;
    for (final name in session.catalog.items.map((item) => item.name)) {
      expect(prompt.contains(name), isTrue, reason: '系统提示词白名单缺少组件 $name');
    }
  });
}
