import 'package:flutter/foundation.dart';

/// 计数模型接口：抽象状态与行为，便于替换实现与测试
abstract class CounterModel extends Listenable {
  int get value;
  int get leafTaps;
  void increment();
  void leafIncrement();
  void reset();
}
