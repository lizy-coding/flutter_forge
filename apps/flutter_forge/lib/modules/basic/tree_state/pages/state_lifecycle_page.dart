import 'package:flutter/material.dart';
import 'package:flutter_study_learning/flutter_study_learning.dart';

/// 侧重打印 StatefulWidget 生命周期，配合 push/pop、setState 观察回调顺序。
class StateLifecyclePage extends StatefulWidget {
  const StateLifecyclePage({super.key});

  @override
  State<StateLifecyclePage> createState() => _StateLifecyclePageState();
}

class _StateLifecyclePageState extends State<StateLifecyclePage> {
  int _counter = 0;
  final List<String> _logs = [];

  @override
  void initState() {
    super.initState();
    debugPrint('[StateLifecyclePage] initState');
    _logs.add('initState 执行');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    debugPrint('[StateLifecyclePage] didChangeDependencies');
    _logs.add('didChangeDependencies');
  }

  @override
  void didUpdateWidget(covariant StateLifecyclePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    debugPrint('[StateLifecyclePage] didUpdateWidget');
  }

  @override
  void deactivate() {
    debugPrint('[StateLifecyclePage] deactivate');
    super.deactivate();
  }

  @override
  void dispose() {
    debugPrint('[StateLifecyclePage] dispose');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('[StateLifecyclePage] build counter=$_counter');
    return LearningScaffold(
      title: 'State Lifecycle',
      interactiveDemo: SizedBox(
        height: 320,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('StatefulWidget 生命周期 + setState 行为'),
              const SizedBox(height: 16),
              Text('Counter: $_counter'),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _counter++;
                      });
                      final msg = 'setState → $_counter';
                      debugPrint('[StateLifecyclePage] $msg');
                      _logs.add(msg);
                    },
                    child: const Text('setState +1'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      debugPrint('[StateLifecyclePage] push sample page');
                      _logs.add('push ChildPage');
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const LifecycleChildPage(),
                        ),
                      );
                      debugPrint('[StateLifecyclePage] pop sample page');
                      _logs.add('pop from ChildPage');
                    },
                    child: const Text('Push & Pop 页面'),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _logs.clear()),
                    child: const Text('清空日志'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView(
                    children: _logs.isEmpty
                        ? [
                            const Text(
                              '操作按钮观察生命周期日志',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ]
                        : _logs
                              .map(
                                (l) => Text(
                                  l,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              )
                              .toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      sections: const [
        LearningObjectives(
          objectives: [
            '理解 StatefulWidget 完整的生命周期回调顺序',
            '观察 setState 触发的 build 过程',
            '理解 push/pop 时 deactivate 与 dispose 的触发时机',
          ],
        ),
        ConceptChips(
          concepts: [
            'initState',
            'didChangeDependencies',
            'build',
            'setState',
            'didUpdateWidget',
            'deactivate',
            'dispose',
          ],
        ),
        CodeSnippetCard(
          title: '生命周期的正确用法',
          code: '''@override
void initState() {
  super.initState();
  // 初始化数据、监听器、控制器
  _controller = AnimationController(vsync: this);
}

@override
void dispose() {
  _controller.dispose();  // 清理资源
  super.dispose();
}''',
          explanation: 'initState 中初始化资源，dispose 中释放资源，成对出现防止内存泄漏。',
        ),
        CommonPitfalls(
          pitfalls: [
            '不要在 initState 中调用 BuildContext 相关方法（如 MediaQuery.of），应使用 didChangeDependencies',
            'dispose 中记得释放 AnimationController、StreamSubscription 等资源',
            'didUpdateWidget 的参数是 oldWidget，可通过 widget 属性访问当前 widget',
          ],
        ),
        ExerciseCard(
          task:
              '点击「Push & Pop 页面」观察 deactivate 和 dispose 的调用顺序。思考：为什么 deactivate 在 dispose 之前被调用？',
          hint:
              'deactivate 允许 State 被重新插入 Element 树（GlobalKey 移动场景），dispose 是最终销毁。',
        ),
      ],
    );
  }
}

class LifecycleChildPage extends StatelessWidget {
  const LifecycleChildPage({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint('[LifecycleChildPage] build');
    return Scaffold(
      appBar: AppBar(title: const Text('Child Page')),
      body: const Center(child: Text('观察父页面 push/pop 时的生命周期日志')),
    );
  }
}
