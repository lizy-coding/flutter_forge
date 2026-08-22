import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_study_learning/flutter_study_learning.dart';

class WithoutIsolatePage extends StatefulWidget {
  const WithoutIsolatePage({super.key});

  @override
  State<WithoutIsolatePage> createState() => _WithoutIsolatePageState();
}

class _WithoutIsolatePageState extends State<WithoutIsolatePage>
    with SingleTickerProviderStateMixin {
  bool _isCalculating = false;
  String _result = '';
  double _progress = 0.0;
  final Stopwatch _stopwatch = Stopwatch();
  late AnimationController _animationController;
  late Animation<double> _animation;
  int _counter = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0, end: 1).animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _incrementCounter() {
    setState(() => _counter++);
  }

  @override
  Widget build(BuildContext context) {
    return LearningScaffold(
      title: '不使用 Isolate',
      interactiveDemo: SizedBox(
        height: 500,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LinearProgressIndicator(value: _progress, minHeight: 10),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _isCalculating ? null : _startHeavyCalculation,
                child: Text(_isCalculating ? '计算中...' : '开始计算'),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _incrementCounter,
                    child: const Text('点击测试响应'),
                  ),
                  const SizedBox(width: 20),
                  Text('计数: $_counter', style: const TextStyle(fontSize: 18)),
                ],
              ),
              const SizedBox(height: 12),
              AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return Container(
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: const [Colors.blue, Colors.purple],
                        stops: [0, _animation.value],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text(
                        '这个动画应该平滑运行',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text('尝试滑动和点击，感受界面响应', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 12),
              const Text('结果:', style: TextStyle(fontSize: 16)),
              const SizedBox(height: 4),
              Container(
                height: 100,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(child: Text(_result)),
              ),
            ],
          ),
        ),
      ),
      sections: const [
        LearningObjectives(
          objectives: [
            '理解主 Isolate 被阻塞时界面卡顿的原理',
            '对比使用和不使用 Isolate 时的界面响应差异',
            '掌握计算密集型任务对 UI 性能的影响',
          ],
        ),
        ConceptChips(concepts: ['Isolate', '主线程', 'UI 卡顿', '计算密集型', '事件循环']),
        CodeSnippetCard(
          title: '主线程计算的问题',
          code:
              '// 主线程执行大量计算\n'
              'void _findPrimes() {\n'
              '  for (int i = 0; i < 20; i++) {\n'
              '    _calculatePrimes(500000); // 阻塞 UI\n'
              '    await Future.delayed(Duration.ms(1));\n'
              '  }\n'
              '}',
          explanation: '计算在事件循环中执行，阻塞了 UI 渲染和手势处理。',
        ),
        ExerciseCard(
          task: '点击"开始计算"后尝试点击测试按钮和观察动画，感受界面卡顿程度。',
          hint: '对比"使用 Isolate"页面，体验两种方式的响应差异。',
        ),
      ],
    );
  }

  void _startHeavyCalculation() {
    setState(() {
      _isCalculating = true;
      _result = '计算中...\n';
      _progress = 0.0;
      _stopwatch.reset();
      _stopwatch.start();
    });
    _findPrimes();
  }

  void _findPrimes() async {
    const int iterations = 20;
    const int maxNumber = 500000;
    List<int> primes = [];
    for (int i = 0; i < iterations; i++) {
      setState(() {
        _progress = i / iterations;
        _result += '迭代 ${i + 1}/$iterations 开始...\n';
      });
      primes = _calculatePrimes(maxNumber);
      await Future.delayed(const Duration(milliseconds: 1));
      setState(() {
        _result += '找到 ${primes.length} 个素数 (≤ $maxNumber)\n';
      });
    }
    _stopwatch.stop();
    setState(() {
      _isCalculating = false;
      _progress = 1.0;
      _result += '\n计算完成! 耗时: ${_stopwatch.elapsedMilliseconds / 1000} 秒';
    });
  }

  List<int> _calculatePrimes(int max) {
    List<int> primes = [];
    List<bool> sieve = List.filled(max + 1, true);
    sieve[0] = sieve[1] = false;
    for (int i = 2; i <= sqrt(max).floor(); i++) {
      if (sieve[i]) {
        for (int j = i * i; j <= max; j += i) {
          sieve[j] = false;
        }
      }
    }
    for (int number = 2; number <= max; number++) {
      if (sieve[number]) {
        // ignore: unused_local_variable
        double sum = 0;
        for (int j = 0; j < 2000; j++) {
          sum += sin(j * 0.01) * cos(j * 0.01) * tan(j * 0.005);
        }
        primes.add(number);
      }
    }
    return primes;
  }
}
