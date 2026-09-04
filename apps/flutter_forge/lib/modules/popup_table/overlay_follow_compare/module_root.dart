import 'package:flutter/material.dart';
import 'package:flutter_forge_app/shared/learning/learning_scaffold.dart';

import 'widgets/compare_panel.dart';
import 'widgets/follower_demo.dart';
import 'widgets/manual_demo.dart';

class OverlayComparePage extends StatelessWidget {
  const OverlayComparePage({super.key});

  @override
  Widget build(BuildContext context) {
    return LearningScaffold(
      title: 'Overlay 跟随方案对照组',
      interactiveDemo: SizedBox(
        height: 420,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 600;
            if (isWide) {
              return Row(
                children: [
                  Expanded(
                    child: ComparePanel(
                      title: 'Follower 自动跟随',
                      color: Colors.orange.shade700,
                      followMethod: 'LayerLink',
                      scrollListener: '无',
                      rebuildLevel: '极低(1次)',
                      demo: const FollowerDemo(),
                    ),
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(
                    child: ComparePanel(
                      title: 'onScroll 手动刷新',
                      color: Colors.blue.shade700,
                      followMethod: 'localToGlobal',
                      scrollListener: '有',
                      rebuildLevel: '随滚动递增',
                      demo: const ManualRebuildDemo(),
                    ),
                  ),
                ],
              );
            }
            return Column(
              children: [
                Expanded(
                  child: ComparePanel(
                    title: 'Follower 自动跟随',
                    color: Colors.orange.shade700,
                    followMethod: 'LayerLink',
                    scrollListener: '无',
                    rebuildLevel: '极低(1次)',
                    demo: const FollowerDemo(),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ComparePanel(
                    title: 'onScroll 手动刷新',
                    color: Colors.blue.shade700,
                    followMethod: 'localToGlobal',
                    scrollListener: '有',
                    rebuildLevel: '随滚动递增',
                    demo: const ManualRebuildDemo(),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      sections: const [
        LearningObjectives(
          objectives: [
            '理解 Overlay + OverlayEntry 实现全局弹层的机制。',
            '掌握 LayerLink + CompositedTransformFollower 实现自动跟随定位。',
            '掌握 localToGlobal 手动计算位置并调用 markNeedsBuild 刷新。',
            '对比自动跟随与手动刷新的性能差异与适用场景。',
            '理解 CompositedTransformTarget/Follower 的 Layer 同步原理。',
          ],
        ),
        ConceptChips(
          concepts: [
            'Overlay',
            'OverlayEntry',
            'LayerLink',
            'CompositedTransformFollower',
            'CompositedTransformTarget',
            'localToGlobal',
            'markNeedsBuild',
          ],
        ),
        CodeSnippetCard(
          title: 'Follower vs Manual 核心代码',
          code: '''// Follower 自动跟随
final link = LayerLink();

CompositedTransformTarget(
  link: link,
  child: targetButton,   // 触发按钮
);

// Overlay 内使用 Follower
CompositedTransformFollower(
  link: link,
  offset: Offset(0, 48),
  child: dropdownPanel,
);

// ---

// Manual 手动刷新
final key = GlobalKey();

final box = key.currentContext!.findRenderObject() as RenderBox;
final pos = box.localToGlobal(Offset.zero);

// OverlayEntry 监听滚动
_scrollController.addListener(() {
  _overlayEntry?.markNeedsBuild();
});

Positioned(
  left: pos.dx,
  top: pos.dy + 48,
  child: dropdownPanel,
);''',
          explanation:
              'Follower 自动跟随基于 Layer 层同步机制，不触发 widget 重建；Manual 方案通过 markNeedsBuild 手动刷新，每次滚动都重建 OverlayEntry。',
        ),
        CommonPitfalls(
          pitfalls: [
            'OverlayEntry 必须通过 Overlay.of(context).insert 插入，不能直接作为子 widget。',
            '忘记在 dispose 中 remove OverlayEntry 会导致 Overlay 泄漏，触发 WidgetsBinding 异常。',
            'CompositedTransformFollower 的 showWhenUnlinked 默认为 true，未链接时仍然显示。',
            'markNeedsBuild 每次调用都会重建 OverlayEntry 的 builder，频繁滚动时影响性能。',
            'localToGlobal 在滚动时需要重新计算，必须通过 ScrollController 监听驱动。',
          ],
        ),
        ExerciseCard(
          task:
              '在 ManualRebuildDemo 中增加状态信息 Widget，实时显示当前 OverlayEntry 的 rebuildCount，对比 FollowerDemo 的 rebuildCount 差异。',
          hint:
              '在 ManualRebuildDemo 的 _toggleOverlay 中增加回调，将 rebuildCount 传递给 StatusInfo 或新增 Widget 展示。',
        ),
      ],
    );
  }
}
