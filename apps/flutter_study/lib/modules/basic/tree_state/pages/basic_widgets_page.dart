import 'package:flutter/material.dart';

import 'package:flutter_study_learning/flutter_study_learning.dart';

/// Stateless 与 Stateful 重建行为对比教学页
class BasicWidgetsPage extends StatefulWidget {
  const BasicWidgetsPage({super.key});

  @override
  State<BasicWidgetsPage> createState() => _BasicWidgetsPageState();
}

class _BasicWidgetsPageState extends State<BasicWidgetsPage> {
  int _counter = 0;
  final List<String> _logs = [];

  void _rebuild() {
    setState(() {
      _counter++;
      _logs.add('父组件 setState → counter=$_counter');
    });
  }

  void _clearLogs() {
    setState(() {
      _logs.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return LearningScaffold(
      title: 'Stateless 与 Stateful 重建',
      interactiveDemo: _buildDemo(context),
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            onPressed: _clearLogs,
            heroTag: 'clear',
            icon: const Icon(Icons.clear_all),
            label: const Text('清空日志'),
          ),
          const SizedBox(width: 8),
          FloatingActionButton.extended(
            onPressed: _rebuild,
            heroTag: 'rebuild',
            icon: const Icon(Icons.refresh),
            label: const Text('触发重建'),
          ),
        ],
      ),
      sections: [
        const LearningObjectives(
          objectives: [
            '区分 Widget（配置对象）和 State（持久对象）的角色差异。',
            '观察父组件 setState 后，StatelessWidget 和 StatefulWidget 子组件的 build 变化。',
            '理解 StatefulWidget 的状态为什么保存在 State 中而不是 Widget 中。',
          ],
        ),
        const ConceptChips(
          concepts: ['Widget', 'Element', 'State', 'build', 'setState'],
        ),
        const CodeSnippetCard(
          title: 'setState 与数据传递',
          code: '''// 父组件触发重建
void _rebuild() {
  setState(() {
    _counter++;
  });
}

// 父组件将 count 传递给子组件
StatelessBox(count: _counter)  // StatelessWidget
StatefulBox(count: _counter)   // StatefulWidget

// StatefulBox 内部通过 widget.count 读取
class _StatefulBoxState extends State<StatefulBox> {
  @override
  Widget build(BuildContext context) {
    return Text('count: \${widget.count}');
  }
}''',
          explanation: 'setState 会触发 build，但 StatefulBox 的 State 实例不会被销毁。',
        ),
        StateLogView(
          logs: _logs.isEmpty ? ['点击「触发重建」按钮开始观察...'] : _logs,
          maxLines: 10,
        ),
        const CommonPitfalls(
          pitfalls: [
            '不要把 Widget 理解成长期存在的界面对象——它只是轻量级配置，每次 build 都会重新创建。',
            '不要认为 StatelessWidget 不会重新 build——父组件 setState 后，所有子 Widget 都会重新 build。',
            '不要把可变状态直接放在 Widget 字段里——Widget 字段是 final，状态应该放在 State 中。',
          ],
        ),
        const ExerciseCard(
          task:
              '尝试修改 StatelessBox，让它在 build 时打印日志，然后观察每次点击「触发重建」后的日志输出。思考：为什么 StatelessBox 每次都会 build，但 StatefulBox 的 initState 只执行一次？',
          hint: '关注 Element 树的复用机制：Widget 类型和 key 不变时，Element 会复用，State 不会被销毁。',
        ),
      ],
    );
  }

  Widget _buildDemo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            '父组件重建次数: $_counter',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            return Flex(
              direction: constraints.maxWidth > 480
                  ? Axis.horizontal
                  : Axis.vertical,
              children: [
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: _RebuildAwareBox(
                        label: 'StatelessWidget',
                        child: StatelessBox(count: _counter),
                      ),
                    ),
                  ),
                ),
                if (constraints.maxWidth > 480)
                  const SizedBox(width: 16)
                else
                  const SizedBox(height: 16),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: _RebuildAwareBox(
                        label: 'StatefulWidget',
                        child: StatefulBox(count: _counter),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

/// 包装器：在 rebuild 时闪烁边框，直观展示重建行为
class _RebuildAwareBox extends StatefulWidget {
  final String label;
  final Widget child;

  const _RebuildAwareBox({required this.label, required this.child});

  @override
  State<_RebuildAwareBox> createState() => _RebuildAwareBoxState();
}

class _RebuildAwareBoxState extends State<_RebuildAwareBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_RebuildAwareBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 1 - _controller.value),
              width: 2,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              Text(
                widget.label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              widget.child,
            ],
          ),
        );
      },
    );
  }
}

class StatelessBox extends StatelessWidget {
  final int count;

  const StatelessBox({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    debugPrint('[StatelessBox] build count=$count');
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('接收 count 参数', style: TextStyle(fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          'count: $count',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class StatefulBox extends StatefulWidget {
  final int count;

  const StatefulBox({super.key, required this.count});

  @override
  State<StatefulBox> createState() => _StatefulBoxState();
}

class _StatefulBoxState extends State<StatefulBox> {
  @override
  void initState() {
    super.initState();
    debugPrint('[StatefulBox] initState');
  }

  @override
  void dispose() {
    debugPrint('[StatefulBox] dispose');
    super.dispose();
  }

  @override
  void didUpdateWidget(StatefulBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    debugPrint(
      '[StatefulBox] didUpdateWidget count=${oldWidget.count} → ${widget.count}',
    );
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('[StatefulBox] build count=${widget.count}');
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('持有 State 实例', style: TextStyle(fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          'count: ${widget.count}',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
