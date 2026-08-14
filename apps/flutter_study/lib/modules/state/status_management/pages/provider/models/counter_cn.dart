import 'package:flutter/foundation.dart';
import 'counter_model.dart';

/// 基于 ChangeNotifier 的计数模型实现
class CounterCN extends ChangeNotifier implements CounterModel {
  int _value = 0;
  int _leafTaps = 0;

  @override
  int get value => _value;

  @override
  int get leafTaps => _leafTaps;

  @override
  void increment() {
    final before = _value;
    _value = _value + 1;
    debugPrint('[Provider] increment: $before -> $_value');
    notifyListeners();
  }

  @override
  void leafIncrement() {
    _leafTaps = _leafTaps + 1;
    debugPrint('[Provider] leaf tap -> $_leafTaps (叶子直接调用 ChangeNotifier)');
    notifyListeners();
  }

  @override
  void reset() {
    _value = 0;
    _leafTaps = 0;
    debugPrint('[Provider] reset -> 0');
    notifyListeners();
  }
}
