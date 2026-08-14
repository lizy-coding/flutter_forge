import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:isolate';
import 'package:flutter_study_learning/flutter_study_learning.dart';

class WithIsolatePage extends StatefulWidget {
  const WithIsolatePage({super.key});

  @override
  State<WithIsolatePage> createState() => _WithIsolatePageState();
}

class _WithIsolatePageState extends State<WithIsolatePage>
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
      title: '使用 Isolate',
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
      sections: [
        LearningObjectives(
          objectives: [
            '理解 Isolate 在 Flutter 中的工作原理',
            '掌握 Isolate.spawn 创建后台线程的方法',
            '学会使用 SendPort/ReceivePort 进行 Isolate 通信',
          ],
        ),
        ConceptChips(
          concepts: [
            'Isolate',
            '多线程',
            'SendPort',
            'ReceivePort',
            '并发计算',
            'UI 流畅度',
          ],
        ),
        CodeSnippetCard(
          title: 'Isolate 基本使用',
          code:
              'final receivePort = ReceivePort();\n'
              'await Isolate.spawn(entryPoint, message,\n'
              '  onError: errorPort.sendPort);\n'
              'await for (final msg in receivePort) {\n'
              '  // 处理计算结果\n'
              '}',
          explanation: 'Isolate.spawn 创建独立内存的 Isolate，通过 Port 进行消息通信。',
        ),
        ExerciseCard(
          task: '点击"开始计算"后尝试点击测试按钮和观察动画，与"不使用 Isolate"页面对比。',
          hint: '计算在后台 Isolate 中执行，主 Isolate 保持 UI 响应的区别非常明显。',
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
    _findPrimesWithIsolate();
  }

  void _findPrimesWithIsolate() async {
    const int iterations = 20;
    const int maxNumber = 500000;
    final receivePort = ReceivePort();
    final errorPort = ReceivePort();
    await Isolate.spawn(
      _isolateEntryPoint,
      _IsolateMessage(
        sendPort: receivePort.sendPort,
        iterations: iterations,
        maxNumber: maxNumber,
      ),
      onError: errorPort.sendPort,
    );
    errorPort.listen((error) {
      setState(() {
        _isCalculating = false;
        _result += '\n发生错误: $error';
      });
    });
    await for (final message in receivePort) {
      if (message is _ProgressMessage) {
        setState(() {
          _progress = message.progress;
          _result += '迭代 ${message.iteration}/$iterations 开始...\n';
          _result += '找到 ${message.primeCount} 个素数 (≤ $maxNumber)\n';
        });
      } else if (message is _ResultMessage) {
        _stopwatch.stop();
        setState(() {
          _isCalculating = false;
          _progress = 1.0;
          _result += '\n计算完成! 耗时: ${_stopwatch.elapsedMilliseconds / 1000} 秒';
        });
        receivePort.close();
        errorPort.close();
        break;
      }
    }
  }
}

void _isolateEntryPoint(_IsolateMessage message) {
  for (int i = 0; i < message.iterations; i++) {
    List<int> primes = _calculatePrimes(message.maxNumber);
    message.sendPort.send(
      _ProgressMessage(
        iteration: i + 1,
        progress: i / message.iterations,
        primeCount: primes.length,
      ),
    );
  }
  message.sendPort.send(_ResultMessage());
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

class _IsolateMessage {
  final SendPort sendPort;
  final int iterations;
  final int maxNumber;
  _IsolateMessage({
    required this.sendPort,
    required this.iterations,
    required this.maxNumber,
  });
}

class _ProgressMessage {
  final int iteration;
  final double progress;
  final int primeCount;
  _ProgressMessage({
    required this.iteration,
    required this.progress,
    required this.primeCount,
  });
}

class _ResultMessage {}
