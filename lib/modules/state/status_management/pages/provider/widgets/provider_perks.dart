import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/counter_cn.dart';
import 'granular_grid.dart';

/// 额外展示 Provider 优势：无需 props 传递，叶子也可按字段粒度刷新。
class ProviderPerks extends StatelessWidget {
  const ProviderPerks({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('深层组件直接拿到上层状态', style: theme.textTheme.titleMedium),
        const SizedBox(height: 6),
        Text(
          'ChangeNotifierProvider 挂在页面顶层，最深层的叶子通过 context.read/select 获取祖先状态与操作，完全不需要 props 层层传递。',
          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black54),
        ),
        const SizedBox(height: 12),
        const DeepTree(),
        const SizedBox(height: 18),
        Text('颗粒度刷新（Selector / context.select）',
            style: theme.textTheme.titleMedium),
        const SizedBox(height: 6),
        Text(
          '不同区域只监听自己关心的字段：点击叶子不会让顶部数值重建，反之亦然。控制台日志可看到哪些 build() 被触发。',
          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black54),
        ),
        const SizedBox(height: 12),
        const GranularGrid(),
      ],
    );
  }
}

class DeepTree extends StatelessWidget {
  const DeepTree({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint('[Provider] _DeepTree build（未订阅，不随状态刷新）');
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: const TreeLevelOne(),
    );
  }
}

class TreeLevelOne extends StatelessWidget {
  const TreeLevelOne({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint('[Provider] Level 1 build（纯布局，不依赖 Provider）');
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Level 1：布局层（未监听 Provider，不会重建）'),
        SizedBox(height: 8),
        TreeLevelTwo(),
      ],
    );
  }
}

class TreeLevelTwo extends StatelessWidget {
  const TreeLevelTwo({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint('[Provider] Level 2 build（继续透传，无 props）');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .primaryContainer
            .withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Level 2：普通 Widget（未持有任何状态字段）'),
          SizedBox(height: 6),
          TreeLeaf(),
        ],
      ),
    );
  }
}

class TreeLeaf extends StatelessWidget {
  const TreeLeaf({super.key});

  @override
  Widget build(BuildContext context) {
    final leafTaps = context.select<CounterCN, int>((s) => s.leafTaps);
    final ancestorValue = context.select<CounterCN, int>((s) => s.value);
    debugPrint(
        '[Provider] 最深叶子 build：leafTaps=$leafTaps, ancestor value=$ancestorValue');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .onPrimaryContainer
            .withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Theme.of(context)
              .colorScheme
              .onPrimaryContainer
              .withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Level 3（叶子）：直接读取 Provider，跨越两层父 Widget',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 6),
          Text(
            '祖先 value：$ancestorValue | 叶子按钮点击：$leafTaps',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: context.read<CounterCN>().leafIncrement,
                icon: const Icon(Icons.touch_app_outlined),
                label: const Text('叶子直接触发事件'),
              ),
              OutlinedButton.icon(
                onPressed: context.read<CounterCN>().increment,
                icon: const Icon(Icons.exposure_plus_1),
                label: const Text('叶子也能改 value'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
