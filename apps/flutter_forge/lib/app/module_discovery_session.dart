import 'dart:async';
import 'dart:convert';
import 'package:a2ui_core/a2ui_core.dart' as a2ui;
import 'package:genui/genui.dart';
import '../module_registry/module_entry.dart';
import '../module_registry/app_platform_snapshot.dart';
import '../shared/genui/model_source.dart';
import '../shared/genui/session_core.dart';
import 'module_discovery_catalog.dart';

const discoverySurface = 'module-discovery';
const discoveryCatalog = 'dev.flutterforge.module-menu';

class ModuleDiscoverySession extends GenuiSessionCore {
  ModuleDiscoverySession({
    required this.modules,
    required this.platform,
    required this.openModule,
    this.recentPaths = const [],
    WorkbenchSource? source,
  }) : _source = source {
    _byPath = {for (final module in modules) module.path: module};
    catalog = buildDiscoveryCatalog(this);
    controller = SurfaceController(catalogs: [catalog]);
    _events = controller.onSubmit.listen((message) {
      final choice = pendingChoice;
      pendingChoice = null;
      if (choice == null || message.parts.uiInteractionParts.isEmpty) return;
      addRecord('SDK 澄清动作：$choice');
      unawaited(submit('$question\n补充偏好：$choice'));
    });
  }

  final List<ModuleEntry> modules;
  final AppPlatformSnapshot platform;
  final void Function(String) openModule;
  final List<String> recentPaths;
  late final Map<String, ModuleEntry> _byPath;
  WorkbenchSource? _source;
  late final Catalog catalog;
  late final SurfaceController controller;
  late final StreamSubscription<ChatMessage> _events;
  Map<String, Map<String, dynamic>> components = {};
  Map<String, Map<String, dynamic>>? _preFilterComponents;
  String? localFilterLabel;
  String question = '';

  /// Clarification prompt chosen by a generated [RefineChoice] and consumed
  /// by the surface's submit event; set by the catalog, drained once.
  String? pendingChoice;

  // Replay is the offline default; a live source replaces it explicitly.
  bool get connected => _source?.isReplay == false;
  bool get isReplay => _source?.isReplay ?? false;
  bool get hasSurface => controller.activeSurfaceIds.contains(discoverySurface);

  /// Single source for how a generated entry offers a module per platform:
  /// unsupported modules still route to the unified unavailable page, but
  /// every component labels the action the same way.
  String moduleActionLabel(ModuleEntry module) =>
      module.isSupportedOn(platform) ? '进入模块' : '查看平台限制';

  /// Resolves a validated module reference; the catalog may assume non-null
  /// because [validate] rejects unknown paths before they reach a renderer.
  ModuleEntry? moduleByPath(String? path) =>
      path == null ? null : _byPath[path];

  void setSource(WorkbenchSource source) {
    cancel();
    _source?.dispose();
    _source = source;
    error = null;
    notifyChanged();
  }

  @override
  WorkbenchSource? get activeSource => _source;

  @override
  String? submitGuard(String prompt) {
    if (prompt.isEmpty || prompt.length > 1500) {
      return '请用 1～1500 字描述想了解的内容。';
    }
    if (_source == null) {
      return '请先连接模型服务，或使用下方本地模块浏览。';
    }
    return null;
  }

  @override
  WorkbenchRequest buildRequest(String prompt) => WorkbenchRequest(
    prompt: prompt,
    snapshot: {'question': question, 'recent': recentPaths},
    components: components.values.toList(),
    systemPrompt: systemPrompt,
  );

  @override
  void applyStreamMessage(a2ui.A2uiMessage message) => _applyMessage(message);

  @override
  String get fallbackError => '推荐暂未完成，请检查模型服务后重试。已有结果仍可使用。';

  @override
  void recordError(Object cause, String message) {
    if (cause is! FormatException) addRecord('错误：$cause');
  }

  @override
  void onRunStarted(String prompt) {
    question = prompt;
    addRecord('请求：$prompt');
  }

