import 'dart:async';

/// Stream工具类，提供各种Stream操作函数
class StreamUtils {
  /// 创建一个固定间隔发送数据的Stream
  ///
  /// [interval] 间隔时间（秒）
  /// [generator] 数据生成函数
  /// [count] 发送次数，null表示无限发送
  static Stream<T> timedStream<T>({
    required int interval,
    required T Function(int index) generator,
    int? count,
  }) {
    final controller = StreamController<T>();
    int counter = 0;

    void addData() {
      if (controller.isClosed) return;

      if (count != null && counter >= count) {
        controller.close();
        return;
      }

      try {
        final value = generator(counter);
        controller.add(value);
        counter++;
      } catch (e) {
        controller.addError(e);
      }
    }

    final timer = Timer.periodic(Duration(seconds: interval), (_) => addData());

    controller.onCancel = () {
      timer.cancel();
    };

    return controller.stream;
  }

  /// 将普通Stream转换为广播Stream
  static Stream<T> asBroadcastStream<T>(Stream<T> stream) {
    final controller = StreamController<T>.broadcast();

    final subscription = stream.listen(
      controller.add,
      onError: controller.addError,
      onDone: controller.close,
    );

    controller.onCancel = () {
      subscription.cancel();
    };

    return controller.stream;
  }

  /// 合并多个Stream
  static Stream<T> mergeStreams<T>(List<Stream<T>> streams) {
    final controller = StreamController<T>();
    final subscriptions = <StreamSubscription<T>>[];

    for (var stream in streams) {
      final subscription = stream.listen(
        controller.add,
        onError: controller.addError,
      );

      subscriptions.add(subscription);
    }

    // 当所有Stream都完成时，关闭控制器
    var completedCount = 0;
    for (var stream in streams) {
      stream
          .listen(
            null,
            onDone: () {
              completedCount++;
              if (completedCount == streams.length) {
                controller.close();
              }
            },
          )
          .cancel(); // 立即取消这个监听，因为我们只关心完成事件
    }

    controller.onCancel = () {
      for (var subscription in subscriptions) {
        subscription.cancel();
      }
    };

    return controller.stream;
  }

  /// 限制Stream的发送速率
  static Stream<T> throttle<T>(Stream<T> stream, Duration duration) {
    final controller = StreamController<T>();
    DateTime? lastEventTime;
    StreamSubscription<T>? subscription;

    subscription = stream.listen(
      (data) {
        final now = DateTime.now();
        if (lastEventTime == null ||
            now.difference(lastEventTime!) >= duration) {
          lastEventTime = now;
          controller.add(data);
        }
      },
      onError: controller.addError,
      onDone: controller.close,
    );

    controller.onCancel = () {
      subscription?.cancel();
    };

    return controller.stream;
  }

  /// 缓冲Stream的数据，当收集到指定数量的数据时一次性发送
  static Stream<List<T>> buffer<T>(Stream<T> stream, int count) {
    final controller = StreamController<List<T>>();
    final buffer = <T>[];
    StreamSubscription<T>? subscription;

    subscription = stream.listen(
      (data) {
        buffer.add(data);
        if (buffer.length >= count) {
          controller.add(List<T>.from(buffer));
          buffer.clear();
        }
      },
      onError: controller.addError,
      onDone: () {
        if (buffer.isNotEmpty) {
          controller.add(List<T>.from(buffer));
        }
        controller.close();
      },
    );

    controller.onCancel = () {
      subscription?.cancel();
    };

    return controller.stream;
  }

  /// 对Stream应用变换操作
  static Stream<R> transform<T, R>(
    Stream<T> stream,
    R Function(T value) transformer,
  ) {
    final controller = StreamController<R>();
    StreamSubscription<T>? subscription;

    subscription = stream.listen(
      (data) {
        try {
          final result = transformer(data);
          controller.add(result);
        } catch (e) {
          controller.addError(e);
        }
      },
      onError: controller.addError,
      onDone: controller.close,
    );

    controller.onCancel = () {
      subscription?.cancel();
    };

    return controller.stream;
  }

  /// 创建一个当数据发生变化时才发送的Stream
  static Stream<T> distinct<T>(
    Stream<T> stream, {
    bool Function(T previous, T current)? equals,
  }) {
    final controller = StreamController<T>();
    T? previousValue;
    bool isFirst = true;
    StreamSubscription<T>? subscription;

    subscription = stream.listen(
      (data) {
        if (isFirst) {
          isFirst = false;
          previousValue = data;
          controller.add(data);
        } else {
          final shouldEmit = equals != null
              ? !equals(previousValue as T, data)
              : previousValue != data;

          if (shouldEmit) {
            previousValue = data;
            controller.add(data);
          }
        }
      },
      onError: controller.addError,
      onDone: controller.close,
    );

    controller.onCancel = () {
      subscription?.cancel();
    };

    return controller.stream;
  }

  /// 创建一个仅发送最后一个值的Stream
  static Future<T> last<T>(Stream<T> stream) {
    final completer = Completer<T>();
    T? lastValue;
    bool hasValue = false;

    stream.listen(
      (data) {
        lastValue = data;
        hasValue = true;
      },
      onError: completer.completeError,
      onDone: () {
        if (hasValue) {
          completer.complete(lastValue as T);
        } else {
          completer.completeError(StateError('No elements'));
        }
      },
    );

    return completer.future;
  }
}
