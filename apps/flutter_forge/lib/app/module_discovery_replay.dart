import 'dart:convert';

import 'package:dio/dio.dart';

import 'package:flutter_forge_app/module_registry/app_platform_snapshot.dart';
import 'package:flutter_forge_app/module_registry/module_entry.dart';
import 'package:flutter_forge_app/shared/genui/model_source.dart';

import 'module_discovery_session.dart';

typedef _ReplayCard = (String path, String reason);
typedef _ReplayStep = (String path, String goal, String fallbackReason);
typedef _ReplayChoice = (String id, String label, String? prompt);
typedef _ReplayTopic = (
  List<String> keywords,
  String note,
  List<_ReplayCard> cards,
  List<String> compare,
  String focus,
  List<_ReplayStep> steps,
  List<_ReplayChoice> choices,
);

/// Offline replay for the module discovery entry: fixed, clearly labelled
/// responses for the three example questions, so visitors without a model
/// service still exercise the full render → clarify → local-filter loop.
///
/// Authored candidates are platform-aware: modules the current platform
/// excludes are filtered out; a compare table keeps at least two modules and
/// a learning path at least two steps, each degrading to plain cards below
/// that, so every target only recommends modules it can actually open. No
/// text claims a model was invoked.
class ReplayDiscoverySource implements WorkbenchSource {
  ReplayDiscoverySource({required this.modules, required this.platform});

  final List<ModuleEntry> modules;
  final AppPlatformSnapshot platform;

  static const _filterByDifficulty = {'by': 'difficulty', 'value': '入门'};

  @override
  String get label => '固定回放 · 未调用模型';
  @override
  bool get isReplay => true;
  @override
  void dispose() {}

  @override
  Stream<String> generate(
    WorkbenchRequest request,
    CancelToken cancelToken,
  ) async* {
    final prompt = request.prompt;
    final clarifyAt = prompt.indexOf('补充偏好');
    final isClarify = clarifyAt >= 0 && request.components.isNotEmpty;
    final question = isClarify ? prompt.substring(0, clarifyAt) : prompt;
    if (isClarify) {
      // Deliberately a partial update: one note changes, everything else the
      // visitor already sees stays in place.
      yield _line('updateComponents', {
        'components': [
          {
            'id': 'note',
            'component': 'Note',
            'text':
                '已收到你的补充偏好（回放演示，仅局部更新这条说明）。'
                '连接真实模型后，补充偏好会驱动完整的新一轮推荐。',
          },
        ],
      });
      return;
    }
    final topic = _topics
        .where((topic) => topic.$1.any(question.contains))
        .firstOrNull;
    if (topic == null) {
      throw const FormatException(
        '回放仅覆盖三个示例问题（异步卡界面、宽度与布局、网络诊断）。'
        '点击示例填入问题，或连接真实模型自由探索。',
      );
    }
    final byPath = {for (final module in modules) module.path: module};
    bool supported(String path) =>
        byPath[path]?.isSupportedOn(platform) ?? false;
    final cards = [
      for (final card in topic.$3)
        if (supported(card.$1)) card,
    ];
    final compare = [
      for (final path in topic.$4)
        if (supported(path)) path,
    ];
    final steps = [
      for (final step in topic.$6)
        if (supported(step.$1)) step,
    ];
    final nodes = <Map<String, Object?>>[
      {'id': 'note', 'component': 'Note', 'text': topic.$2},
      for (final (index, card) in cards.indexed)
        {
          'id': 'card-$index',
          'component': 'ModuleCard',
          'moduleId': card.$1,
          'reason': card.$2,
        },
      if (compare.length >= 2)
        {
          'id': 'compare',
          'component': 'CompareTable',
          'moduleIds': compare,
          'focus': topic.$5,
        }
      else
        for (final (index, path) in compare.indexed)
          {
            'id': 'card-compare-$index',
            'component': 'ModuleCard',
            'moduleId': path,
            'reason': topic.$5,
          },
      if (steps.length >= 2)
        {
          'id': 'path',
          'component': 'LearningPath',
          'title': '建议顺序',
          'steps': [
            for (final step in steps) {'moduleId': step.$1, 'goal': step.$2},
          ],
        }
      else
        for (final (index, step) in steps.indexed)
          if (cards.every((card) => card.$1 != step.$1))
            {
              'id': 'card-step-$index',
              'component': 'ModuleCard',
              'moduleId': step.$1,
              'reason': step.$3,
            },
      for (final choice in topic.$7)
        {
          'id': choice.$1,
          'component': 'RefineChoice',
          'label': choice.$2,
          if (choice.$3 != null) 'prompt': choice.$3!,
          if (choice.$3 == null) 'filter': _filterByDifficulty,
        },
    ];
    final recents = [
      for (final path in (request.snapshot['recent'] as List? ?? const []))
        if (path is String && byPath.containsKey(path)) path,
    ];
    final children = [
      for (final node in nodes)
        if ((node['id'] as String) != 'note') node['id'] as String,
      if (recents.isNotEmpty) 'recent',
    ];
    final tree = [
      {'id': 'root', 'component': 'Group', 'children': children},
      ...nodes,
      if (recents.isNotEmpty)
        {'id': 'recent', 'component': 'RecentHint', 'title': '继续上次'},
    ];
    if (request.components.isEmpty) {
      yield _line('createSurface', {'catalogId': discoveryCatalog});
    }
    yield _line('updateComponents', {'components': tree});
  }