  @override
  void onSuccess(String prompt, int appliedMessages) =>
      addRecord('界面更新：共 $appliedMessages 条消息，${components.length} 个组件');

  @override
  void onCancelled() => pendingChoice = null;

  Map<String, Map<String, dynamic>> validate(
    List<Map<String, dynamic>> updates,
    Map<String, Map<String, dynamic>> previous,
  ) {
    final next = {...previous};
    for (final node in updates) {
      final id = node['id'];
      if (id is! String || !RegExp(r'^[a-zA-Z0-9_-]{1,40}$').hasMatch(id)) {
        throw const FormatException('无效组件标识');
      }
      switch (node['component']) {
        case 'Group':
          if (node['children'] is! List ||
              (node['children'] as List).length > 12 ||
              (node['title'] != null &&
                  (node['title'] is! String ||
                      (node['title'] as String).length > 120)) ||
              (node['layout'] != null &&
                  !['list', 'compare'].contains(node['layout']))) {
            throw const FormatException('无效推荐分组');
          }
        case 'ModuleCard':
          if (!_byPath.containsKey(node['moduleId'])) {
            throw const FormatException('推荐引用了项目中不存在的模块');
          }
          _text(node['reason'], 400);
        case 'CompareTable':
          final ids = node['moduleIds'];
          if (ids is! List || ids.length < 2 || ids.length > 3) {
            throw const FormatException('对比表须选择 2～3 个模块');
          }
          for (final id in ids) {
            if (id is! String || !_byPath.containsKey(id)) {
              throw const FormatException('对比表引用了项目中不存在的模块');
            }
          }
          if (node['focus'] != null) _text(node['focus'], 120);
        case 'LearningPath':
          if (node['title'] != null) _text(node['title'], 40);
          final steps = node['steps'];
          if (steps is! List || steps.length < 2 || steps.length > 4) {
            throw const FormatException('学习路径须包含 2～4 步');
          }
          for (final step in steps) {
            if (step is! Map ||
                step['moduleId'] is! String ||
                !_byPath.containsKey(step['moduleId'])) {
              throw const FormatException('学习路径引用了项目中不存在的模块');
            }
            _text(step['goal'], 120);
          }
        case 'RecentHint':
          if (node['title'] != null) _text(node['title'], 40);
          final ids = node['moduleIds'];
          if (ids != null &&
              (ids is! List ||
                  ids.isEmpty ||
                  ids.length > 3 ||
                  ids.any(
                    (id) =>
                        id is! String ||
                        !_byPath.containsKey(id) ||
                        !recentPaths.contains(id),
                  ))) {
            throw const FormatException('最近访问须引用本地已有的模块入口');
          }
        case 'Note':
          _text(node['text'], 600);
        case 'RefineChoice':
          _text(node['label'], 60);
          final filter = node['filter'];
          if (filter is Map) {
            if (filter['by'] is! String ||
                !['difficulty', 'category', 'concept'].contains(filter['by']) ||
                filter['value'] is! String ||
                (filter['value'] as String).trim().isEmpty ||
                (filter['value'] as String).length > 20) {
              throw const FormatException('无效本地过滤条件');
            }
            if (node['prompt'] != null) _text(node['prompt'], 300);
          } else {
            _text(node['prompt'], 300);
          }
        default:
          throw const FormatException('未知探索组件');
      }
      next[id] = Map<String, dynamic>.from(node);
    }
    if (next.length > 40 || next['root']?['component'] != 'Group') {
      throw const FormatException('推荐须包含 root 分组，最多 40 个组件');
    }
    var visits = 0;
    void visit(String id, Set<String> ancestors, int depth) {
      if (++visits > 60 ||
          depth > 5 ||
          ancestors.contains(id) ||
          !next.containsKey(id)) {
        throw const FormatException('组件引用缺失、循环或嵌套过深');
      }
      final node = next[id]!;
      if (node['component'] == 'Group') {
        for (final child in node['children'] as List) {
          if (child is! String) throw const FormatException('无效子组件引用');
          visit(child, {...ancestors, id}, depth + 1);
        }
      }
    }

    for (final id in next.keys) {
      visits = 0;
      visit(id, {}, 0);
    }
    return next;
  }

