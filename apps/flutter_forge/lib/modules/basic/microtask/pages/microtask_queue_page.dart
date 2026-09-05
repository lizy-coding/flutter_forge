import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_forge_app/shared/learning/learning_scaffold.dart';
import '../models/event_log.dart';
import '../widgets/event_log_view.dart';
import '../widgets/code_snippet_view.dart';

class MicrotaskQueuePage extends StatefulWidget {
  const MicrotaskQueuePage({super.key});

  @override
  State<MicrotaskQueuePage> createState() => _MicrotaskQueuePageState();
}

class _MicrotaskQueuePageState extends State<MicrotaskQueuePage> {
  final List<EventLog> _logs = [];
  bool _isRunning = false;
  final ScrollController _scrollController = ScrollController();
  final bool _showTimestamps = true;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _addLog(String message, EventType type) {
    if (!_isRunning) return;
    setState(() {
      _logs.add(EventLog(message: message, type: type, id: _logs.length + 1));
    });
    scheduleMicrotask(_scrollToBottom);
  }

  void _clearLogs() {
    setState(() => _logs.clear());
  }

  void _runBasicMicrotaskTest() async {
    if (_isRunning) return;
    _isRunning = true;
    _clearLogs();
    _addLog('开始微任务队列测试', EventType.info);
    _addLog('代码开始执行', EventType.sync);
    Future(() => _addLog('事件任务执行', EventType.event));
    scheduleMicrotask(
      () => _addLog('scheduleMicrotask 微任务1执行', EventType.microtask),
    );
    Future.microtask(
      () => _addLog('Future.microtask 微任务2执行', EventType.microtask),
    );
    Future(() => _addLog('另一个事件任务执行', EventType.event));
    scheduleMicrotask(
      () => _addLog('scheduleMicrotask 微任务3执行', EventType.microtask),
    );
    _addLog('代码结束执行', EventType.sync);
    Future.delayed(const Duration(seconds: 2), () {
      _addLog('微任务队列测试结束', EventType.info);
      _isRunning = false;
    });
  }

  void _runThenMicrotaskTest() async {
    if (_isRunning) return;
    _isRunning = true;
    _clearLogs();
    _addLog('开始Future.then微任务测试', EventType.info);
    _addLog('代码开始执行', EventType.sync);
    Future(() => _addLog('Future事件任务执行', EventType.event))
        .then((_) => _addLog('Future.then微任务1执行', EventType.microtask))
        .then((_) => _addLog('Future.then微任务2执行', EventType.microtask));
    Future(() => _addLog('另一个事件任务执行', EventType.event));
    scheduleMicrotask(
      () => _addLog('scheduleMicrotask 微任务执行', EventType.microtask),
    );
    _addLog('代码结束执行', EventType.sync);
    Future.delayed(const Duration(seconds: 2), () {
      _addLog('Future.then微任务测试结束', EventType.info);
      _isRunning = false;
    });
  }

  void _runNestedMicrotaskTest() async {
    if (_isRunning) return;
    _isRunning = true;
    _clearLogs();
    _addLog('开始嵌套微任务测试', EventType.info);
    _addLog('代码开始执行', EventType.sync);
    scheduleMicrotask(() {
      _addLog('外层微任务1执行', EventType.microtask);
      scheduleMicrotask(() => _addLog('嵌套微任务1执行', EventType.microtask));
      scheduleMicrotask(() {
        _addLog('嵌套微任务2执行', EventType.microtask);
        scheduleMicrotask(() => _addLog('二层嵌套微任务执行', EventType.microtask));
      });
      _addLog('外层微任务1继续执行', EventType.microtask);
    });
    scheduleMicrotask(() => _addLog('外层微任务2执行', EventType.microtask));
    Future(() => _addLog('事件任务执行', EventType.event));
    _addLog('代码结束执行', EventType.sync);
    Future.delayed(const Duration(seconds: 2), () {
      _addLog('嵌套微任务测试结束', EventType.info);
      _isRunning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LearningScaffold(
      title: '微任务队列演示',
      floatingActionButton: FloatingActionButton(
        onPressed: _clearLogs,
        child: const Icon(Icons.delete),
      ),
      interactiveDemo: SizedBox(
        height: 500,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _runBasicMicrotaskTest,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('基础微任务测试'),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _runThenMicrotaskTest,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Future.then测试'),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _runNestedMicrotaskTest,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('嵌套微任务测试'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const CodeSnippetView(
              title: 'Microtask Queue 示例代码',
              code: '''
scheduleMicrotask(() { print('微任务执行'); });
Future.microtask(() { print('另一个微任务执行'); });
Future(() { print('事件任务执行'); })
  .then((_) { print('then回调作为微任务执行'); });''',
            ),
            const SizedBox(height: 8),
            Expanded(
              child: EventLogView(
                logs: _logs,
                showTimestamp: _showTimestamps,
                scrollController: _scrollController,
              ),
            ),
          ],
        ),
      ),
      sections: const [
        LearningObjectives(
          objectives: [
            '理解微任务队列 (Microtask Queue) 的优先级特性',
            '掌握 scheduleMicrotask 和 Future.microtask 的使用',
            '理解 Future.then 回调作为微任务执行的机制',
            '掌握嵌套微任务的行为特征',
          ],
        ),
        ConceptChips(
          concepts: [
            '微任务队列',
            'scheduleMicrotask',
            'Future.microtask',
            'Future.then',
            '优先级',
            '嵌套微任务',
          ],
        ),
        CodeSnippetCard(
          title: '微任务优先级示例',
          code:
              'scheduleMicrotask(() => print("1: 微任务"));\n'
              'Future(() => print("3: 事件任务"));\n'
              'scheduleMicrotask(() => print("2: 微任务"));',
          explanation: '微任务始终在事件任务之前执行，即使微任务在事件任务之后注册。',
        ),
        CommonPitfalls(
          pitfalls: [
            '微任务过多会导致事件队列饿死 — UI事件（触摸、渲染）也无法处理',
            'scheduleMicrotask 嵌套调用会递归清空微任务队列，可能导致长时间阻塞',
            'Future.then 是微任务不是事件任务 — 注意与 Future 本身的区别',
          ],
        ),
        ExerciseCard(
          task: '运行"嵌套微任务测试"观察执行顺序，理解为什么嵌套微任务会先于事件任务执行。',
          hint: '微任务队列的"清空"策略是持续处理直到队列为空，新添加的微任务也会在当前批次处理。',
        ),
      ],
    );
  }
}
