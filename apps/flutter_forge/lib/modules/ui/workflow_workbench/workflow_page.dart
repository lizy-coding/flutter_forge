import 'dart:async';

import 'package:a2ui_core/a2ui_core.dart' as a2ui;
import 'package:flutter/material.dart';
import 'package:genui/genui.dart' as genui;
import 'package:json_schema_builder/json_schema_builder.dart';
import 'package:flutter_forge_app/shared/learning/learning_scaffold.dart';
import 'package:flutter_forge_app/shared/table/scroll_table.dart';
import 'package:flutter_forge_app/shared/workflows/hub_client.dart';

import 'workflow_session.dart';

class WorkflowPage extends StatefulWidget {
  const WorkflowPage({super.key, this.session});
  final WorkflowSession? session;
  @override
  State<WorkflowPage> createState() => _WorkflowPageState();
}

class _WorkflowPageState extends State<WorkflowPage> {
  late final session = widget.session ?? WorkflowSession();
  late final genui.SurfaceController surface;

  @override
  void initState() {
    super.initState();
    final catalog = genui.Catalog([
      genui.column,
      genui.CatalogItem(
        name: 'WorkflowParameters',
        dataSchema: S.object(),
        widgetBuilder: (_) => _parameters(),
      ),
      genui.CatalogItem(
        name: 'WorkflowState',
        dataSchema: S.object(),
        widgetBuilder: (item) => genui.BoundString(
          dataContext: item.dataContext,
          value: const {'path': '/state'},
          builder: (context, value) => Text(
            'Hub 运行状态：${value ?? 'idle'}',
            key: const ValueKey('workflow-state'),
          ),
        ),
      ),
      genui.CatalogItem(
        name: 'WorkflowResult',
        dataSchema: S.object(),
        widgetBuilder: (_) => _result(),
      ),
    ], catalogId: 'dev.flutterforge.workflow-v1');
    surface = genui.SurfaceController(catalogs: [catalog]);
    surface.handleMessage(
      a2ui.CreateSurfaceMessage(
        surfaceId: 'workflow',
        catalogId: 'dev.flutterforge.workflow-v1',
      ),
    );
    surface.handleMessage(
      a2ui.UpdateComponentsMessage(
        surfaceId: 'workflow',
        components: [
          {
            'id': 'root',
            'component': 'Column',
            'align': 'stretch',
            'children': ['parameters', 'state', 'result'],
          },
          {'id': 'parameters', 'component': 'WorkflowParameters'},
          {'id': 'state', 'component': 'WorkflowState'},
          {'id': 'result', 'component': 'WorkflowResult'},
        ],
      ),
    );
    session.addListener(_sync);
    _sync();
  }

