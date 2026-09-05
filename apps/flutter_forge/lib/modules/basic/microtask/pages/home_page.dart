import 'package:flutter/material.dart';
import 'package:flutter_forge_app/shared/learning/learning_scaffold.dart';
import 'package:go_router/go_router.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const String _baseRoute = '/microtask';

  @override
  Widget build(BuildContext context) {
    return LearningScaffold(
      title: 'Flutter 事件机制学习',
      interactiveDemo: SizedBox(
        height: 300,
        child: LayoutBuilder(
          builder: (context, constraints) => GridView.count(
            crossAxisCount: constraints.maxWidth < 500 ? 1 : 2,
            childAspectRatio: 1.5,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            padding: const EdgeInsets.all(16),
            children: [
              _buildNavCard(
                context,
                title: '事件队列',
                subtitle: '学习事件队列的基本概念和使用方式',
                icon: Icons.queue,
                color: Colors.red.shade100,
                route: '$_baseRoute/event-queue',
              ),
              _buildNavCard(
                context,
                title: '微任务队列',
                subtitle: '学习微任务队列的特性和优先级',
                icon: Icons.speed,
                color: Colors.blue.shade100,
                route: '$_baseRoute/microtask-queue',
              ),
              _buildNavCard(
                context,
                title: '高级示例',
                subtitle: '探索async/await、Future链和Zone',
                icon: Icons.code,
                color: Colors.purple.shade100,
                route: '$_baseRoute/advanced',
              ),
              _buildNavCard(
                context,
                title: '学习资源',
                subtitle: '查看更多关于Flutter事件机制的学习资源',
                icon: Icons.book,
                color: Colors.green.shade100,
              ),
            ],
          ),
        ),
      ),
      sections: const [
        LearningObjectives(
          objectives: [
            '理解 Flutter 事件循环 (Event Loop) 的运作机制',
            '掌握微任务队列 (Microtask Queue) 和事件队列 (Event Queue) 的区别',
            '学会使用 scheduleMicrotask 和 Future 管理异步任务',
            '理解 async/await 背后的微任务调度原理',
          ],
        ),
        ConceptChips(
          concepts: [
            '事件循环',
            'Event Loop',
            '微任务队列',
            '事件队列',
            'scheduleMicrotask',
            'Future',
            'Zone',
          ],
        ),
        CodeSnippetCard(
          title: '微任务 vs 事件任务',
          code:
              'scheduleMicrotask(() {\n'
              '  print("微任务优先执行");\n'
              '});\n\n'
              'Future(() {\n'
              '  print("事件任务后执行");\n'
              '});',
          explanation: '微任务队列优先级高于事件队列，每次事件循环先清空微任务再处理事件。',
        ),
        CommonPitfalls(
          pitfalls: [
            '微任务会阻塞事件循环 — 过多微任务会导致 UI 卡顿',
            'Future.then 的回调是微任务，不是事件任务',
            'scheduleMicrotask 在同一个微任务中嵌套调用仍会优先于事件任务',
          ],
        ),
        ExerciseCard(
          task: '运行"基础微任务测试"观察微任务与事件任务的执行顺序，然后用代码验证你的猜测。',
          hint: '点击导航中的"微任务队列"页面，运行"基础微任务测试"按钮观察日志输出顺序。',
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
  }) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 3,
      child: InkWell(
        onTap: route != null ? () => context.push(route) : null,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color, color.withValues(alpha: 0.7)],
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: Colors.grey[800]),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(subtitle, style: TextStyle(color: Colors.grey[800])),
              const Spacer(),
              Align(
                alignment: Alignment.bottomRight,
                child: Icon(
                  Icons.arrow_forward,
                  color: Colors.grey[800],
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
