import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:forge_articles/forge_articles.dart';
import '../../../shared/learning/learning_scaffold.dart';

const offlineArticleWorkflow = <String, dynamic>{
  'schema': 'forge.workflow.v1',
  'id': 'articles.explore',
  'version': 1,
  'steps': [
    {'id': 'fetch', 'capability': 'articles.fetch', 'version': 1},
    {'id': 'organize', 'capability': 'articles.organize', 'version': 1},
  ],
};

class OfflineWorkflowPage extends StatefulWidget {
  const OfflineWorkflowPage({super.key});

  @override
  State<OfflineWorkflowPage> createState() => _OfflineWorkflowPageState();
}

class _OfflineWorkflowPageState extends State<OfflineWorkflowPage> {
  final query = TextEditingController();
  final events = <String>[];
  CancelToken? cancel;
  Map<String, Object>? result;
  bool simulateFailure = false;
  String state = '等待执行';

  Future<void> run() async {
    if (cancel != null) return;
    final token = CancelToken();
    setState(() {
      cancel = token;
      result = null;
      events.clear();
      state = '执行中';
    });
    try {
      final output = await ArticleWorkflowRunner().run(
        definition: offlineArticleWorkflow,
        inputs: {
          'page': 1,
          'pageSize': 10,
          'delayMs': 500,
          'query': query.text.trim(),
          'simulateFailure': simulateFailure,
        },
        cancelToken: token,
        emit: (type, step) async {
          if (mounted) setState(() => events.add('$step · $type'));
        },
      );
      if (mounted) {
        setState(() {
          result = output;
          state = '执行完成';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => state = token.isCancelled ? '已取消' : '教学故障：请求失败，可关闭模拟故障后重试',
        );
      }
    } finally {
      if (mounted) setState(() => cancel = null);
    }
  }

  @override
  void dispose() {
    cancel?.cancel('离开页面');
    query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LearningScaffold(
    title: '本地文章工作流',
    interactiveDemo: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('请求模拟文章 → 筛选与排序 → 展示结果。全部在本机执行，无需服务端。'),
        TextField(
          controller: query,
          maxLength: 80,
          enabled: cancel == null,
          decoration: const InputDecoration(labelText: '筛选标题或作者'),
        ),
        SwitchListTile(
          title: const Text('模拟请求失败'),
          value: simulateFailure,
          onChanged: cancel == null
              ? (value) => setState(() => simulateFailure = value)
              : null,
        ),
        Wrap(
          spacing: 8,
          children: [
            FilledButton(
              onPressed: cancel == null ? run : null,
              child: const Text('执行本地流程'),
            ),
            OutlinedButton(
              onPressed: cancel == null ? null : () => cancel!.cancel('用户取消'),
              child: const Text('取消执行'),
            ),
          ],
        ),
        Text(state, key: const ValueKey('offline-workflow-state')),
        for (final event in events) Text(event),
        if (result != null)
          for (final row in result!['rows']! as List)
            ListTile(
              title: Text('${(row as List)[1]}'),
              subtitle: Text('${row[2]} · ID ${row[0]}'),
            ),
      ],
    ),
    sections: const [
      LearningObjectives(
        objectives: ['观察两个步骤的执行顺序', '改变输入并比较输出', '模拟故障、取消与重试'],
      ),
    ],
  );
}
