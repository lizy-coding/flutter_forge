import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_study_learning/flutter_study_learning.dart';

import '../state/drawing_state.dart';
import '../widgets/drawing_board.dart';

class AdsorptionLinePage extends StatelessWidget {
  const AdsorptionLinePage({super.key});

  @override
  Widget build(BuildContext context) {
    return LearningScaffold(
      title: '智能吸附线画板',
      interactiveDemo: const SizedBox(
        height: 360,
        child: DrawingBoard(embedInScaffold: false),
      ),
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'clear_logs',
            onPressed: () => context.read<DrawingState>().clearLogs(),
            tooltip: '清空日志',
            child: const Icon(Icons.clear_all),
          ),
          const SizedBox(width: 8),
          FloatingActionButton.small(
            heroTag: 'clear_board',
            onPressed: () => context.read<DrawingState>().clear(),
            tooltip: '清空画板',
            child: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      sections: [
        const LearningObjectives(
          objectives: [
            '理解 CustomPaint 与 CustomPainter 的绘制流程和重绘机制。',
            '掌握 GestureDetector 的手势事件处理（点击、拖拽）。',
            '学习吸附对齐算法的基本原理——在阈值范围内自动对齐到参考点。',
            '理解 ChangeNotifier 如何驱动 UI 状态更新。',
            '了解吸附线（SnapLine）辅助显示的视觉反馈机制。',
          ],
        ),
        const ConceptChips(
          concepts: [
            'CustomPaint',
            'CustomPainter',
            'GestureDetector',
            '吸附对齐',
            'ChangeNotifier',
            'Provider',
            'SnapLine',
          ],
        ),
        const CodeSnippetCard(
          title: 'CustomPainter 绘制与重绘',
          code: '''// 绘制器：负责实际绘制逻辑
class DrawingCanvasPainter extends CustomPainter {
  final List<DrawingElement> elements;

  @override
  void paint(Canvas canvas, Size size) {
    for (final element in elements) {
      _drawElement(canvas, element);
    }
  }

  // 必须重写 shouldRepaint 驱动重绘
  @override
  bool shouldRepaint(DrawingCanvasPainter oldDelegate) {
    return elements != oldDelegate.elements;
  }
}

// 使用 ChangeNotifier 驱动重绘
class DrawingState extends ChangeNotifier {
  void addElement(DrawingElement element) {
    _elements.add(element);
    notifyListeners();  // 触发 Consumer/ListenableBuilder 重建
  }
}''',
          explanation:
              'CustomPainter 通过 shouldRepaint 判断是否需要重绘；ChangeNotifier 的 notifyListeners 触发 UI 更新。',
        ),
        StateLogView(
          logs: context.read<DrawingState>().logs.isEmpty
              ? ['在画板上点击添加元素，或拖拽已有元素开始体验...']
              : context.read<DrawingState>().logs,
          maxLines: 6,
        ),
        const CommonPitfalls(
          pitfalls: [
            'CustomPaint 不会自动重绘——需要通过 ChangeNotifier.notifyListeners() 或 setState 触发。',
            'shouldRepaint 返回 false 时即使数据变了也不会重绘，务必正确实现。',
            '屏幕坐标系 Y 轴向下为正，与数学坐标相反，计算吸附时需要注意方向。',
            '吸附阈值（snapThreshold）过大或过小都会影响体验——25px 是一个常用值。',
            'GestureDetector 的 onPanUpdate 频率很高，吸附计算要保持轻量。',
          ],
        ),
        const ExerciseCard(
          task:
              '尝试修改吸附阈值（snapThreshold），观察吸附灵敏度变化。当前阈值为 25px，分别改为 10px 和 50px 体验效果差异。',
          hint: '在 adsorption_manager.dart 中修改 snapThreshold 常量的值。',
        ),
      ],
    );
  }
}
