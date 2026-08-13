// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables
import 'package:flutter/material.dart';
import 'package:flutter_study_learning/flutter_study_learning.dart';
import 'package:go_router/go_router.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const String _baseRoute = '/download-animation';

  @override
  Widget build(BuildContext context) {
    return LearningScaffold(
      title: '下载动画演示',
      interactiveDemo: SizedBox(
        height: 500,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade200,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(Icons.download, size: 64, color: Colors.blue.shade600),
                  const SizedBox(height: 16),
                  const Text(
                    '下载动画演示',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '体验不同的下载动画实现方式',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            _buildNavigationCard(
              context: context,
              title: '自定义 View 实现',
              subtitle: '基于 Stack 的传统实现方式',
              icon: Icons.layers,
              color: Colors.blue,
              routePath: '$_baseRoute/custom-view',
            ),
            const SizedBox(height: 16),
            _buildNavigationCard(
              context: context,
              title: 'Paint 绘制动画',
              subtitle: '使用 CustomPaint 实现的动画效果',
              icon: Icons.brush,
              color: Colors.teal,
              routePath: '$_baseRoute/paint',
            ),
            const SizedBox(height: 16),
            _buildNavigationCard(
              context: context,
              title: '实现方式对比',
              subtitle: 'Custom View vs Overlay 对比演示',
              icon: Icons.compare,
              color: Colors.purple,
              routePath: '$_baseRoute/comparison',
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue.shade600,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '实现说明',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Custom View: 使用 Stack + AnimatedBuilder 实现\n'
                    '• Paint: 使用 CustomPaint 绘制动画\n'
                    '• Overlay: 使用全局 Overlay 实现，不受视图层级限制',
                    style: TextStyle(fontSize: 14, color: Colors.blue.shade700),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      sections: [
        LearningObjectives(
          objectives: [
            '理解 Flutter 动画的基础实现方式',
            '对比 Custom View、CustomPaint、Overlay 三种方案的差异',
            '掌握不同场景下选择合适的动画实现策略',
          ],
        ),
        ConceptChips(
          concepts: [
            'Tween 动画',
            'CustomPaint',
            'OverlayEntry',
            'Stack',
            'AnimatedBuilder',
            '动画配置',
          ],
        ),
        CodeSnippetCard(
          title: '三种动画实现对比',
          code:
              '// 1. Custom View (Stack)\n'
              'Stack(children: [\n'
              '  AnimatedBuilder(\n'
              '    animation: controller,\n'
              '    builder: (context, child) => ...\n'
              '  ),\n'
              ']);\n\n'
              '// 2. CustomPaint\n'
              'CustomPaint(\n'
              '  painter: DownloadPainter(progress),\n'
              ');\n\n'
              '// 3. Overlay\n'
              'Overlay.of(context).insert(\n'
              '  OverlayEntry(builder: (_) => ...)\n'
              ');',
          explanation: '三种方案各有优劣：Stack 直观、CustomPaint 灵活、Overlay 全局。',
        ),
        ExerciseCard(
          task: '为 Paint 绘制动画增加"暂停/继续"功能，使用 AnimationController 的 stop/resume。',
          hint: 'AnimationController 自带 stop() 和 repeat()，在按钮回调中切换即可。',
        ),
      ],
    );
  }

  Widget _buildNavigationCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String routePath,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push(routePath),
        child: Padding(
          padding: const EdgeInsets.all(20),
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
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey.shade400,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
