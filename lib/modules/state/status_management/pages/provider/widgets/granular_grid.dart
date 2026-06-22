import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/counter_cn.dart';

class GranularGrid extends StatelessWidget {
  const GranularGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        GranularCard(
          title: '只监听 value',
          desc: '点击顶部「加 1」会触发重建，叶子按钮不会。',
          selector: GranularSelector.value,
        ),
        GranularCard(
          title: '只监听 leafTaps',
          desc: '只有叶子按钮触发，展示 Provider 的依赖分割。',
          selector: GranularSelector.leafTaps,
        ),
      ],
    );
  }
}

enum GranularSelector { value, leafTaps }

class GranularCard extends StatelessWidget {
  const GranularCard({
    super.key,
    required this.title,
    required this.desc,
    required this.selector,
  });

  final String title;
  final String desc;
  final GranularSelector selector;

  @override
  Widget build(BuildContext context) {
    final selected = context.select<CounterCN, int>((s) {
      switch (selector) {
        case GranularSelector.value:
          return s.value;
        case GranularSelector.leafTaps:
          return s.leafTaps;
      }
    });
    debugPrint('[Provider] $title 重建，选中值=$selected');

    final scheme = Theme.of(context).colorScheme;
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 150, maxWidth: 240),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: scheme.secondaryContainer.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 6),
            Text(desc, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 10),
            Text(
              '$selected',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