  void _text(Object? value, int limit) {
    if (value is! String || value.trim().isEmpty || value.length > limit) {
      throw const FormatException('无效组件文本');
    }
  }

  void _applyMessage(a2ui.A2uiMessage message) {
    switch (message) {
      case a2ui.CreateSurfaceMessage m:
        if (m.surfaceId != discoverySurface ||
            m.catalogId != discoveryCatalog) {
          throw const FormatException('未知探索目录');
        }
        if (!hasSurface) controller.handleMessage(message);
      case a2ui.UpdateComponentsMessage m:
        if (m.surfaceId != discoverySurface || !hasSurface) {
          throw const FormatException('无效探索界面');
        }
        final next = validate(m.components, components);
        controller.handleMessage(message);
        components = next;
        // A fresh model response supersedes any local filtering.
        _preFilterComponents = null;
        localFilterLabel = null;
        controller
            .contextFor(discoverySurface)
            .dataModel
            .update(DataPath('/question'), question);
        addRecord('消息：更新 ${m.components.length} 项 → 共 ${next.length} 组件');
      default:
        throw const FormatException('当前只接受创建与组件更新');
    }
  }

  /// Narrows the current recommendation to modules matching a metadata
  /// criterion, executing entirely on-device through the same Surface
  /// pipeline the model uses — no model call, no event round-trip.
  void applyLocalFilter({
    required String by,
    required String value,
    required String label,
  }) {
    if (disposed || busy || !hasSurface) return;
    _preFilterComponents ??= {
      for (final entry in components.entries)
        entry.key: Map<String, dynamic>.from(entry.value),
    };
    final filtered = _filterTree(by, value);
    if (filtered == null) {
      error = '本地过滤「$label」没有匹配的模块，可换个条件或清除过滤。';
      notifyChanged();
      return;
    }
    _applyComponents(filtered);
    localFilterLabel = label;
    error = null;
    addRecord('本地过滤：$label（未调用模型）');
    notifyChanged();
  }

  void clearLocalFilter() {
    if (disposed) return;
    final restore = _preFilterComponents;
    _preFilterComponents = null;
    localFilterLabel = null;
    if (restore != null && hasSurface) {
      _applyComponents(restore);
      addRecord('已清除本地过滤');
    }
    notifyChanged();
  }

  Map<String, Map<String, dynamic>>? _filterTree(String by, String value) {
    bool matches(ModuleEntry module) => switch (by) {
      'difficulty' => module.difficulty.label == value,
      'category' => module.category.label == value,
      'concept' => module.concepts.contains(value),
      _ => false,
    };
    final kept = <String, Map<String, dynamic>>{};
    var matchedModules = 0;
    bool matchesPath(Object? path) {
      final module = path is String ? _byPath[path] : null;
      return module != null && matches(module);
    }

    Map<String, dynamic>? visit(String id) {
      if (kept.containsKey(id)) return kept[id];
      final node = components[id];
      if (node == null) return null;
      if (node['component'] == 'Group') {
        final children = [
          for (final child in (node['children'] as List).whereType<String>())
            visit(child),
        ].whereType<Map<String, dynamic>>().toList();
        if (children.isEmpty) return null;
        final copy = Map<String, dynamic>.from(node);
        copy['children'] = [
          for (final child in children) child['id'] as String,
        ];
        kept[id] = copy;
        return copy;
      }
      final copy = Map<String, dynamic>.from(node);
      switch (node['component']) {
        case 'ModuleCard':
          if (!matchesPath(node['moduleId'])) return null;
          matchedModules++;
        case 'CompareTable':
          final ids = (node['moduleIds'] as List).where(matchesPath).toList();
          if (ids.isEmpty) return null;
          matchedModules += ids.length;
          if (ids.length == 1) {
            kept[id] = {
              'id': id,
              'component': 'ModuleCard',
              'moduleId': ids.single,
              'reason': node['focus'] ?? '符合当前过滤条件的模块',
            };
            return kept[id];
          }
          copy['moduleIds'] = ids;
        case 'LearningPath':
          final steps = [
            for (final step in (node['steps'] as List).cast<Map>())
              if (matchesPath(step['moduleId'])) step,
          ];
          if (steps.isEmpty) return null;
          matchedModules += steps.length;
          if (steps.length == 1) {
            kept[id] = {
              'id': id,
              'component': 'ModuleCard',
              'moduleId': steps.single['moduleId'],
              'reason': steps.single['goal'],
            };
            return kept[id];
          }
          copy['steps'] = steps;
        case 'RecentHint':
          final ids = (node['moduleIds'] as List? ?? recentPaths)
              .where((path) => path is String && _byPath.containsKey(path))
              .take(3)
              .where(matchesPath)
              .toList();
          if (ids.isEmpty) return null;
          matchedModules += ids.length;
          copy['moduleIds'] = ids;
      }
      kept[id] = copy;
      return copy;
    }

    if (visit('root') == null || matchedModules == 0) return null;
    return kept;
  }

