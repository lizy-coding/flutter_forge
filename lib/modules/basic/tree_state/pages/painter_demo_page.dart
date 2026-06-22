import 'package:flutter/material.dart';
import 'package:flutter_study_learning/flutter_study_learning.dart';

/// CustomPainter 的布局/重绘示例，日志标记了 build、shouldRepaint、paint 调用。
class PainterDemoPage extends StatefulWidget {
  const PainterDemoPage({super.key});

  @override
  State<PainterDemoPage> createState() => _PainterDemoPageState();
}

class _PainterDemoPageState extends State<PainterDemoPage> {
  double _radius = 60;
  final List<String> _logs = [];

  @override
  Widget build(BuildContext context) {
    debugPrint('[PainterDemoPage] build radius=${_radius.toStringAsFixed(1)}');
    return LearningScaffold(
      title: 'CustomPainter 渲染流程',
      interactiveDemo: SizedBox(
        height: 400,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('CustomPainter 展示 build/layout/paint 分离'),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Text('半径: '),
                  Expanded(
                    child: Slider(
                      value: _radius,
                      min: 20,
                      max: 140,
                      label: _radius.toStringAsFixed(0),
                      onChanged: (value) {
                        setState(() {
                          _radius = value;
                        });
                        _logs.add(
                            'Slider → radius=${_radius.toStringAsFixed(0)}');
                      },
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _logs.clear()),
                    child: const Text('清空'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: SizedBox(
                  width: 280,
                  height: 220,
                  child: CustomPaint(
                    painter: PainterDemoPainter(radius: _radius),
                    child: const Center(child: Text('拖动 Slider 观察日志')),
                  ),
                ),
              ),
            ),
            Container(
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView(
                children: _logs.isEmpty
                    ? [
                        const Text('拖动 Slider 观察 paint 和 shouldRepaint 日志',
                            style: TextStyle(color: Colors.grey, fontSize: 12))
                      ]
                    : _logs
                        .map((l) => Text(l,
                            style: const TextStyle(
                                fontSize: 11, fontFamily: 'monospace')))
                        .toList(),
              ),
            ),
          ],
        ),
      ),
      sections: const [
        LearningObjectives(
          objectives: [
            '理解 Widget build / shouldRepaint / paint 的三阶段分离',
            '观察 Slider 拖动时 CustomPaint 的重绘行为',
            '理解 CustomPainter 的 shouldRepaint 优化机制',
          ],
        ),
        ConceptChips(
          concepts: [
            'CustomPaint',
            'CustomPainter',
            'shouldRepaint',
            'Canvas',
            'paint'
          ],
        ),
        CodeSnippetCard(
          title: 'CustomPainter 核心模式',
          code: '''class MyPainter extends CustomPainter {
  final double radius;

  MyPainter({required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    // 在此绘制图形
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(MyPainter oldDelegate) {
    // 仅当数据变化时才重绘
    return oldDelegate.radius != radius;
  }
}''',
          explanation:
              'CustomPainter 接收不可变配置参数，shouldRepaint 决定是否触发 paint 阶段，避免无意义重绘。',
        ),
        CommonPitfalls(
          pitfalls: [
            'CustomPainter 的参数必须是不可变（final）的，否则 shouldRepaint 判断会出错',
            'paint 方法中不要做耗时操作——它在光栅化线程执行',
            'shouldRepaint 返回 true 过于频繁会导致性能问题',
            'Canvas 绘制没有自动保存状态，需要手动 save/restore',
          ],
        ),
        ExerciseCard(
          task:
              '拖动 Slider 并观察调试控制台的 shouldRepaint 和 paint 日志。思考：为什么某些情况 paint 被调用了但视觉上没变化？',
          hint:
              'paint 被调用不代表一定有视觉变化——如果 shouldRepaint 返回 true 但绘制内容不变，仍会触发 paint。',
        ),
      ],
    );
  }
}

class PainterDemoPainter extends CustomPainter {
  final double radius;

  PainterDemoPainter({required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    debugPrint(
      '[PainterDemoPainter] paint, radius=${radius.toStringAsFixed(1)}, size=$size',
    );
    final center = size.center(Offset.zero);
    final axisPaint = Paint()
      ..color = Colors.grey
      ..strokeWidth = 1;
    canvas.drawLine(
        Offset(center.dx, 0), Offset(center.dx, size.height), axisPaint);
    canvas.drawLine(
        Offset(0, center.dy), Offset(size.width, center.dy), axisPaint);

    final fillPaint = Paint()
      ..color = Colors.blueAccent.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = Colors.blueAccent
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius, fillPaint);
    canvas.drawCircle(center, radius, strokePaint);
  }

  @override
  bool shouldRepaint(covariant PainterDemoPainter oldDelegate) {
    final should = oldDelegate.radius != radius;
    debugPrint(
      '[PainterDemoPainter] shouldRepaint: old=${oldDelegate.radius.toStringAsFixed(1)}, new=${radius.toStringAsFixed(1)}, should=$should',
    );
    return should;
  }
}
