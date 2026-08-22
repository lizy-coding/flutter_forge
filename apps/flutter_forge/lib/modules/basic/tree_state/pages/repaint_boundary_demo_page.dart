import 'package:flutter/material.dart';
import 'package:flutter_study_learning/flutter_study_learning.dart';

/// 对比使用/不使用 RepaintBoundary 时的重绘范围，方便解释 RenderObject 分叉。
class RepaintBoundaryDemoPage extends StatefulWidget {
  const RepaintBoundaryDemoPage({super.key});

  @override
  State<RepaintBoundaryDemoPage> createState() =>
      _RepaintBoundaryDemoPageState();
}

class _RepaintBoundaryDemoPageState extends State<RepaintBoundaryDemoPage> {
  int _colorIndex = 0;
  final List<Color> _colors = [
    Colors.orange,
    Colors.green,
    Colors.purple,
    Colors.blue,
  ];
  final List<String> _logs = [];

  @override
  Widget build(BuildContext context) {
    final color = _colors[_colorIndex % _colors.length];
    debugPrint('[RepaintBoundaryDemoPage] build color=$color');
    return LearningScaffold(
      title: 'RepaintBoundary 局部重绘',
      interactiveDemo: SizedBox(
        height: 320,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(8),
              child: Text('对比没有/有 RepaintBoundary 时的局部重绘范围'),
            ),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: _buildSection(
                      label: '无 RepaintBoundary',
                      child: const CustomPaint(
                        painter: NoBoundaryPainter(),
                        child: SizedBox.expand(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildSection(
                      label: '有 RepaintBoundary',
                      child: RepaintBoundary(
                        child: CustomPaint(
                          painter: BoundaryPainter(color: color),
                          child: const SizedBox.expand(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _colorIndex++;
                      });
                      final msg = 'changeColor → index=$_colorIndex';
                      debugPrint('[RepaintBoundaryDemoPage] $msg');
                      _logs.add(msg);
                    },
                    child: const Text('只改变右侧颜色'),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: () => setState(() => _logs.clear()),
                    child: const Text('清空日志'),
                  ),
                ],
              ),
            ),
            Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _logs.isEmpty
                    ? [
                        const Text(
                          '点击按钮观察 paint 日志',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ]
                    : _logs
                          .map(
                            (l) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Text(
                                l,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                          )
                          .toList(),
              ),
            ),
          ],
        ),
      ),
      sections: const [
        LearningObjectives(
          objectives: [
            '理解 RepaintBoundary 如何隔离子树的重绘范围',
            '观察 shouldRepaint 返回 true/false 时的不同行为',
            '理解 RenderObject 树的局部更新机制',
          ],
        ),
        ConceptChips(
          concepts: [
            'RepaintBoundary',
            'CustomPainter',
            'shouldRepaint',
            '局部重绘',
            'RenderObject',
          ],
        ),
        CodeSnippetCard(
          title: 'RepaintBoundary 用法',
          code: '''RepaintBoundary(
  child: CustomPaint(
    painter: MyPainter(color: color),
  ),
)

// 外部 setState 时，RepaintBoundary
// 内部的 RenderObject 不会无条件重绘''',
          explanation:
              'RepaintBoundary 在 RenderObject 树中创建一个独立的重绘边界，内部子树只在自己 dirty 时重绘。',
        ),
        CommonPitfalls(
          pitfalls: [
            'RepaintBoundary 不会阻止 Widget build，只阻止 RenderObject paint',
            'CustomPainter 的 shouldRepaint 返回 false 时，即使父组件 setState 也不会重绘',
            '过度使用 RepaintBoundary 会增加内存开销，只在必要时使用',
          ],
        ),
        ExerciseCard(
          task:
              '点击「只改变右侧颜色」并观察 debugPrint：NoBoundaryPainter 每次都被调用 paint，而 BoundaryPainter 只在颜色变化时重绘。',
          hint:
              'NoBoundaryPainter.shouldRepaint 始终返回 false，但因为它的父组件没有 RepaintBoundary 保护，所以仍随父组件重绘。',
        ),
      ],
    );
  }

  Widget _buildSection({required String label, required Widget child}) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Expanded(child: child),
      ],
    );
  }
}

class NoBoundaryPainter extends CustomPainter {
  const NoBoundaryPainter();

  @override
  void paint(Canvas canvas, Size size) {
    debugPrint('[NoBoundaryPainter] paint, size=$size');
    final paint = Paint()
      ..color = Colors.grey.shade400
      ..style = PaintingStyle.fill;
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant NoBoundaryPainter oldDelegate) {
    debugPrint('[NoBoundaryPainter] shouldRepaint -> false');
    return false;
  }
}

class BoundaryPainter extends CustomPainter {
  final Color color;

  BoundaryPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    debugPrint('[BoundaryPainter] paint, color=$color, size=$size');
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant BoundaryPainter oldDelegate) {
    final should = oldDelegate.color != color;
    debugPrint(
      '[BoundaryPainter] shouldRepaint old=${oldDelegate.color}, new=$color, should=$should',
    );
    return should;
  }
}
