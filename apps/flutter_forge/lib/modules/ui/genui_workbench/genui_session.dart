import 'dart:async';
import 'dart:convert';

import 'package:a2ui_core/a2ui_core.dart' as a2ui;
import 'package:dio/dio.dart';
import 'package:genui/genui.dart';

import '../../../shared/genui/session_core.dart';
import 'workbench_catalog.dart';
import 'workbench_protocol.dart';
import 'workbench_source.dart';

const _explainPrompt = '解释当前结果';

class GenuiSession extends GenuiSessionCore {
  GenuiSession({WorkbenchSource? source})
    : _source = source ?? ReplayWorkbenchSource(),
      super(recordLimit: 40) {
    catalog = buildWorkbenchCatalog(this);
    controller = SurfaceController(catalogs: [catalog]);
    _submissions = controller.onSubmit.listen((message) {
      if (disposed) return;
      final interactions = message.parts.uiInteractionParts;
      if (interactions.isEmpty) {
        error = 'SDK 无法处理当前组件或消息，请重置后重试。';
        notifyChanged();
        return;
      }
      _record('事件', interactions.first.interaction);
      unawaited(submit(_explainPrompt));
    });
  }

  late final Catalog catalog;
  late final SurfaceController controller;
  late final StreamSubscription<ChatMessage> _submissions;
  WorkbenchSource _source;
  int _sentRevision = 0;
  int revision = 0;
  int? observationRevision;
  int? explanationRevision;
  double? actualWidth;
  double? actualHeight;
  String lastPrompt = '';
  Map<String, Map<String, dynamic>> _components = {};

  bool get hasSurface =>
      controller.activeSurfaceIds.contains(workbenchSurfaceId);
  bool get hasExperiment => hasSurface && _components.isNotEmpty;
  String get sourceLabel => _source.label;
  bool get isReplay => _source.isReplay;
  bool get observationReady => observationRevision == revision;
  bool get explanationStale =>
      explanationRevision != null && explanationRevision != revision;
  DataModel get dataModel =>
      controller.contextFor(workbenchSurfaceId).dataModel;

  Object value(String field) => hasSurface
      ? dataModel.getValue<Object>(DataPath('/$field')) ??
            initialExperiment[field]!
      : initialExperiment[field]!;

  Map<String, Object?> get snapshot => {
    for (final field in initialExperiment.keys) field: value(field),
    'revision': revision,
    'observationRevision': observationRevision,
    'actualWidth': observationReady ? actualWidth : null,
    'actualHeight': observationReady ? actualHeight : null,
    'observationSource': 'Flutter RenderBox.size after layout',
  };

  void updateParameter(String field, Object? next) {
    if (disposed || !hasSurface) return;
    final validated = validateExperimentValue(field, next);
    if (value(field) == validated) return;
    dataModel.update(DataPath('/$field'), validated);
    revision++;
    observationRevision = null;
    _record('状态', '$field = $validated · v$revision');
    notifyChanged();
  }

  void observe(int measuredRevision, double width, double height) {
    if (disposed || measuredRevision != revision || !hasSurface) return;
    if (observationRevision == revision &&
        actualWidth == width &&
        actualHeight == height) {
      return;
    }
    actualWidth = width;
    actualHeight = height;
    observationRevision = revision;
    notifyChanged();
  }

  void explain(CatalogItemContext context) {
    if (busy || !observationReady) return;
    context.dispatchEvent(
      UserActionEvent(
        name: 'explain',
        sourceComponentId: context.id,
        context: snapshot,
      ),
    );
  }

  void setSource(WorkbenchSource source) {
    cancel();
    _source.dispose();
    _source = source;
    error = null;
    _record('模式', source.label);
    notifyChanged();
  }

  void reset() {
    cancel();
    if (hasSurface) {
      controller.handleMessage(
        a2ui.DeleteSurfaceMessage(surfaceId: workbenchSurfaceId),
      );
    }
    _components = {};
    revision++;
    observationRevision = null;
    explanationRevision = null;
    actualWidth = null;
    actualHeight = null;
    error = null;
    lastPrompt = '';
    records.clear();
    notifyChanged();
  }

  @override
  WorkbenchSource? get activeSource => _source;

  @override
  bool get silentEmptyPrompt => true;

  @override
  String? submitGuard(String prompt) {
    if (prompt.length > 2000) return '问题请控制在 2000 字以内。';
    if (hasExperiment && !observationReady) {
      return '等待当前布局观测完成后再提交。';
    }
    return null;
  }

  @override
  WorkbenchRequest buildRequest(String prompt) => WorkbenchRequest(
    prompt: prompt,
    snapshot: snapshot,
    components: _components.values.toList(),
    systemPrompt: _systemPrompt,
  );

  @override
  void applyStreamMessage(a2ui.A2uiMessage message) => _apply(message);

