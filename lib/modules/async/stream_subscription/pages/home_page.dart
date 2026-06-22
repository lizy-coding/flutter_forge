import 'package:flutter/material.dart';
import 'package:flutter_study_learning/flutter_study_learning.dart';
import 'package:go_router/go_router.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const String _baseRoute = '/stream-subscription';

  @override
  Widget build(BuildContext context) {
    return LearningScaffold(
      title: 'Flutter Stream 学习',
      interactiveDemo: SizedBox(
        height: 400,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildNavCard(
              context,
              title: '单订阅 Stream',
              subtitle: '单订阅流只允许一个监听器，适用于点对点通信场景',
              icon: Icons.person,
              color: Colors.blue,
              route: '$_baseRoute/stream-demo',
            ),
            const SizedBox(height: 12),
            _buildNavCard(
              context,
              title: '广播 Stream',
              subtitle: '广播流允许多个监听器，适用于一对多通信场景',
              icon: Icons.people,
              color: Colors.green,
              route: '$_baseRoute/broadcast-demo',
            ),
            const SizedBox(height: 12),
            _buildNavCard(
              context,
              title: 'Stream 变换示例',
              subtitle: '使用各种操作符对数据流进行变换处理',
              icon: Icons.transform,
              color: Colors.orange,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('此功能暂未实现，敬请期待！')),
                );
              },
            ),
          ],
        ),
      ),
      sections: [
        LearningObjectives(objectives: [
          '理解 Flutter Stream 的概念与工作原理',
          '掌握单订阅 Stream 和广播 Stream 的区别',
          '学会使用 StreamController 创建和管理数据流',
          '理解 StreamSubscription 的生命周期管理',
        ]),
        ConceptChips(concepts: [
          'Stream',
          'StreamController',
          'StreamSubscription',
          '单订阅',
          '广播',
          '异步数据流',
        ]),
        CodeSnippetCard(
          title: '创建广播 Stream',
          code: 'final controller = StreamController<String>.broadcast();\n'
              'controller.stream.listen((data) {\n'
              '  print("收到: \$data");\n'
              '});\n'
              'controller.add("hello");\n'
              'controller.close();',
          explanation: 'broadcast() 创建多订阅者流，支持一对多推送。',
        ),
        CommonPitfalls(pitfalls: [
          '单订阅 Stream 只能有一个监听器 — 添加第二个会抛出 StateError',
          'Stream 使用后必须 close() — 否则会导致内存泄漏',
          '广播 Stream 的 onListen/onCancel 回调在第一个/最后一个监听器时触发',
        ]),
        ExerciseCard(
          task: '实现一个带错误处理和 done 回调的 Stream，模拟三次数据推送后自动关闭。',
          hint:
              '使用 controller.add() 三次后调用 controller.close()，通过 onDone 回调监听关闭事件。',
        ),
      ],
    );
  }

  Widget _buildNavCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    String? route,
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: route != null ? () => context.push(route) : onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: TextStyle(
                            fontSize: 14, color: Colors.grey.shade600)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}
