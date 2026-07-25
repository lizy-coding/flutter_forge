import 'package:flutter/material.dart';

class StateFlowDemo extends StatelessWidget {
  const StateFlowDemo({
    super.key,
    required this.pageTitle,
    required this.subtitle,
    required this.value,
    required this.flowSteps,
    required this.onAdd,
    required this.onReset,
    this.extra,
  });

  final String pageTitle;
  final String subtitle;
  final int value;
  final List<String> flowSteps;
  final VoidCallback onAdd;
  final VoidCallback onReset;
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final animatedColor = value.isEven
        ? colorScheme.primaryContainer.withValues(alpha: 0.4)
        : colorScheme.secondaryContainer.withValues(alpha: 0.4);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              colors: [animatedColor, Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    pageTitle,
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                    textAlign: TextAlign.center,
                  ),
                  const Divider(height: 32),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    transitionBuilder: (child, animation) =>
                        ScaleTransition(scale: animation, child: child),
                    child: Text(
                      '$value',
                      key: ValueKey(value),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _FlowTimeline(steps: flowSteps),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FilledButton.icon(
                        onPressed: onAdd,
                        icon: const Icon(Icons.exposure_plus_1),
                        label: const Text('加 1'),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: onReset,
                        icon: const Icon(Icons.restart_alt),
                        label: const Text('重置'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '提示：配合调试控制台日志，可完整追踪 "事件 → 状态变化 → 通知 → build() 重建"。',
                    textAlign: TextAlign.center,
                  ),
                  if (extra != null) ...[const SizedBox(height: 16), extra!],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FlowTimeline extends StatelessWidget {
  const _FlowTimeline({required this.steps});
  final List<String> steps;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      runSpacing: 4,
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          Chip(
            label: Text(
              steps[i],
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            avatar: CircleAvatar(
              radius: 10,
              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.2),
              child: Text('${i + 1}', style: theme.textTheme.labelSmall),
            ),
            backgroundColor: theme.colorScheme.surfaceContainerHighest
                .withValues(alpha: 0.6),
          ),
          if (i != steps.length - 1)
            Icon(Icons.trending_flat, color: theme.colorScheme.primary),
        ],
      ],
    );
  }
}
