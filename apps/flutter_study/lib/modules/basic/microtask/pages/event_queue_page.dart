import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_study_learning/flutter_study_learning.dart';
import '../models/event_log.dart';
import '../widgets/event_log_view.dart';
import '../widgets/code_snippet_view.dart';

class EventQueuePage extends StatefulWidget {
  const EventQueuePage({super.key});

  @override
  State<EventQueuePage> createState() => _EventQueuePageState();
}

class _EventQueuePageState extends State<EventQueuePage> {
  final List<EventLog> _logs = [];
  bool _isRunning = false;
  final ScrollController _scrollController = ScrollController();
  bool _showTimestamps = true;

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

  void _runBasicEventTest() async {
    if (_isRunning) return;
    _isRunning = true;
    _clearLogs();
    _addLog('开始事件队列测试', EventType.info);
    _addLog('代码开始执行', EventType.sync);
    Future(() => _addLog('Future() 执行', EventType.event));
    Future.delayed(
      const Duration(milliseconds: 500),
      () => _addLog('Future.delayed 0.5秒后执行', EventType.event),
    );
    Future.delayed(
      const Duration(seconds: 1),
      () => _addLog('Future.delayed 1秒后执行', EventType.event),
    );
    Future.delayed(
      const Duration(seconds: 2),
      () => _addLog('Future.delayed 2秒后执行', EventType.event),
    );
    Timer.run(() => _addLog('Timer.run 执行', EventType.event));
    _addLog('代码结束执行', EventType.sync);
    Future.delayed(const Duration(seconds: 3), () {
      _addLog('事件队列测试结束', EventType.info);
      _isRunning = false;
    });
  }

  void _runIoEventTest() async {
    if (_isRunning) return;
    _isRunning = true;
    _clearLogs();
    _addLog('开始IO事件测试', EventType.info);
    _addLog('代码开始执行', EventType.sync);
    Future(() {
      _addLog('模拟IO操作开始', EventType.event);
      return Future.delayed(const Duration(seconds: 1), () => '数据加载完成');
    }).then((result) {
      _addLog('IO操作结果: $result', EventType.event);
    });
    Future.wait([
      Future.delayed(
        const Duration(milliseconds: 800),
        () => _addLog('并发IO操作1完成', EventType.event),
      ),
      Future.delayed(
        const Duration(milliseconds: 1200),
        () => _addLog('并发IO操作2完成', EventType.event),
      ),
    ]).then((results) {
      _addLog('所有并发操作完成: $results', EventType.event);
    });
    _addLog('代码结束执行', EventType.sync);
    Future.delayed(const Duration(seconds: 3), () {
      _addLog('IO事件测试结束', EventType.info);
      _isRunning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LearningScaffold(
      title: '事件队列演示',
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
                    onPressed: _runBasicEventTest,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('基础事件队列测试'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _runIoEventTest,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('IO事件测试'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const CodeSnippetView(
              title: 'Event Queue 示例代码',
              code: '''
Future(() { print('事件队列任务执行'); });
Future.delayed(Duration(seconds: 1), () {
  print('延迟1秒后执行的事件队列任务');
});
Timer.run(() { print('Timer事件队列任务执行'); });''',
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
      sections: [
        LearningObjectives(
          objectives: [
            '理解事件队列 (Event Queue) 的工作原理',
            '掌握 Future、Future.delayed、Timer.run 的调度行为',
            '区分同步代码与事件队列任务的执行顺序',
          ],
        ),
        ConceptChips(concepts: ['事件队列', 'Future', 'Timer', '异步调度', '执行顺序']),
        CodeSnippetCard(
          title: '事件队列调度机制',
          code:
              '// 事件队列任务总是在当前同步代码之后执行\n'
              'print("1: 同步");\n'
              'Future(() => print("3: 事件任务"));\n'
              'print("2: 同步");',
          explanation: 'Future() 将回调放入事件队列，在当前帧同步代码执行完毕后触发。',
        ),
        CommonPitfalls(
          pitfalls: [
            'Future.delayed 即使延迟为 0 也会进入事件队列，不会在当前帧执行',
            '多个 Future.delayed 按延迟时间排序，但同延迟时按注册顺序执行',
            'Timer.run 等价于 Future(null)，回调在事件队列中执行',
          ],
        ),
        ExerciseCard(
          task: '修改 _runBasicEventTest 中的延迟时间，观察执行顺序的变化。',
          hint: '尝试将 Future.delayed 的延迟时间设为相同值，观察按注册顺序执行的特点。',
        ),
      ],
    );
  }
}