  void _sync() {
    surface
        .contextFor('workflow')
        .dataModel
        .update(genui.DataPath('/state'), session.state);
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    session.removeListener(_sync);
    if (widget.session == null) session.dispose();
    surface.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.surface,
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '跨项目工作流实验室',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              const Text(
                'Forge 执行核心能力，Hub 保存流程版本、调度与运行记录，GenUI 组织参数和结果。当前使用教学模拟数据，不调用外部模型。',
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: session.busy || session.connecting
                        ? null
                        : _connect,
                    icon: const Icon(Icons.hub_outlined),
                    label: Text(
                      session.connected ? '重新连接 Hub' : '连接 Agent Hub',
                    ),
                  ),
                  Chip(label: Text(session.connected ? 'Hub 已连接' : '等待 Hub')),
                  if (session.connecting)
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(),
                    ),
                ],
              ),
              SelectableText('执行端：${session.executorId}'),
              if (session.definition != null) ...[
                const SizedBox(height: 12),
                Text(
                  '流程：${session.definition!['id']} · v${session.definition!['version']}',
                ),
                const Text('请求文章 → 筛选整理 → 表格结果'),
              ],
              if (session.error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    session.error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              genui.Surface(surfaceContext: surface.contextFor('workflow')),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                children: [
                  FilledButton(
                    onPressed: !session.connected || session.busy
                        ? null
                        : () => unawaited(session.submit()),
                    child: Text(
                      ['failed', 'cancelled'].contains(session.state)
                          ? '重试当前参数（新运行）'
                          : '运行流程',
                    ),
                  ),
                  OutlinedButton(
                    onPressed: session.busy
                        ? () => unawaited(session.cancel())
                        : null,
                    child: const Text('取消运行'),
                  ),
                  TextButton(
                    onPressed: session.connected
                        ? () => unawaited(session.poll())
                        : null,
                    child: const Text('刷新 Hub 记录'),
                  ),
                ],
              ),
              if (session.busy) const LinearProgressIndicator(),
              ExpansionTile(
                title: const Text('运行事件与历史'),
                expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (session.current != null) ...[
                    SelectableText('Run ID：${session.current!['id']}'),
                    if (session.current!['error'] != null)
                      Text('${session.current!['error']}'),
                    for (final event in session.current!['events'] as List)
                      Text(
                        '#${event['seq']} ${event['kind']} ${event['stepId'] ?? ''}',
                      ),
                  ],
                  for (final run in session.history)
                    TextButton(
                      onPressed: session.busy
                          ? null
                          : () =>
                                unawaited(session.select(run['id'] as String)),
                      child: Text(
                        '${run['id']} · ${run['state']}${run['retryOf'] == null ? '' : ' · 重试记录'}',
                      ),
                    ),
                ],
              ),
              const ExpansionTile(
                title: Text('理解这条生态链'),
                children: [
                  LearningObjectives(
                    objectives: [
                      '流程版本和每次运行由 Hub 保存。',
                      '文章请求与整理在独立能力包中执行，不依赖页面。',
                      '参数表单来自输入 schema，表格复用共享组件。',
                      '这是低代码基建的首条固定流程，节点编辑和字段映射后续逐步补齐。',
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _parameters() {
    final definition = session.definition;
    if (definition == null) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('启动本机 Hub 工作流服务并连接后，可读取流程版本和输入 schema。'),
      );
    }
    final fields = ((definition['inputSchema'] as Map)['properties'] as Map)
        .cast<String, dynamic>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final entry in fields.entries)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: switch (entry.value['type']) {
              'integer' => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${entry.value['title']}：${session.inputs[entry.key]}'),
                  Slider(
                    key: ValueKey('workflow-input-${entry.key}'),
                    value: (session.inputs[entry.key] as num).toDouble(),
                    min: (entry.value['minimum'] as num).toDouble(),
                    max: (entry.value['maximum'] as num).toDouble(),
                    divisions: entry.key == 'delayMs' ? 50 : 19,
                    onChanged: session.busy
                        ? null
                        : (value) =>
                              session.parameter(entry.key, value.round()),
                  ),
                ],
              ),
              'boolean' => SwitchListTile(
                key: ValueKey('workflow-input-${entry.key}'),
                title: Text(entry.value['title'] as String),
                value: session.inputs[entry.key] as bool,
                onChanged: session.busy
                    ? null
                    : (value) => session.parameter(entry.key, value),
              ),
              _ => TextFormField(
                key: ValueKey(
                  'workflow-input-${definition['version']}-${entry.key}',
                ),
                initialValue: session.inputs[entry.key] as String,
                enabled: !session.busy,
                maxLength: entry.value['maxLength'] as int?,
                decoration: InputDecoration(
                  labelText: entry.value['title'] as String,
                ),
                onChanged: (value) => session.parameter(entry.key, value),
              ),
            },
          ),
      ],
    );
  }

  Widget _result() {
    final result = session.current?['result'];
    if (result is! Map) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Text('完成运行后显示 Hub 已接收的结果。'),
      );
    }
    final rows = (result['rows'] as List)
        .map((row) => (row as List).cast<String>())
        .toList();
    if (rows.isEmpty) return const Text('流程已完成，筛选结果为空。');
    return SizedBox(
      height: 300,
      child: DefaultTextStyle.merge(
        style: const TextStyle(color: Colors.black87),
        child: ScrollTable(
          columnHeaders: (result['columns'] as List).cast<String>(),
          rowHeaders: [for (var i = 0; i < rows.length; i++) '${i + 1}'],
          data: rows,
          onCellTap: (row, _) => showDialog<void>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('结果行'),
              content: SelectableText(rows[row].join('\n')),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('关闭'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _connect() async {
    final client = await showDialog<WorkflowHubClient>(
      context: context,
      builder: (_) => const _HubDialog(),
    );
    if (client == null) return;
    if (!mounted) {
      client.close();
      return;
    }
    await session.connect(client);
  }
}

class _HubDialog extends StatefulWidget {
  const _HubDialog();
  @override
  State<_HubDialog> createState() => _HubDialogState();
}

class _HubDialogState extends State<_HubDialog> {
  final endpoint = TextEditingController(text: 'http://127.0.0.1:8768');
  final token = TextEditingController();
  String? error;
  @override
  void dispose() {
    endpoint.dispose();
    token.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('连接 Agent Hub 工作流服务'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('运行记录保存在 Hub；当前页面作为一个执行端领取任务。连接配置仅保留在当前页面。'),
          TextField(
            controller: endpoint,
            decoration: const InputDecoration(labelText: 'Hub 根地址'),
          ),
          TextField(
            key: const ValueKey('workflow-hub-token'),
            controller: token,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Hub 临时访问令牌'),
          ),
          if (error != null) Text(error!),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('取消'),
      ),
      FilledButton(
        onPressed: () {
          try {
            if (token.text.trim().isEmpty) {
              throw const FormatException('请输入临时访问令牌。');
            }
            final client = WorkflowHubClient(
              endpoint: Uri.parse(endpoint.text.trim()),
              token: token.text.trim(),
            );
            Navigator.pop(context, client);
          } catch (_) {
            setState(() => error = '请检查 Hub 地址和临时令牌。');
          }
        },
        child: const Text('连接'),
      ),
    ],
  );
}
