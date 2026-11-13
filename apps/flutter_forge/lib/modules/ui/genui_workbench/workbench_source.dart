import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import 'workbench_protocol.dart';

import '../../../shared/genui/model_source.dart';
import '../../../shared/platform/build_features.dart';
export '../../../shared/genui/model_source.dart';

class ReplayWorkbenchSource implements WorkbenchSource {
  @override
  String get label => '固定消息回放 · 未调用模型';
  @override
  bool get isReplay => true;

  @override
  Stream<String> generate(
    WorkbenchRequest request,
    CancelToken cancelToken,
  ) async* {
    final prompt = request.prompt;
    final explain = prompt == '解释当前结果';
    if (!explain && !['宽度', '约束', 'tight', 'loose'].any(prompt.contains)) {
      throw const FormatException(
        offlineEdition
            ? '离线回放支持宽度、松紧约束示例与“解释当前结果”。请选择一个约束问题。'
            : '回放仅支持约束示例与“解释当前结果”。自由探索请配置真实模型。',
      );
    }
    if (request.components.isEmpty) {
      for (final message in initialMessages()) {
        yield '${jsonEncode(message)}\n';
      }
    }
    if (!explain) {
      if (prompt.contains('紧') || prompt.contains('tight')) {
        yield '${jsonEncode(envelope('updateDataModel', {'path': '/tight', 'value': true}))}\n';
      } else if (prompt.contains('松') || prompt.contains('loose')) {
        yield '${jsonEncode(envelope('updateDataModel', {'path': '/tight', 'value': false}))}\n';
      }
    }
    final tight = explain
        ? request.snapshot['tight'] == true
        : (prompt.contains('紧') || prompt.contains('tight'))
        ? true
        : (prompt.contains('松') || prompt.contains('loose'))
        ? false
        : request.snapshot['tight'] == true;
    final actual = request.snapshot['actualWidth'];
    final note = explain
        ? '回放规则说明（状态 v${request.snapshot['revision']}）：'
              '${tight ? '紧约束要求子组件使用父容器指定宽度。' : '松约束允许期望宽度，但不能超过父容器最大宽度。'}'
              '当前 Flutter 实际宽度：$actual dp。此说明来自预设规则。'
        : '${tight ? '紧' : '松'}约束实验已准备好。拖动参数后可请求解释；回放不理解任意自然语言。';
    yield '${jsonEncode(envelope('updateComponents', {
      'components': [
        {'id': 'intro', 'component': 'Note', 'text': note},
      ],
    }))}\n';
  }

  @override
  void dispose() {}
}
