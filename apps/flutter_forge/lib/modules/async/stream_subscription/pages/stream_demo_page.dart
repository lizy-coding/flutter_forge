import 'package:flutter/material.dart';
import 'package:flutter_forge_app/shared/learning/learning_scaffold.dart';

import 'stream_demo_controller.dart';

class StreamDemoPage extends StatefulWidget {
  const StreamDemoPage({super.key});

  @override
  State<StreamDemoPage> createState() => _StreamDemoPageState();
}

class _StreamDemoPageState extends State<StreamDemoPage> {
  late final StreamDemoController controller;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    controller = StreamDemoController();
    controller.addListener(() {
      if (_scrollController.hasClients) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return LearningScaffold(
          title: 'Stream 单订阅示例',
          interactiveDemo: _buildInteractiveDemo(context),
          sections: [
            const LearningObjectives(
              objectives: [
                '理解 Stream 的「推」模式——数据从生产者到消费者的异步流动。',
                '掌握 StreamController 的创建与事件推送（add、addError、close）。',
                '学习 StreamSubscription 的 listen、cancel 生命周期管理。',
                '理解单订阅流（single-subscription）只能有一个监听器。',
                '掌握定时推送与消息接收的异步协作模式。',
              ],
            ),
            const ConceptChips(
              concepts: [
                'Stream',
                'StreamController',
                'StreamSubscription',
                'listen',
                'cancel',
                'Timer',
                'ChangeNotifier',
              ],
            ),
            const CodeSnippetCard(
              title: 'Stream 创建与订阅',
              code: '''// 创建 StreamController
final _controller = StreamController<String>();

// 推送数据
_controller.add('消息内容');

// 注入错误
_controller.addError('错误信息');

// 订阅流
_subscription = _controller.stream.listen(
  (data) => print('收到: \$data'),
  onError: (e) => print('错误: \$e'),
  onDone: () => print('流关闭'),
);

// 取消订阅
_subscription?.cancel();

// 关闭流
_controller.close();''',
              explanation:
                  'StreamController 管理数据生产，stream.listen 返回 StreamSubscription 用于管理消费端生命周期。',
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: SizedBox(
                  height: 120,
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: controller.messages.length,
                    itemBuilder: (context, index) {
                      return Text(
                        controller.messages[index],
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            const CommonPitfalls(
              pitfalls: [
                '单订阅流不能多次调用 listen——第二次调用会抛出异常。需要广播流（broadcast）实现多监听。',
                '忘记 cancel() 订阅会导致内存泄漏，StreamController 不会被垃圾回收。',
                '未处理 onError 时，错误会冒泡到 Zone 层，可能导致应用崩溃。',
                'Stream 关闭后不能再推送数据，需要重新创建 StreamController。',
                'Timer.periodic 不会自动停止，务必在 dispose 中 cancel。',
              ],
            ),
            const ExerciseCard(
              task: '修改代码让 Stream 每次推送的数据中包含当前时间格式化的描述，观察消息列表的变化。',
              hint: '修改 start() 方法中的 msg 构造逻辑，使用 DateFormat 或字符串格式化。',
            ),
          ],
        );
      },
    );
  }

  Widget _buildInteractiveDemo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.tune,
              size: 18,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              '控制面板',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ElevatedButton(
              onPressed: controller.isPushing ? null : controller.start,
              child: const Text('开始推送'),
            ),
            ElevatedButton(
              onPressed: !controller.isPushing ? null : controller.stop,
              child: const Text('停止推送'),
            ),
            ElevatedButton(
              onPressed: !controller.isSubscribed ? null : controller.subscribe,
              child: const Text('订阅'),
            ),
            ElevatedButton(
              onPressed: controller.isSubscribed
                  ? null
                  : controller.unsubscribe,
              child: const Text('取消订阅'),
            ),
            ElevatedButton(
              onPressed: controller.addError,
              child: const Text('添加错误'),
            ),
            ElevatedButton(
              onPressed: controller.closeStream,
              child: const Text('关闭Stream'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Text('推送间隔: '),
            DropdownButton<int>(
              value: controller.interval,
              items: const [1, 2, 3, 5].map((value) {
                return DropdownMenuItem<int>(
                  value: value,
                  child: Text('$value秒'),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) controller.setInterval(value);
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '状态: ${controller.isPushing ? "推送中" : "已停止"} | ${controller.isSubscribed ? "已订阅" : "未订阅"}',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: controller.isPushing ? Colors.green : Colors.red,
          ),
        ),
      ],
    );
  }
}