  Map<String, Object?> _envelope(String operation, Map<String, Object?> body) =>
      {
        'version': 'v0.9',
        operation: {'surfaceId': discoverySurface, ...body},
      };

  String _line(String operation, Map<String, Object?> body) =>
      '${jsonEncode(_envelope(operation, body))}\n';
}

const _topics = <_ReplayTopic>[
  (
    ['宽度', '布局', '约束', '尺寸'],
    '固定回放：宽度不生效通常是父级约束覆盖了子组件的期望尺寸。'
        '下面用对比表并排看两个模块，也可换个角度继续探索。',
    <_ReplayCard>[],
    ['/constraint-layout', '/tree-state'],
    '约束决定尺寸的可用范围，三棵树解释尺寸如何被采纳与重建',
    <_ReplayStep>[],
    <_ReplayChoice>[('refine', '换个角度：看异步为什么会卡界面', '请推荐异步并发方向的模块')],
  ),
  (
    ['网络', '诊断', 'dns', 'http', '请求'],
    '固定回放：排查网络问题先采集证据再定位。建议按顺序，'
        '从现象级检测走到拦截器层的重试与错误处理。',
    <_ReplayCard>[('/dio-interceptor', '拦截器实战：Auth、重试、日志与本地 Mock Server')],
    <String>[],
    '',
    <_ReplayStep>[
      (
        '/network-diagnostics',
        '从现象出发，采集 DNS、TCP 与 HTTP 的检测证据',
        '先看诊断模块如何采集网络证据',
      ),
      ('/dio-interceptor', '在拦截器层处理重试、Token 刷新与错误分支', '再学拦截器层的重试与错误处理'),
    ],
    <_ReplayChoice>[
      ('filter', '只看进阶难度（本地执行）', null),
      ('refine', '我想看更基础的入门内容', '请优先推荐入门难度的模块'),
    ],
  ),
  (
    ['异步', '卡', 'isolate', '事件循环', '并发'],
    '固定回放：界面卡顿常见于耗时计算占住了主线程。'
        '先理解事件循环的排队规则，再对比 Isolate 把耗时任务放到哪里执行。',
    <_ReplayCard>[
      ('/microtask', '先看清微任务与事件队列谁先执行，定位卡顿来自哪里'),
      ('/isolate-basic', '把耗时计算放进 Isolate，直接对比主线程执行时的流畅度差异'),
    ],
    <String>[],
    '',
    <_ReplayStep>[
      ('/microtask', '理解事件循环的排队规则', '先理解事件循环的排队规则'),
      ('/isolate-basic', '用 Isolate 对比耗时任务的执行位置', '再对比 Isolate 中耗时任务的执行位置'),
    ],
    <_ReplayChoice>[
      ('filter', '只看入门难度（本地执行）', null),
      ('refine', '想看网络请求卡住的场景', '请优先推荐网络与平台分类的模块'),
    ],
  ),
];
