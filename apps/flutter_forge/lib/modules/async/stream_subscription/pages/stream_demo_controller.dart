import 'dart:async';
import 'package:flutter/foundation.dart';

/// ViewModel: 封装单订阅 Stream 逻辑与状态管理
class StreamDemoController extends ChangeNotifier {
  final List<String> _messages = [];

  /// 对外只读的消息列表
  List<String> get messages => List.unmodifiable(_messages);

  bool _isPushing = false;
  bool get isPushing => _isPushing;

  StreamSubscription<String>? _subscription;
  bool get isSubscribed => _subscription != null;

  int _interval = 2;
  int get interval => _interval;

  late StreamController<String> _controller;
  Timer? _timer;
  int _count = 0;

  StreamDemoController() {
    _reset();
  }

  void _reset() {
    _controller = StreamController<String>(
      onCancel: () => debugPrint('StreamController 已关闭'),
    );
    _subscription = null;
    _messages.clear();
    _count = 0;
    _isPushing = false;
    _interval = 2;
    notifyListeners();
  }

  /// 开始定时推送消息
  void start() {
    if (_isPushing) return;
    _isPushing = true;
    notifyListeners();

    _timer = Timer.periodic(Duration(seconds: _interval), (t) {
      if (!_isPushing) {
        t.cancel();
        return;
      }
      _count++;
      final msg =
          '模拟消息 #$_count - ${DateTime.now().toString().substring(11, 19)}';
      if (!_controller.isClosed) _controller.add(msg);
    });
  }

  /// 停止消息推送
  void stop() {
    if (!_isPushing) return;
    _isPushing = false;
    _timer?.cancel();
    notifyListeners();
  }

  /// 订阅 Stream
  void subscribe() {
    if (_subscription != null) return;
    _messages.clear();
    _subscription = _controller.stream.listen(
      (d) {
        _messages.add(d);
        notifyListeners();
      },
      onError: (e) {
        _messages.add('错误: $e');
        notifyListeners();
      },
      onDone: () {
        _subscription = null;
        notifyListeners();
      },
    );
  }

  /// 取消订阅
  void unsubscribe() {
    unawaited(
      _subscription?.cancel().then((_) {
        _subscription = null;
        notifyListeners();
      }),
    );
  }

  /// 注入错误事件
  void addError() {
    if (!_isPushing || _controller.isClosed) return;
    _controller.addError('模拟错误事件');
  }

  /// 关闭并重置 Stream
  void closeStream() {
    if (_controller.isClosed) return;
    stop();
    unawaited(_controller.close().then((_) => _reset()));
  }

  /// 修改推送间隔
  void setInterval(int s) {
    if (s < 1) return;
    _interval = s;
    if (_isPushing) {
      stop();
      start();
    }
    notifyListeners();
  }

  @override
  void dispose() {
    stop();
    unawaited(_subscription?.cancel());
    unawaited(_controller.close());
    super.dispose();
  }
}