  @override
  int get maxGeneratedChars => 64000;

  @override
  String get generatedOverflowMessage => '本次生成超出 64K 字符限制。';

  @override
  String get textLeakMessage => '响应含有不完整或非协议内容，请重试。';

  @override
  String get emptyResultMessage => '响应未包含可用的 A2UI v0.9 消息。';

  @override
  String get fallbackError => '生成失败，请检查模型端点、认证、跨域与网络后重试。';

  @override
  String describeError(Object cause) => cause is FormatException
      ? cause.message
      : cause is TimeoutException
      ? '生成超时，请重试或切换回放。'
      : cause is DioException
      ? switch (cause.response?.statusCode) {
          401 || 403 => '模型服务拒绝认证，请检查临时访问令牌。',
          429 => '模型服务正忙或额度受限，请稍后重试。',
          502 => '桥接中的 Codex 调用失败，请检查 CLI 登录、可用模型和额度。',
          null => '无法连接模型服务（${cause.type.name}），请检查端点与网络。',
          final status => '模型服务返回 HTTP $status，请检查服务配置。',
        }
      : fallbackError;

  @override
  void recordError(Object cause, String message) => _record('错误', message);

  @override
  void onRunStarted(String prompt) {
    lastPrompt = prompt;
    _sentRevision = revision;
    _record('请求', prompt);
  }

  @override
  void onMessageApplied(a2ui.A2uiMessage message) =>
      _record('消息', jsonEncode(message.toJson()));

  @override
  void onSuccess(String prompt, int appliedMessages) {
    if (prompt == _explainPrompt) explanationRevision = _sentRevision;
  }

  void _apply(a2ui.A2uiMessage message) {
    if (messageSurface(message) != workbenchSurfaceId) {
      throw const FormatException('当前仅允许一个 constraint-lab 工作区。');
    }
    switch (message) {
      case a2ui.CreateSurfaceMessage m:
        if (m.catalogId != workbenchCatalogId) {
          throw const FormatException('未知组件目录。');
        }
        if (!hasSurface) {
          controller.handleMessage(message);
          for (final field in initialExperiment.keys) {
            dataModel.update(DataPath('/$field'), initialExperiment[field]);
          }
        }
      case a2ui.UpdateComponentsMessage m:
        if (!hasSurface) throw const FormatException('请先创建工作区。');
        final next = validateComponents(m.components, _components);
        controller.handleMessage(message);
        _components = next;
      case a2ui.UpdateDataModelMessage m:
        if (!hasSurface) throw const FormatException('请先创建工作区。');
        final values = m.path == '/' || m.path == null
            ? (m.value is Map
                  ? Map<String, Object?>.from(m.value as Map)
                  : throw const FormatException('状态须为对象。'))
            : <String, Object?>{m.path!.replaceFirst('/', ''): m.value};
        for (final entry in values.entries) {
          validateExperimentValue(entry.key, entry.value);
        }
        for (final entry in values.entries) {
          updateParameter(entry.key, entry.value);
        }
      case a2ui.DeleteSurfaceMessage _:
        controller.handleMessage(message);
        _components = {};
        observationRevision = null;
        explanationRevision = null;
        revision++;
      default:
        throw const FormatException('未知消息类型。');
    }
    notifyChanged();
  }

  String get _systemPrompt =>
      '''
你是 Flutter Forge 生成式实验工作区。当前只支持一个约束小实验。
仅输出换行分隔的 A2UI v0.9 JSON 消息，不输出 Markdown 或普通文本。
surfaceId 固定 $workbenchSurfaceId，catalogId 固定 $workbenchCatalogId。
首次请求需 createSurface、updateDataModel、updateComponents。后续只更新必要部分，保留未修改状态与组件。
root 必须为 LabColumn，children 为已有组件 ID 数组。只支持以下组件 schema：
${jsonEncode(catalog.items.map((item) => item.dataSchema.value).toList())}
状态只有 /parentWidth、/requestedWidth（60–300 数字）、/tight（布尔）。
组件使用固定状态绑定；模型不能写入实际尺寸。观测由 Flutter 提供，若为空不可虚构。
首次 updateComponents 必须在同一消息中给出 root 及其所有子组件的定义；之后可局部更新已有组件。
解释用 Note.text，明确依赖的 snapshot.revision。保持预览和 Observation，保留参数控件和 ExplainAction。
已有组件与最新状态会随每轮请求提供；解释动作也会携带实际状态。超出能力时用 Note 说明可操作范围。
首次消息示例：${jsonEncode(initialMessages())}
''';

  void _record(String kind, String content) => addRecord('$kind · $content');

  @override
  void dispose() {
    super.dispose();
    unawaited(_submissions.cancel());
    controller.dispose();
    _source.dispose();
  }
}
