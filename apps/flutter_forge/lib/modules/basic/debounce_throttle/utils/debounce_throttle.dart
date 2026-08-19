import 'dart:async';

class Debouncer {
  final Duration delay;
  Timer? _timer;

  Debouncer({required this.delay});

  void run(void Function() action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void dispose() {
    _timer?.cancel();
  }
}

class Throttle {
  final Duration limit;
  bool _canRun = true;

  Throttle({required this.limit});

  void run(void Function() action) {
    if (_canRun) {
      action();
      _canRun = false;
      Timer(limit, () => _canRun = true);
    }
  }
}
