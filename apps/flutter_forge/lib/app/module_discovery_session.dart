import 'dart:async';
import 'dart:convert';
import 'package:a2ui_core/a2ui_core.dart' as a2ui;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';
import '../module_registry/module_entry.dart';
import '../module_registry/app_platform_snapshot.dart';
import '../shared/genui/model_source.dart';
import 'module_discovery_surface.dart';

const discoverySurface = 'module-discovery';
const discoveryCatalog = 'dev.flutterforge.module-menu';

class ModuleDiscoverySession extends ChangeNotifier {
  ModuleDiscoverySession({
    required this.modules,
    required this.platform,
    required this.openModule,
    this.recentPaths = const [],
    WorkbenchSource? source,
  }) : _source = source {
    _byPath = {for (final module in modules) module.path: module};
    catalog = Catalog([
      _item(
        'Group',
        {
          'children': S.list(items: S.string()),
          'title': S.string(),
          'layout': S.string(enumValues: ['list', 'compare']),
        },
        (c) {
          final data = c.data as Map;
          final children = [
            for (final id in data['children'] as List)
              c.buildChild(id as String),
          ];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (data['title'] is String)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    data['title'] as String,
                    style: Theme.of(c.buildContext).textTheme.titleMedium,
                  ),
                ),
              if (data['layout'] == 'compare')
                LayoutBuilder(
                  builder: (_, constraints) => Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      for (final child in children)
                        SizedBox(
                          width: constraints.maxWidth >= 600
                              ? (constraints.maxWidth - 12) / 2
                              : constraints.maxWidth,
                          child: child,
                        ),
                    ],
                  ),
                )
              else
                ...children,
            ],
          );
        },
        required: ['children'],
      ),
      _item(
        'Note',
        {'text': S.string(maxLength: 600)},
        (c) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text((c.data as Map)['text'] as String),
        ),
        required: ['text'],
      ),
      _item(
        'ModuleCard',
        {'moduleId': S.string(), 'reason': S.string(maxLength: 400)},
        (c) {
          final data = c.data as Map;
          final module = _byPath[data['moduleId'] as String]!;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: DiscoverySurface(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      module.title,
                      style: Theme.of(c.buildContext).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(module.subtitle),
                    Text(
                      '${module.category.label} · ${module.difficulty.label} · ${module.estimatedMinutes} 分钟',
                    ),
                    const SizedBox(height: 8),
                    Text(data['reason'] as String),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FilledButton.tonal(
                        onPressed: busy
                            ? null
                            : () {
                                records.add('本地打开：${module.path}');
                                openModule(module.path);
                              },
                        child: Text(moduleActionLabel(module)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        required: ['moduleId', 'reason'],
      ),
      _item(
        'CompareTable',
        {
          'moduleIds': S.list(items: S.string()),
          'focus': S.string(maxLength: 120),
        },
        (c) {
          final data = c.data as Map;
          final selected = [
            for (final id in (data['moduleIds'] as List).whereType<String>())
              _byPath[id]!,
          ];
          final focus = data['focus'] as String?;
          final theme = Theme.of(c.buildContext);
          final colors = theme.colorScheme;
          TableRow row(String label, List<String> values) => TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
              for (final value in values)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(value, style: theme.textTheme.bodySmall),
                ),
            ],
          );
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: DiscoverySurface(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Table(
                      columnWidths: const {0: FixedColumnWidth(72)},
                      defaultVerticalAlignment:
                          TableCellVerticalAlignment.middle,
                      children: [
                        TableRow(
                          children: [
                            const SizedBox(),
                            for (final module in selected)
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      module.title,
                                      style: theme.textTheme.titleSmall,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: moduleActionLabel(module),
                                    visualDensity: VisualDensity.compact,
                                    onPressed: busy
                                        ? null
                                        : () {
                                            records.add('本地打开：${module.path}');
                                            openModule(module.path);
                                          },
                                    icon: const Icon(
                                      Icons.open_in_new,
                                      size: 16,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        row('分类', [
                          for (final module in selected) module.category.label,
                        ]),
                        row('难度', [
                          for (final module in selected)
                            module.difficulty.label,
                        ]),
                        row('时长', [
                          for (final module in selected)
                            '${module.estimatedMinutes} 分钟',
                        ]),
                        row('平台', [
                          for (final module in selected)
                            module.isSupportedOn(platform)
                                ? '当前平台可用'
                                : '当前平台受限',
                        ]),
                        row('概念', [
                          for (final module in selected)
                            module.concepts.take(3).join('、'),
                        ]),
                      ],
                    ),
                    if (focus != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '对比重点：$focus',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
        required: ['moduleIds'],
      ),
      _item(
        'LearningPath',
        {
          'title': S.string(maxLength: 40),
          'steps': S.list(
            items: S.object(
              properties: {
                'moduleId': S.string(),
                'goal': S.string(maxLength: 120),
              },
              required: ['moduleId', 'goal'],
            ),
          ),
        },
        (c) {
          final data = c.data as Map;
          final theme = Theme.of(c.buildContext);
          final colors = theme.colorScheme;
          final steps = [
            for (final step in (data['steps'] as List).whereType<Map>())
              (
                module: _byPath[step['moduleId'] as String?]!,
                goal: step['goal'] as String,
              ),
          ];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: DiscoverySurface(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (data['title'] is String)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          data['title'] as String,
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                    for (var index = 0; index < steps.length; index++)
                      Padding(
                        padding: EdgeInsets.only(top: index == 0 ? 0 : 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: colors.primaryContainer,
                              ),
                              child: Text(
                                '${index + 1}',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colors.onPrimaryContainer,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    steps[index].goal,
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        steps[index].module.category.icon,
                                        size: 16,
                                        color: colors.onSurfaceVariant,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          steps[index].module.title,
                                          style: theme.textTheme.titleSmall,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      IconButton(
                                        tooltip: moduleActionLabel(
                                          steps[index].module,
                                        ),
                                        visualDensity: VisualDensity.compact,
                                        onPressed: busy
                                            ? null
                                            : () {
                                                final path =
                                                    steps[index].module.path;
                                                records.add('本地打开：$path');
                                                openModule(path);
                                              },
                                        icon: const Icon(
                                          Icons.arrow_forward,
                                          size: 18,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    steps[index].module.subtitle,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colors.onSurfaceVariant,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
        required: ['steps'],
      ),
      _item('RecentHint', {'title': S.string(maxLength: 40)}, (c) {
        final recents = [
          for (final path in recentPaths)
            if (_byPath[path] case final module?) module,
        ].take(3).toList();
        if (recents.isEmpty) return const SizedBox.shrink();
        final theme = Theme.of(c.buildContext);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.history_rounded,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    ((c.data as Map)['title'] as String?) ?? '继续上次',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final module in recents)
                    ActionChip(
                      label: Text(module.title),
                      onPressed: busy
                          ? null
                          : () {
                              records.add('本地打开：${module.path}');
                              openModule(module.path);
                            },
                    ),
                ],
              ),
            ],
          ),
        );
      }),
      _item(
        'RefineChoice',
        {
          'label': S.string(maxLength: 60),
          'prompt': S.string(maxLength: 300),
          'filter': S.object(
            properties: {
              'by': S.string(enumValues: ['difficulty', 'category', 'concept']),
              'value': S.string(maxLength: 20),
            },
            required: ['by', 'value'],
          ),
        },
        (c) {
          final data = c.data as Map;
          final filter = data['filter'];
          final isLocal = filter is Map;
          return Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: OutlinedButton.icon(
                onPressed: busy || (!isLocal && _pending != null)
                    ? null
                    : () {
                        final filter = data['filter'];
                        if (filter case Map<String, dynamic> filter
                            when filter['by'] is String &&
                                filter['value'] is String) {
                          applyLocalFilter(
                            by: filter['by'] as String,
                            value: filter['value'] as String,
                            label: data['label'] as String,
                          );
                        } else {
                          _pending = data['prompt'] as String;
                          c.dispatchEvent(
                            UserActionEvent(
                              name: 'refineIntent',
                              sourceComponentId: c.id,
                              context: {'choice': _pending!},
                            ),
                          );
                        }
                      },
                icon: Icon(
                  isLocal
                      ? Icons.filter_alt_outlined
                      : Icons.north_east_rounded,
                  size: 14,
                ),
                label: Text(data['label'] as String),
              ),
            ),
          );
        },
        required: ['label'],
      ),
    ], catalogId: discoveryCatalog);
    controller = SurfaceController(catalogs: [catalog]);
    _events = controller.onSubmit.listen((message) {
      final choice = _pending;
      _pending = null;
      if (choice == null || message.parts.uiInteractionParts.isEmpty) return;
      records.add('SDK 澄清动作：$choice');
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
  final records = <String>[];
  String question = '';
  String? error;
  String? _pending;
  bool busy = false;
  bool _disposed = false;
  int _epoch = 0;
  CancelToken? _token;
  // Replay is the offline default; a live source replaces it explicitly.
  bool get connected => _source?.isReplay == false;
  bool get isReplay => _source?.isReplay ?? false;
  bool get hasSurface => controller.activeSurfaceIds.contains(discoverySurface);

  /// Single source for how a generated entry offers a module per platform:
  /// unsupported modules still route to the unified unavailable page, but
  /// every component labels the action the same way.
  String moduleActionLabel(ModuleEntry module) =>
      module.isSupportedOn(platform) ? '进入模块' : '查看平台限制';

  CatalogItem _item(
    String name,
    Map<String, Schema> properties,
    Widget Function(CatalogItemContext) builder, {
    List<String> required = const [],
  }) => CatalogItem(
    name: name,
    dataSchema: S.object(properties: properties, required: required),
    widgetBuilder: builder,
  );

  void setSource(WorkbenchSource source) {
    cancel();
    _source?.dispose();
    _source = source;
    error = null;
    notifyListeners();
  }

  void cancel() {
    _epoch++;
    _token?.cancel('cancelled');
    _token = null;
    busy = false;
    _pending = null;
    if (!_disposed) notifyListeners();
  }

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

  Future<void> submit(String prompt) async {
    if (_disposed || busy) return;
    prompt = prompt.trim();
    if (prompt.isEmpty || prompt.length > 1500) {
      error = '请用 1～1500 字描述想了解的内容。';
      notifyListeners();
      return;
    }
    final source = _source;
    if (source == null) {
      error = '请先连接模型服务，或使用下方本地模块浏览。';
      notifyListeners();
      return;
    }
    final epoch = ++_epoch;
    final token = _token = CancelToken();
    question = prompt;
    busy = true;
    error = null;
    records.add('请求：$prompt');
    if (records.length > 20) records.removeRange(0, records.length - 20);
    notifyListeners();
    var applied = 0;
    var length = 0;
    try {
      final request = WorkbenchRequest(
        prompt: prompt,
        snapshot: {'question': question, 'recent': recentPaths},
        components: components.values.toList(),
        systemPrompt: systemPrompt,
      );
      // Apply each protocol message as it is parsed so partial results render
      // progressively; every message is fully validated before it commits,
      // and an invalid tail leaves earlier messages in place.
      await for (final event
          in source
              .generate(request, token)
              .timeout(const Duration(seconds: 100))
              .map((chunk) {
                length += chunk.length;
                if (length > 48000) throw const FormatException('生成内容过长');
                return chunk;
              })
              .transform(const A2uiParserTransformer())) {
        if (_disposed || epoch != _epoch) return;
        if (event is A2uiMessageEvent) {
          _applyMessage(event.message);
          applied++;
        } else if (event is TextEvent && event.text.trim().isNotEmpty) {
          throw const FormatException('响应不是完整的界面协议');
        }
      }
      if (_disposed || epoch != _epoch) return;
      if (applied == 0) throw const FormatException('没有收到推荐界面');
      records.add('界面更新：共 $applied 条消息，${components.length} 个组件');
    } catch (e) {
      if (!_disposed && epoch == _epoch) {
        error = e is FormatException
            ? e.message
            : '推荐暂未完成，请检查模型服务后重试。已有结果仍可使用。';
        if (e is! FormatException) records.add('错误：$e');
      }
    } finally {
      if (!_disposed && epoch == _epoch) {
        busy = false;
        _token = null;
        notifyListeners();
      }
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
        records.add('消息：更新 ${m.components.length} 项 → 共 ${next.length} 组件');
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
    if (_disposed || busy || !hasSurface) return;
    _preFilterComponents ??= {
      for (final entry in components.entries)
        entry.key: Map<String, dynamic>.from(entry.value),
    };
    final filtered = _filterTree(by, value);
    if (filtered == null) {
      error = '本地过滤「$label」没有匹配的模块，可换个条件或清除过滤。';
      notifyListeners();
      return;
    }
    _applyComponents(filtered);
    localFilterLabel = label;
    error = null;
    records.add('本地过滤：$label（未调用模型）');
    if (records.length > 20) records.removeRange(0, records.length - 20);
    notifyListeners();
  }

  void clearLocalFilter() {
    if (_disposed) return;
    final restore = _preFilterComponents;
    _preFilterComponents = null;
    localFilterLabel = null;
    if (restore != null && hasSurface) {
      _applyComponents(restore);
      records.add('已清除本地过滤');
    }
    notifyListeners();
  }

  Map<String, Map<String, dynamic>>? _filterTree(String by, String value) {
    bool matches(ModuleEntry module) => switch (by) {
      'difficulty' => module.difficulty.label == value,
      'category' => module.category.label == value,
      'concept' => module.concepts.contains(value),
      _ => false,
    };
    final kept = <String, Map<String, dynamic>>{};
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
      if (node['component'] == 'ModuleCard') {
        final module = _byPath[node['moduleId'] as String?];
        if (module == null || !matches(module)) return null;
      }
      final copy = Map<String, dynamic>.from(node);
      kept[id] = copy;
      return copy;
    }

    if (visit('root') == null) return null;
    return kept;
  }

  void _applyComponents(Map<String, Map<String, dynamic>> next) {
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
    _disposed = true;
    cancel();
    unawaited(_events.cancel());
    controller.dispose();
    _source?.dispose();
    super.dispose();
  }
}
