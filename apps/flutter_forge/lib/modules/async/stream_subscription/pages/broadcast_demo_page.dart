import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_study_learning/flutter_study_learning.dart';

class BroadcastDemoPage extends StatefulWidget {
  const BroadcastDemoPage({super.key});

  @override
  State<BroadcastDemoPage> createState() => _BroadcastDemoPageState();
}

class _BroadcastDemoPageState extends State<BroadcastDemoPage> {
  late StreamController<String> _broadcastController;
  bool _isPushingActive = false;
  int _pushCount = 0;
  int _interval = 2;
  Timer? _timer;
  final List<_Subscriber> _subscribers = [];

  @override
  void initState() {
    super.initState();
    _initBroadcastStream();
  }

  void _initBroadcastStream() {
    _broadcastController = StreamController<String>.broadcast(
      onListen: () => debugPrint('有人开始监听广播Stream'),
      onCancel: () => debugPrint('有人取消监听广播Stream'),
    );
  }

  void _startPushing() {
    if (_isPushingActive) return;
    setState(() => _isPushingActive = true);

    _timer = Timer.periodic(Duration(seconds: _interval), (timer) {
      if (!_isPushingActive) {
        timer.cancel();
        _timer = null;
        return;
      }
      _pushCount++;
      final message =
          '广播消息 #$_pushCount - ${DateTime.now().toString().substring(11, 19)}';
      if (!_broadcastController.isClosed) {
        _broadcastController.add(message);
      }
    });
    _showMessage('开始推送消息');
  }

  void _stopPushing() {
    if (!_isPushingActive) return;
    setState(() => _isPushingActive = false);
    _timer?.cancel();
    _timer = null;
    _showMessage('停止推送消息');
  }

  void _addSubscriber() {
    final subscriberId = _subscribers.length + 1;
    final subscriber = _Subscriber(
      id: subscriberId,
      name: '订阅者 $subscriberId',
      subscription: _broadcastController.stream.listen(
        (data) {
          setState(() {
            _subscribers
                .firstWhere((s) => s.id == subscriberId)
                .messages
                .add(data);
          });
        },
        onError: (error) {
          _showMessage('订阅者 $subscriberId 收到错误: $error');
        },
        onDone: () {
          _showMessage('订阅者 $subscriberId 的Stream已关闭');
        },
      ),
    );
    setState(() => _subscribers.add(subscriber));
    _showMessage('添加了新订阅者: ${subscriber.name}');
  }

  void _removeSubscriber(int id) {
    final subscriber = _subscribers.firstWhere((s) => s.id == id);
    subscriber.subscription.cancel();
    setState(() => _subscribers.remove(subscriber));
    _showMessage('移除了订阅者: ${subscriber.name}');
  }

  void _addError() {
    if (!_isPushingActive) {
      _showMessage('请先开始推送');
      return;
    }
    if (!_broadcastController.isClosed) {
      _broadcastController.addError('模拟的广播错误事件');
      _showMessage('添加了错误事件');
    }
  }

  void _closeStream() {
    if (_broadcastController.isClosed) {
      _showMessage('Stream已经关闭');
      return;
    }
    _stopPushing();
    _broadcastController.close();
    _initBroadcastStream();
    setState(() => _subscribers.clear());
    _showMessage('Stream已关闭，所有订阅已移除');
  }

  void _changeInterval(int newInterval) {
    if (newInterval < 1) return;
    setState(() => _interval = newInterval);
    if (_isPushingActive) {
      _stopPushing();
      _startPushing();
    }
    _showMessage('推送间隔已设置为 $_interval 秒');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var subscriber in _subscribers) {
      subscriber.subscription.cancel();
    }
    if (!_broadcastController.isClosed) {
      _broadcastController.close();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LearningScaffold(
      title: 'Stream 广播订阅示例',
      interactiveDemo: SizedBox(
        height: 500,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '控制面板',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: _isPushingActive ? null : _startPushing,
                          child: const Text('开始推送'),
                        ),
                        ElevatedButton(
                          onPressed: !_isPushingActive ? null : _stopPushing,
                          child: const Text('停止推送'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: _addSubscriber,
                          child: const Text('添加订阅者'),
                        ),
                        ElevatedButton(
                          onPressed: _addError,
                          child: const Text('添加错误'),
                        ),
                        ElevatedButton(
                          onPressed: _closeStream,
                          child: const Text('关闭Stream'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('推送间隔: '),
                        DropdownButton<int>(
                          value: _interval,
                          items: [1, 2, 3, 5].map((value) {
                            return DropdownMenuItem<int>(
                              value: value,
                              child: Text('$value秒'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) _changeInterval(value);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                '订阅者 (${_subscribers.length}):',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: _subscribers.isEmpty
                  ? const Center(child: Text('暂无订阅者，请添加'))
                  : ListView.builder(
                      itemCount: _subscribers.length,
                      itemBuilder: (context, index) {
                        final subscriber = _subscribers[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ListTile(
                                title: Text(subscriber.name),
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () =>
                                      _removeSubscriber(subscriber.id),
                                ),
                              ),
                              const Divider(),
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: Text(
                                  '收到的消息 (${subscriber.messages.length}):',
                                ),
                              ),
                              SizedBox(
                                height: 80,
                                child: subscriber.messages.isEmpty
                                    ? const Center(child: Text('暂无消息'))
                                    : ListView.builder(
                                        itemCount: subscriber.messages.length,
                                        itemBuilder: (context, messageIndex) {
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 2,
                                            ),
                                            child: Text(
                                              subscriber.messages[messageIndex],
                                              style: TextStyle(
                                                color: Colors.blue.shade700,
                                                fontSize: 12,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '状态: ${_isPushingActive ? "推送中" : "已停止"} | '
                '订阅者数量: ${_subscribers.length}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _isPushingActive ? Colors.green : Colors.red,
                ),
              ),
            ),
          ],
        ),
      ),
      sections: const [
        LearningObjectives(
          objectives: [
            '理解广播 Stream 的多订阅者特性',
            '掌握 StreamController.broadcast() 的创建与使用',
            '学会管理多个 StreamSubscription 的生命周期',
          ],
        ),
        ConceptChips(
          concepts: ['广播 Stream', '多订阅者', 'StreamController', '错误处理', '定时推送'],
        ),
        CodeSnippetCard(
          title: '广播模式核心代码',
          code:
              'final controller = StreamController<String>.broadcast(\n'
              '  onListen: () => print("首次订阅"),\n'
              '  onCancel: () => print("末次取消"),\n'
              ');\n'
              'final sub1 = controller.stream.listen((d) => print(d));\n'
              'final sub2 = controller.stream.listen((d) => print(d));\n'
              'controller.add("hello"); // 两个订阅者都收到',
          explanation: '广播流允许任意数量的监听器同时订阅同一个数据源。',
        ),
        CommonPitfalls(
          pitfalls: [
            '广播 Stream 没有缓存 — 在订阅前发送的消息会被丢失',
            'onListen 只在第一个订阅者加入时触发，onCancel 在最后一个离开时触发',
            'close() 后不能再用 add()，需重新创建 StreamController',
          ],
        ),
        ExerciseCard(
          task: '为每个订阅者设置独立的过滤器，让其只接收包含特定关键词的消息。',
          hint:
              '在 stream.listen() 前使用 .where((msg) => msg.contains(keyword)) 进行过滤。',
        ),
      ],
    );
  }
}

class _Subscriber {
  final int id;
  final String name;
  final StreamSubscription<String> subscription;
  final List<String> messages = [];

  _Subscriber({
    required this.id,
    required this.name,
    required this.subscription,
  });
}
