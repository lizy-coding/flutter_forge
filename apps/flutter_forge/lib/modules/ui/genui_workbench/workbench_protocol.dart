import 'package:a2ui_core/a2ui_core.dart' as a2ui;

const workbenchSurfaceId = 'constraint-lab';
const workbenchCatalogId = 'dev.flutterforge.constraint-lab';
const initialExperiment = <String, Object?>{
  'parentWidth': 240.0,
  'requestedWidth': 120.0,
  'tight': false,
};

const workbenchComponents = <Map<String, dynamic>>[
  {
    'id': 'root',
    'component': 'LabColumn',
    'children': [
      'intro',
      'parent',
      'child',
      'mode',
      'preview',
      'result',
      'explain',
    ],
  },
  {'id': 'intro', 'component': 'Note', 'text': '改变约束，观察期望宽度与实际宽度的关系。'},
  {'id': 'parent', 'component': 'NumberControl', 'field': 'parentWidth'},
  {'id': 'child', 'component': 'NumberControl', 'field': 'requestedWidth'},
  {'id': 'mode', 'component': 'ModeControl'},
  {'id': 'preview', 'component': 'ConstraintPreview'},
  {'id': 'result', 'component': 'Observation'},
  {'id': 'explain', 'component': 'ExplainAction'},
];

Map<String, Object?> envelope(String operation, Map<String, Object?> body) => {
  'version': 'v0.9',
  operation: {'surfaceId': workbenchSurfaceId, ...body},
};

List<Map<String, Object?>> initialMessages() => [
  envelope('createSurface', {'catalogId': workbenchCatalogId}),
  envelope('updateDataModel', {'path': '/', 'value': initialExperiment}),
  envelope('updateComponents', {'components': workbenchComponents}),
];

Object validateExperimentValue(String field, Object? value) {
  if (field == 'tight' && value is bool) return value;
  if ((field == 'parentWidth' || field == 'requestedWidth') &&
      value is num &&
      value.isFinite &&
      value >= 60 &&
      value <= 300) {
    return value.toDouble();
  }
  throw const FormatException('参数仅支持 60–300dp 的宽度和布尔松紧模式。');
}

// Validate references before handing them to the recursive SDK renderer.
Map<String, Map<String, dynamic>> validateComponents(
  List<Map<String, dynamic>> updates,
  Map<String, Map<String, dynamic>> current,
) {
  const types = {
    'LabColumn',
    'Note',
    'NumberControl',
    'ModeControl',
    'ConstraintPreview',
    'Observation',
    'ExplainAction',
  };
  final next = {...current};
  for (final component in updates) {
    final id = component['id'];
    final type = component['component'];
    if (id is! String ||
        id.isEmpty ||
        id.length > 40 ||
        !types.contains(type)) {
      throw const FormatException('组件 ID 或类型不在工作区允许范围内。');
    }
    if (type == 'Note' &&
        (component['text'] is! String ||
            (component['text'] as String).length > 2000)) {
      throw const FormatException('说明文本无效或过长。');
    }
    if (type == 'NumberControl' &&
        !['parentWidth', 'requestedWidth'].contains(component['field'])) {
      throw const FormatException('未知的参数绑定。');
    }
    next[id] = Map<String, dynamic>.from(component);
  }
  if (next.length > 16 || !next.containsKey('root')) {
    throw const FormatException('工作区须包含 root，且最多 16 个组件。');
  }
  var visits = 0;
  void visit(String id, Set<String> ancestors) {
    if (++visits > 32 || ancestors.contains(id) || !next.containsKey(id)) {
      throw const FormatException('组件引用缺失、循环或重复过多。');
    }
    final node = next[id]!;
    if (node['component'] != 'LabColumn') return;
    final children = node['children'];
    if (children is! List || children.length > 8) {
      throw const FormatException('布局须提供至多 8 个子组件。');
    }
    for (final child in children) {
      if (child is! String) throw const FormatException('子组件必须引用 ID。');
      visit(child, {...ancestors, id});
    }
  }

  // Check unreachable nodes too: a later update can make them reachable.
  for (final id in next.keys) {
    visits = 0;
    visit(id, {});
  }
  final reachable = <String>{};
  void collect(String id) {
    if (!reachable.add(id)) return;
    final node = next[id]!;
    if (node['component'] == 'LabColumn') {
      for (final child in node['children'] as List) {
        collect(child as String);
      }
    }
  }

  collect('root');
  final renderedTypes = reachable.map((id) => next[id]!['component']).toList();
  if (next['root']!['component'] != 'LabColumn' ||
      ['ConstraintPreview', 'Observation', 'ExplainAction'].any(
        (type) =>
            renderedTypes.where((candidate) => candidate == type).length != 1,
      )) {
    throw const FormatException('工作区必须包含一个布局预览、观测结果和解释按钮。');
  }
  return next;
}

String messageSurface(a2ui.A2uiMessage message) => switch (message) {
  a2ui.CreateSurfaceMessage m => m.surfaceId,
  a2ui.UpdateComponentsMessage m => m.surfaceId,
  a2ui.UpdateDataModelMessage m => m.surfaceId,
  a2ui.DeleteSurfaceMessage m => m.surfaceId,
  _ => throw const FormatException('不支持的消息。'),
};
