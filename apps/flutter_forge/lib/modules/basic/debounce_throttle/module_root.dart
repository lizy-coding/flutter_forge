// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables
import 'package:flutter/material.dart';
import 'package:flutter_study_learning/flutter_study_learning.dart';

import 'utils/debounce_throttle.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  int _currentPageIndex = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LearningScaffold(
      title: widget.title,
      interactiveDemo: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 600;

          return SizedBox(
            height: isCompact ? 620 : 500,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _currentPageIndex == 0
                                ? Theme.of(context).colorScheme.primaryContainer
                                : null,
                          ),
                          onPressed: () {
                            setState(() => _currentPageIndex = 0);
                            _pageController.animateToPage(
                              0,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          child: const Text('按钮点击场景'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _currentPageIndex == 1
                                ? Theme.of(context).colorScheme.primaryContainer
                                : null,
                          ),
                          onPressed: () {
                            setState(() => _currentPageIndex = 1);
                            _pageController.animateToPage(
                              1,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          child: const Text('滚动场景'),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.grey[100],
                  child: const Column(
                    children: [
                      Text(
                        '防抖(Debounce)：在一段时间内多次触发事件，只执行最后一次。',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '节流(Throttle)：在一段时间内多次触发事件，只执行第一次。',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() => _currentPageIndex = index);
                    },
                    children: const [ButtonScene(), ScrollScene()],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      sections: [
        LearningObjectives(
          objectives: [
            '理解防抖(Debounce)与节流(Throttle)的核心区别',
            '掌握 Debouncer 和 Throttle 的代码实现',
            '学会在实际场景中选择合适的频率控制策略',
          ],
        ),
        ConceptChips(
          concepts: ['Debounce', 'Throttle', 'Timer', '频率控制', '性能优化'],
        ),
        CodeSnippetCard(
          title: 'Debouncer 实现',
          code:
              'class Debouncer {\n'
              '  final Duration delay;\n'
              '  Timer? _timer;\n\n'
              '  void run(VoidCallback action) {\n'
              '    _timer?.cancel();\n'
              '    _timer = Timer(delay, action);\n'
              '  }\n\n'
              '  void dispose() => _timer?.cancel();\n'
              '}',
          explanation: '防抖在延迟时间内重置计时器，只有最后一次触发生效。',
        ),
        CodeSnippetCard(
          title: 'Throttle 实现',
          code:
              'class Throttle {\n'
              '  final Duration limit;\n'
              '  DateTime? _lastCall;\n\n'
              '  void run(VoidCallback action) {\n'
              '    final now = DateTime.now();\n'
              '    if (_lastCall != null &&\n'
              '        now.difference(_lastCall!) < limit) return;\n'
              '    _lastCall = now;\n'
              '    action();\n'
              '  }\n'
              '}',
          explanation: '节流在限制时间内忽略后续触发，只有第一次生效。',
        ),
        CommonPitfalls(
          pitfalls: [
            '防抖延迟过长会降低响应感 — 按钮点击场景建议 300-500ms，滚动场景可适当延长',
            '节流可能会导致关键更新丢失 — 不适合需要实时反馈的场景',
            '忘记 dispose — Timer 和 StreamSubscription 必须在 dispose 中清理',
          ],
        ),
        ExerciseCard(
          task: '实现一个"先执行一次"的防抖（leading edge debounce），首次点击立即执行，后续连续点击只执行最后一次。',
          hint: '在 Debouncer 中增加 _leadingExecuted 标记，首次调用时立即执行再启动延迟。',
        ),
      ],
    );
  }
}

class ButtonScene extends StatefulWidget {
  const ButtonScene({super.key});

  @override
  State<ButtonScene> createState() => _ButtonSceneState();
}

class _ButtonSceneState extends State<ButtonScene>
    with TickerProviderStateMixin {
  int _debounceCount = 0;
  int _throttleCount = 0;
  int _normalCount = 0;

  final List<int> _normalEvents = [];
  final List<int> _debounceEvents = [];
  final List<int> _throttleEvents = [];

  late AnimationController _normalAnim;
  late AnimationController _debounceAnim;
  late AnimationController _throttleAnim;

  final Debouncer _debouncer = Debouncer(
    delay: const Duration(milliseconds: 500),
  );
  final Throttle _throttler = Throttle(
    limit: const Duration(milliseconds: 500),
  );

  @override
  void initState() {
    super.initState();
    _normalAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: 1,
    );
    _debounceAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: 1,
    );
    _throttleAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: 1,
    );
  }

  @override
  void dispose() {
    _normalAnim.dispose();
    _debounceAnim.dispose();
    _throttleAnim.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  void _addEventRecord(List<int> list) {
    setState(() {
      list.add(DateTime.now().millisecondsSinceEpoch);
      if (list.length > 10) {
        list.removeAt(0);
      }
    });
  }

  void _handleNormalClick() {
    setState(() => _normalCount++);
    _normalAnim.forward(from: 0);
    _addEventRecord(_normalEvents);
  }

  void _handleDebounceClick() {
    _debounceAnim.forward(from: 0);
    _debouncer.run(() {
      setState(() => _debounceCount++);
      _addEventRecord(_debounceEvents);
    });
  }

  void _handleThrottleClick() {
    _throttleAnim.forward(from: 0);
    _throttler.run(() {
      setState(() => _throttleCount++);
      _addEventRecord(_throttleEvents);
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 600;

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '连续快速点击按钮，对比不同处理方式:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Wrap(
                alignment: WrapAlignment.spaceEvenly,
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildAnimatedButton(
                    '普通点击',
                    Colors.grey,
                    _handleNormalClick,
                    _normalAnim,
                  ),
                  _buildAnimatedButton(
                    '防抖点击',
                    Colors.red,
                    _handleDebounceClick,
                    _debounceAnim,
                  ),
                  _buildAnimatedButton(
                    '节流点击',
                    Colors.blue,
                    _handleThrottleClick,
                    _throttleAnim,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Wrap(
                alignment: WrapAlignment.spaceEvenly,
                spacing: 16,
                runSpacing: 8,
                children: [
                  _buildCounter('普通:', _normalCount, Colors.grey),
                  _buildCounter('防抖:', _debounceCount, Colors.red),
                  _buildCounter('节流:', _throttleCount, Colors.blue),
                ],
              ),
              const SizedBox(height: 30),
              const Text(
                '事件触发可视化:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, eventConstraints) {
                    final visualizations = [
                      _buildEventVisualization(
                        '普通',
                        _normalEvents,
                        Colors.grey,
                      ),
                      _buildEventVisualization(
                        '防抖',
                        _debounceEvents,
                        Colors.red,
                      ),
                      _buildEventVisualization(
                        '节流',
                        _throttleEvents,
                        Colors.blue,
                      ),
                    ];

                    if (isCompact) {
                      return SingleChildScrollView(
                        child: Column(
                          children: [
                            for (final visualization in visualizations) ...[
                              SizedBox(
                                height: eventConstraints.maxHeight,
                                child: visualization,
                              ),
                              if (visualization != visualizations.last)
                                const SizedBox(height: 8),
                            ],
                          ],
                        ),
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final visualization in visualizations)
                          Expanded(child: visualization),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnimatedButton(
    String text,
    Color color,
    VoidCallback onTap,
    AnimationController anim,
  ) {
    return ScaleTransition(
      scale: CurvedAnimation(parent: anim, curve: Curves.elasticOut),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withValues(alpha: 0.2),
          foregroundColor: color,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
        onPressed: onTap,
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildCounter(String prefix, int count, Color color) {
    return Column(
      children: [
        Text(
          '$prefix $count',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildEventVisualization(String title, List<int> events, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: events.length,
              reverse: true,
              itemBuilder: (context, index) {
                return Text(
                  DateTime.fromMillisecondsSinceEpoch(
                    events[index],
                  ).toString().substring(11, 19),
                  style: TextStyle(color: color.withValues(alpha: 0.8)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ScrollScene extends StatefulWidget {
  const ScrollScene({super.key});

  @override
  State<ScrollScene> createState() => _ScrollSceneState();
}

class _ScrollSceneState extends State<ScrollScene>
    with SingleTickerProviderStateMixin {
  double _scrollPosition = 0;
  double _debouncePosition = 0;
  double _throttlePosition = 0;

  final ScrollController _scrollController = ScrollController();
  late AnimationController _positionAnimController;

  final Debouncer _debouncer = Debouncer(
    delay: const Duration(milliseconds: 500),
  );
  final Throttle _throttler = Throttle(
    limit: const Duration(milliseconds: 500),
  );

  @override
  void initState() {
    super.initState();
    _positionAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _scrollController.addListener(() {
      setState(() => _scrollPosition = _scrollController.offset);
      _debouncer.run(() {
        setState(() => _debouncePosition = _scrollController.offset);
        _positionAnimController.forward(from: 0);
      });
      _throttler.run(() {
        setState(() => _throttlePosition = _scrollController.offset);
        _positionAnimController.forward(from: 0);
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _positionAnimController.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 600;

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey[200],
              child: Column(
                children: [
                  _buildPositionIndicator(
                    '实时位置',
                    _scrollPosition,
                    Colors.grey[800]!,
                  ),
                  const SizedBox(height: 10),
                  if (isCompact) ...[
                    _buildAnimatedPositionIndicator(
                      '防抖位置',
                      _debouncePosition,
                      Colors.red,
                    ),
                    const SizedBox(height: 10),
                    _buildAnimatedPositionIndicator(
                      '节流位置',
                      _throttlePosition,
                      Colors.blue,
                    ),
                  ] else
                    Row(
                      children: [
                        Expanded(
                          child: _buildAnimatedPositionIndicator(
                            '防抖位置',
                            _debouncePosition,
                            Colors.red,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: _buildAnimatedPositionIndicator(
                            '节流位置',
                            _throttlePosition,
                            Colors.blue,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                itemCount: 100,
                itemBuilder: (context, index) {
                  final double itemPosition = index * 100.0;
                  final bool isNearReal =
                      (_scrollPosition - itemPosition).abs() < 200;
                  final bool isNearDebounce =
                      (_debouncePosition - itemPosition).abs() < 200;
                  final bool isNearThrottle =
                      (_throttlePosition - itemPosition).abs() < 200;

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '列表项 #$index',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 16,
                            runSpacing: 8,
                            children: [
                              _buildPositionDot(
                                '实时',
                                isNearReal,
                                Colors.grey[800]!,
                              ),
                              _buildPositionDot(
                                '防抖',
                                isNearDebounce,
                                Colors.red,
                              ),
                              _buildPositionDot(
                                '节流',
                                isNearThrottle,
                                Colors.blue,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPositionIndicator(String title, double position, Color color) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            title,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: Container(
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: Colors.grey[300],
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor:
                  (position /
                          (_scrollController.hasClients
                              ? _scrollController.position.maxScrollExtent
                              : 1))
                      .clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: color,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 60,
          child: Text(
            '${position.toStringAsFixed(0)}px',
            textAlign: TextAlign.right,
            style: TextStyle(color: color),
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedPositionIndicator(
    String title,
    double position,
    Color color,
  ) {
    final widthFactor =
        (position /
                (_scrollController.hasClients
                    ? _scrollController.position.maxScrollExtent
                    : 1))
            .clamp(0.0, 1.0);

    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            title,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 12,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: Colors.grey[300],
                ),
              ),
              Positioned.fill(
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: widthFactor,
                  child: FadeTransition(
                    opacity: CurvedAnimation(
                      parent: _positionAnimController,
                      curve: Curves.easeOut,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        color: color,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 60,
          child: Text(
            '${position.toStringAsFixed(0)}px',
            textAlign: TextAlign.right,
            style: TextStyle(color: color),
          ),
        ),
      ],
    );
  }

  Widget _buildPositionDot(String label, bool isActive, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? color : Colors.transparent,
            border: Border.all(color: color),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
