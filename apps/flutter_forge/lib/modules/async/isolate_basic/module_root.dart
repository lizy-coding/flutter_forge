// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables
import 'package:flutter/material.dart';
import 'package:flutter_study_learning/flutter_study_learning.dart';
import 'package:go_router/go_router.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const String _baseRoute = '/isolate-basic';

  @override
  Widget build(BuildContext context) {
    return LearningScaffold(
      title: 'Isolate 并发对比',
      interactiveDemo: SizedBox(
        height: 350,
        child: SingleChildScrollView(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '本演示通过大量计算来对比使用和不使用 Isolate 的差异',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber),
                  ),
                  child: const Column(
                    children: [
                      Text(
                        '测试说明:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '1. 两个页面执行相同的计算任务(查找素数)\n'
                        '2. 计算过程中观察动画流畅度\n'
                        '3. 尝试点击"点击测试响应"按钮\n'
                        '4. 尝试在蓝色区域滑动\n'
                        '5. 对比两者UI响应差异',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    backgroundColor: Colors.red[100],
                  ),
                  onPressed: () {
                    context.push('$_baseRoute/without-isolate');
                  },
                  child: const Text('不使用 Isolate (卡顿示例)'),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    backgroundColor: Colors.green[100],
                  ),
                  onPressed: () {
                    context.push('$_baseRoute/with-isolate');
                  },
                  child: const Text('使用 Isolate (流畅示例)'),
                ),
              ],
            ),
          ),
        ),
      ),
      sections: [
        LearningObjectives(
          objectives: [
            '理解 Isolate 与主线程的内存隔离机制',
            '掌握 Isolate.spawn + SendPort/ReceivePort 通信模式',
            '对比有/无 Isolate 时 UI 流畅度差异',
          ],
        ),
        ConceptChips(
          concepts: [
            'Isolate',
            'SendPort',
            'ReceivePort',
            '并发',
            'UI 流畅度',
            '耗时计算',
          ],
        ),
        CodeSnippetCard(
          title: 'Isolate 基础用法',
          code:
              'final receivePort = ReceivePort();\n'
              'await Isolate.spawn(\n'
              '  computeTask,\n'
              '  receivePort.sendPort,\n'
              ');\n'
              'receivePort.listen((result) {\n'
              '  // 接收计算结果\n'
              '});',
          explanation: 'Isolate.spawn 在新 Isolate 中执行函数，通过 Port 通信。',
        ),
        CommonPitfalls(
          pitfalls: [
            'Isolate 间不能共享变量 — 必须通过消息传递，无法直接访问主线程数据',
            'ReceivePort 需要及时关闭 — 不关闭会导致内存泄漏',
            '大量小消息的性能开销 — 频繁跨 Isolate 通信可能得不偿失',
          ],
        ),
        ExerciseCard(
          task:
              '修改 without_isolate_page.dart，尝试使用 compute 工具函数替换 Isolate.spawn，对比两种 API 的差异。',
          hint: 'Flutter 提供了 compute() 函数作为 Isolate 的简化封装，适合一次性耗时计算。',
        ),
      ],
    );
  }
}