  void _applyComponents(Map<String, Map<String, dynamic>> next) {
    validate(next.values.toList(), {});
    controller.handleMessage(
      a2ui.UpdateComponentsMessage(
        surfaceId: discoverySurface,
        components: next.values.toList(),
      ),
    );
    components = next;
  }

  String get systemPrompt =>
      '''你是 Forge 的模块探索入口，像智能点餐一样在现有菜单内帮助用户选择学习模块。
只输出换行分隔的 A2UI v0.9 JSON。surfaceId=$discoverySurface，catalogId=$discoveryCatalog。
首次 createSurface 后 updateComponents，首次更新须一次提供 root 和全部引用节点。后续只更新必要组件，保留已有节点。
只使用 Group(children为组件ID数组,title可选,layout=list或compare)、Note(text≤600)、ModuleCard(moduleId,reason≤400)、RefineChoice(label≤60,prompt或filter)、CompareTable(moduleIds为2~3个path,focus≤120可选)、LearningPath(title≤40可选,steps为2~4个{moduleId,goal≤120})、RecentHint(title≤40可选)。root必须为Group。
ModuleCard.moduleId、CompareTable.moduleIds、LearningPath.steps[].moduleId 必须精确使用下面的path，所有模块事实由客户端渲染，你只写简短推荐理由；不能虚构课程、执行结果或路径。没有对应模块时用Note说明。
对比类意图用CompareTable；循序渐进的学习顺序用LearningPath；缩小难度/分类/概念范围用带filter的RefineChoice(filter={by:difficulty|category|concept,value}，本地执行不消耗模型调用)；需要重新理解意图才用带prompt的RefineChoice；用户想继续上次学习且最近访问非空时可用RecentHint。
一般推荐1～3个模块、0～3个澄清选项，不随机变换布局，不推荐自身入口的技术演示代替实际主题。已明确意图时直接推荐。
用户选择带prompt的RefineChoice将回传新偏好；进入模块由本地路由完成。不要输出updateDataModel/deleteSurface或普通文本。最多40组件、5层嵌套。
最近访问（可能为空）：${jsonEncode([for (final path in recentPaths)
        if (_byPath[path] case final module?) module.title])}
例：{"version":"v0.9","createSurface":{"surfaceId":"$discoverySurface","catalogId":"$discoveryCatalog"}}
{"version":"v0.9","updateComponents":{"surfaceId":"$discoverySurface","components":[{"id":"root","component":"Group","children":["note"]},{"id":"note","component":"Note","text":"请选择想了解的问题"}]}}
真实模块菜单：${jsonEncode([
        for (final m in modules) {'path': m.path, 'title': m.title, 'subtitle': m.subtitle, 'concepts': m.concepts, 'difficulty': m.difficulty.label, 'minutes': m.estimatedMinutes, 'available': m.isSupportedOn(platform)},
      ])}
''';
  @override
  void dispose() {
    super.dispose();
    unawaited(_events.cancel());
    controller.dispose();
    _source?.dispose();
  }
}
