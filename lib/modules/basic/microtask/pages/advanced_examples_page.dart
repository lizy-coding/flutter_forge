import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_study_learning/flutter_study_learning.dart';
import '../models/event_log.dart';
import '../widgets/event_log_view.dart';
import '../widgets/code_snippet_view.dart';

class AdvancedExamplesPage extends StatefulWidget {
  const AdvancedExamplesPage({super.key});

  @override
  State<AdvancedExamplesPage> createState() => _AdvancedExamplesPageState();
}

class _AdvancedExamplesPageState extends State<AdvancedExamplesPage>
    with SingleTickerProviderStateMixin {
  final List<EventLog> _logs = [];
  bool _isRunning = false;
  final ScrollController _scrollController = ScrollController();
  bool _showTimestamps = true;
  late TabController _tabController;

  final Map<String, String> _codeExamples = {
    'async/await': r'''
Future<void> example() async {
  print('函数开始');
  print('await之前的代码');
  await Future(() { print('await的Future执行'); });
  print('await之后的代码');
  await Future.delayed(Duration(milliseconds: 500));
  print('第二个await之后的代码');
}''',
    'Future.value': r'''
Future.value('immediate value').then((value) {
  print('Future.value微任务: $value');
});
Future(() { return 'computed value'; })
  .then((value) { print('普通Future: $value'); });''',
    'Future链': r'''
Future(() => print('初始Future'))
    .then((_) => print('第一个then微任务'))
    .then((_) {
      print('第二个then微任务');
      return Future(() => print('嵌套事件任务'));
    })
    .then((_) => print('第三个then微任务'));''',
    'Zone': r'''
runZoned(() {
  Future(() => print('在自定义Zone中执行的Future'));
  scheduleMicrotask(() => print('在自定义Zone中执行的微任务'));
}, zoneSpecification: ZoneSpecification(
  scheduleMicrotask: (self, parent, zone, f) {
    print('微任务被调度');
    parent.scheduleMicrotask(zone, f);
  },
));''',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _tabController.dispose();
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

  void _runAsyncAwaitTest() async {
    if (_isRunning) return;
    _isRunning = true;
    _clearLogs();
    _addLog('开始async/await测试', EventType.info);
    _addLog('代码开始执行', EventType.sync);
    _addLog('即将调用async函数', EventType.sync);
    await _executeAsyncFunction();
    _addLog('async函数调用完成', EventType.sync);
    _addLog('代码结束执行', EventType.sync);
    Future.delayed(const Duration(seconds: 2), () {
      _addLog('async/await测试结束', EventType.info);
      _isRunning = false;
    });
  }

  Future<void> _executeAsyncFunction() async {
    _addLog('async函数开始', EventType.sync);
    _addLog('await之前的代码', EventType.sync);
    await Future(() => _addLog('await的Future执行', EventType.event));
    _addLog('await之后的代码', EventType.microtask);
    await Future.delayed(
      const Duration(milliseconds: 500),
      () => _addLog('第二个await的Future执行', EventType.event),
    );
    _addLog('第二个await之后的代码', EventType.microtask);
    _addLog('async函数结束', EventType.microtask);
  }

  void _runFutureValueTest() async {
    if (_isRunning) return;
    _isRunning = true;
    _clearLogs();
    _addLog('开始Future.value测试', EventType.info);
    _addLog('代码开始执行', EventType.sync);
    Future.value(
      '立即值',
    ).then((value) => _addLog('Future.value微任务: $value', EventType.microtask));
    Future(() {
      _addLog('普通Future事件任务执行', EventType.event);
      return '计算值';
    }).then((value) => _addLog('普通Future的then回调: $value', EventType.microtask));
    scheduleMicrotask(() => _addLog('独立的微任务', EventType.microtask));
    Future(() => _addLog('独立的事件任务', EventType.event));
    _addLog('代码结束执行', EventType.sync);
    Future.delayed(const Duration(seconds: 2), () {
      _addLog('Future.value测试结束', EventType.info);
      _isRunning = false;
    });
  }

  void _runFutureChainTest() async {
    if (_isRunning) return;
    _isRunning = true;
    _clearLogs();
    _addLog('开始Future链式调用测试', EventType.info);
    _addLog('代码开始执行', EventType.sync);
    Future(() => _addLog('初始Future', EventType.event))
        .then((_) => _addLog('第一个then微任务', EventType.microtask))
        .then((_) {
          _addLog('第二个then微任务', EventType.microtask);
          return Future(() => _addLog('嵌套事件任务', EventType.event));
        })
        .then((_) => _addLog('第三个then微任务', EventType.microtask));
    scheduleMicrotask(() => _addLog('独立的微任务', EventType.microtask));
    Future(() => _addLog('独立的事件任务', EventType.event));
    _addLog('代码结束执行', EventType.sync);
    Future.delayed(const Duration(seconds: 2), () {
      _addLog('Future链式调用测试结束', EventType.info);
      _isRunning = false;
    });
  }

  void _runZoneTest() async {
    if (_isRunning) return;
    _isRunning = true;
    _clearLogs();
    _addLog('开始Zone测试', EventType.info);
    _addLog('代码开始执行', EventType.sync);
    runZoned(
      () {
        _addLog('进入自定义Zone', EventType.sync);
        Future(() => _addLog('在自定义Zone中执行的Future', EventType.event));
        scheduleMicrotask(
          () => _addLog('在自定义Zone中执行的微任务', EventType.microtask),
        );
        _addLog('离开自定义Zone', EventType.sync);
      },
      zoneSpecification: ZoneSpecification(
        scheduleMicrotask: (self, parent, zone, f) {
          _addLog('微任务被调度', EventType.info);
          parent.scheduleMicrotask(zone, f);
        },
        createTimer: (self, parent, zone, duration, f) {
          _addLog('计时器被创建，持续时间: $duration', EventType.info);
          return parent.createTimer(zone, duration, f);
        },
      ),
    );
    Future(() => _addLog('在主Zone中执行的Future', EventType.event));
    scheduleMicrotask(() => _addLog('在主Zone中执行的微任务', EventType.microtask));
    _addLog('代码结束执行', EventType.sync);
    Future.delayed(const Duration(seconds: 2), () {
      _addLog('Zone测试结束', EventType.info);
      _isRunning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LearningScaffold(
      title: '高级事件机制演示',
      floatingActionButton: FloatingActionButton(
        onPressed: _clearLogs,
        child: const Icon(Icons.delete),
      ),
      interactiveDemo: SizedBox(
        height: 500,
        child: Column(
          children: [
            SizedBox(
              height: 380,
              child: DefaultTabController(
                length: 4,
                child: Column(
                  children: [
                    TabBar(
                      controller: _tabController,
                      tabs: const [
                        Tab(text: 'async/await'),
                        Tab(text: 'Future.value'),
                        Tab(text: 'Future链'),
                        Tab(text: 'Zone'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildTabContent(
                            'async/await',
                            'async/await语法是Future的语法糖。'
                                'await会暂停函数并将后续代码包装成微任务。',
                            _runAsyncAwaitTest,
                          ),
                          _buildTabContent(
                            'Future.value',
                            'Future.value立即完成，then回调直接进微任务队列。',
                            _runFutureValueTest,
                          ),
                          _buildTabContent(
                            'Future链式调用',
                            '每个then回调都是微任务，不是事件任务。',
                            _runFutureChainTest,
                          ),
                          _buildTabContent(
                            'Zone',
                            'Zone可拦截和修改异步操作调度。',
                            _runZoneTest,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
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
            '理解 async/await 背后的微任务调度机制',
            '掌握 Future.value 与普通 Future 的区别',
            '理解 Future 链式调用中 then 回调的调度行为',
            '了解 Zone 的异步操作拦截机制',
          ],
        ),
        ConceptChips(
          concepts: ['async/await', 'Future.value', '链式调用', 'Zone', '微任务调度'],
        ),
        CodeSnippetCard(
          title: 'async/await 调度原理',
          code:
              'void main() async {\n'
              '  print("1: 同步");\n'
              '  await Future(() => print("3: 事件"));\n'
              '  print("2: await后的微任务");\n'
              '}',
          explanation: 'await 将后续代码封装为微任务，在 Future 完成后以微任务形式执行。',
        ),
        ExerciseCard(
          task: '在 Zone 测试中观察微任务调度日志，尝试理解 ZoneSpecification 的工作原理。',
          hint: 'Zone 的 scheduleMicrotask 拦截器会在每次微任务调度时触发，createTimer 拦截定时器创建。',
        ),
      ],
    );
  }

  Widget _buildTabContent(
    String title,
    String description,
    VoidCallback onRun,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(description, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: onRun,
            icon: const Icon(Icons.play_arrow),
            label: Text('运行$title测试'),
          ),
          const SizedBox(height: 4),
          CodeSnippetView(
            title: '$title 示例代码',
            code: _codeExamples[title] ?? '',
          ),
        ],
      ),
    );
  }
}
