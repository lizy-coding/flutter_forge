import 'package:flutter/material.dart';

import 'widgets/compare_panel.dart';
import 'widgets/follower_demo.dart';
import 'widgets/manual_demo.dart';

class OverlayComparePage extends StatelessWidget {
  const OverlayComparePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Overlay 跟随方案对照组'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: LayoutBuilder(
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
    );
  }
}
