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
    WorkbenchSource? source,
  }) : _source = source {
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
          final module = modules.firstWhere((m) => m.path == data['moduleId']);
          final supported = module.isSupportedOn(platform);
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
                        child: Text(supported ? '进入模块' : '查看平台限制'),
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
        'RefineChoice',
        {'label': S.string(maxLength: 60), 'prompt': S.string(maxLength: 300)},
        (c) {
          final data = c.data as Map;
          return Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: OutlinedButton(
                onPressed: busy || _pending != null
                    ? null
                    : () {
                        _pending = data['prompt'] as String;
                        c.dispatchEvent(
                          UserActionEvent(
                            name: 'refineIntent',
                            sourceComponentId: c.id,
                            context: {'choice': _pending!},
                          ),
                        );
                      },
                child: Text(data['label'] as String),
              ),
            ),
          );
        },
        required: ['label', 'prompt'],
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
  WorkbenchSource? _source;
  late final Catalog catalog;
  late final SurfaceController controller;
  late final StreamSubscription<ChatMessage> _events;
  Map<String, Map<String, dynamic>> components = {};
  final records = <String>[];
  String question = '';
  String? error;
  String? _pending;
  bool busy = false;
  bool _disposed = false;
  int _epoch = 0;
  CancelToken? _token;
  bool get connected => _source != null;
  bool get hasSurface => controller.activeSurfaceIds.contains(discoverySurface);
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
          if (!modules.any((m) => m.path == node['moduleId'])) {
            throw const FormatException('推荐引用了项目中不存在的模块');
          }
          _text(node['reason'], 400);
        case 'Note':
          _text(node['text'], 600);
        case 'RefineChoice':
          _text(node['label'], 60);
          _text(node['prompt'], 300);
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
    try {
      final messages = <a2ui.A2uiMessage>[];
      var length = 0;
      final request = WorkbenchRequest(
        prompt: prompt,
        snapshot: {'question': question},
        components: components.values.toList(),
        systemPrompt: systemPrompt,
      );
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
          messages.add(event.message);
        } else if (event is TextEvent && event.text.trim().isNotEmpty) {
          throw const FormatException('响应不是完整的界面协议');
        }
      }
      if (_disposed || epoch != _epoch) return;
      if (messages.isEmpty) throw const FormatException('没有收到推荐界面');
      var next = components;
      var created = hasSurface;
      for (final message in messages) {
        switch (message) {
          case a2ui.CreateSurfaceMessage m:
            if (m.surfaceId != discoverySurface ||
                m.catalogId != discoveryCatalog) {
              throw const FormatException('未知探索目录');
            }
            created = true;
          case a2ui.UpdateComponentsMessage m:
            if (!created || m.surfaceId != discoverySurface) {
              throw const FormatException('无效探索界面');
            }
            next = validate(m.components, next);
          default:
            throw const FormatException('当前只接受创建与组件更新');
        }
      }
      if (next.isEmpty) throw const FormatException('未收到可用推荐');
      // Validate the whole response before committing; failed updates keep the old menu.
      for (final message in messages) {
        if (message is a2ui.CreateSurfaceMessage && hasSurface) continue;
        controller.handleMessage(message);
      }
      components = next;
      controller
          .contextFor(discoverySurface)
          .dataModel
          .update(DataPath('/question'), question);
      records.add('界面更新：${messages.length} 条 A2UI 消息，${components.length} 个组件');
    } catch (e) {
      if (!_disposed && epoch == _epoch) {
        error = e is FormatException
            ? e.message
            : '推荐暂未完成，请检查模型服务后重试。已有结果仍可使用。';
      }
    } finally {
      if (!_disposed && epoch == _epoch) {
        busy = false;
        _token = null;
        notifyListeners();
      }
    }
  }

  String get systemPrompt =>
      '''你是 Forge 的模块探索入口，像智能点餐一样在现有菜单内帮助用户选择学习模块。
只输出换行分隔的 A2UI v0.9 JSON。surfaceId=$discoverySurface，catalogId=$discoveryCatalog。
首次 createSurface 后 updateComponents，首次更新须一次提供 root 和全部引用节点。后续只更新必要组件，保留已有节点。
只使用 Group(children为组件ID数组,title可选,layout=list或compare)、Note(text)、ModuleCard(moduleId,reason)、RefineChoice(label,prompt)。root必须为Group。
ModuleCard.moduleId必须精确使用下面的path，所有模块事实由客户端渲染，你只写简短推荐理由；不能虚构课程、执行结果或路径。没有对应模块时用Note说明。
根据意图灵活组织分组、对比或澄清选项。一般推荐1～3个模块、0～3个澄清选项，不随机变换布局，不推荐自身入口的技术演示代替实际主题。已明确意图时直接推荐。
用户选择RefineChoice将回传新偏好；进入模块由本地路由完成。不要输出updateDataModel/deleteSurface或普通文本。最多40组件、5层嵌套。
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
