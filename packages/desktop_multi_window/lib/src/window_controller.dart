import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'window_channel.dart';
import 'window_configuration.dart';

final _windowEvent = _windowEventAsStream();

/// A listenable that notifies when the windows list changes.
/// Listen to this to be notified when windows are created or destroyed.
Stream<void> get onWindowsChanged => _windowEvent
    .map((call) {
      if (call.method == 'onWindowsChanged') {
        return call.method;
      }
      return null;
    })
    .where((event) => event != null);

/// The [WindowController] instance that is used to control this window.
class WindowController {
  WindowController._(this.windowId, this.arguments)
    : _windowChannel = WindowMethodChannel(
        'mixin.one/window_controller/$windowId',
        mode: ChannelMode.unidirectional,
      );

  final String windowId;
  final String arguments;

  final WindowMethodChannel _windowChannel;

  factory WindowController.fromWindowId(String id) =>
      WindowController._(id, '');

  static Future<WindowController> create(
    WindowConfiguration configuration,
  ) async {
    final windowId = await _channel.invokeMethod<String>(
      'createWindow',
      configuration.toJson(),
    );
    if (windowId == null || windowId.isEmpty) {
      throw PlatformException(
        code: 'WINDOW_CREATION_FAILED',
        message: 'Native window creation returned no window identity',
      );
    }
    return WindowController._(windowId, configuration.arguments);
  }

  static Future<WindowController> fromCurrentEngine() async {
    Map<dynamic, dynamic>? definition;
    final elapsed = Stopwatch()..start();
    const startupTimeout = Duration(seconds: 3);
    // Windows starts Dart while constructing the view controller, before the
    // caller can register plugins. Yield only for that transient missing channel.
    const retryDelay = Duration(milliseconds: 50);
    for (var attempt = 0; ; attempt++) {
      try {
        final remaining = startupTimeout - elapsed.elapsed;
        if (remaining <= Duration.zero) {
          throw TimeoutException('Native window definition was not registered');
        }
        definition = await _channel
            .invokeMethod<Map<dynamic, dynamic>>('getWindowDefinition')
            .timeout(remaining);
        break;
      } on MissingPluginException {
        if (defaultTargetPlatform != TargetPlatform.windows || attempt >= 40) {
          rethrow;
        }
        await Future<void>.delayed(retryDelay);
      }
    }
    final windowId = definition?['windowId'];
    final windowArgument = definition?['windowArgument'];
    if (windowId is! String || windowId.isEmpty || windowArgument is! String) {
      throw PlatformException(
        code: 'WINDOW_DEFINITION_INVALID',
        message:
            'Native window definition must contain an identity and arguments',
      );
    }
    return WindowController._(windowId, windowArgument);
  }

  static Future<List<WindowController>> getAll() async {
    final result = await _channel.invokeMethod<List<dynamic>>('getAllWindows');
    if (result == null) {
      return [];
    }
    return result.cast<Map<dynamic, dynamic>>().map((e) {
      final windowId = e['windowId'] as String;
      final windowArgument = e['windowArgument'] as String;
      return WindowController._(windowId, windowArgument);
    }).toList();
  }

  Future<void> _callWindowMethod(
    String method, [
    Map<String, dynamic>? arguments,
  ]) {
    assert(windowId.isNotEmpty, 'windowId is empty');
    assert(method.startsWith('window_'), 'method must start with "window_"');
    return _channel.invokeMethod(method, {'windowId': windowId, ...?arguments});
  }

  Future<void> show() => _callWindowMethod('window_show', {});

  Future<void> hide() => _callWindowMethod('window_hide', {});

  /// Closes a native window on Windows or macOS, including a failed startup.
  Future<void> closeNative() => _callWindowMethod('window_close');

  /// Enables native inventory notifications after this window has mounted.
  ///
  /// Call this on the current engine on Windows or macOS.
  Future<void> markReady() => _callWindowMethod('window_markReady');

  /// Reports whether the Windows child engine has rendered its first frame.
  ///
  /// This is a startup barrier, not proof of visible content or GPU completion.
  Future<bool> isReadyToShow() async =>
      await _channel.invokeMethod<bool>('window_isReadyToShow', {
        'windowId': windowId,
      }) ??
      false;

  @optionalTypeArgs
  Future<T?> invokeMethod<T>(String method, [dynamic arguments]) =>
      _windowChannel.invokeMethod<T>(method, arguments);

  Future<void> setWindowMethodHandler(
    Future<dynamic> Function(MethodCall call)? handler,
  ) {
    assert(() {
      scheduleMicrotask(() async {
        final c = await WindowController.fromCurrentEngine();
        if (c.windowId != windowId) {
          throw FlutterError(
            'setWindowMethodHandler can only be called on the current window controller. '
            'Current windowId: ${c.windowId}, this windowId: $windowId',
          );
        }
      });
      return true;
    }());
    return _windowChannel.setMethodCallHandler(handler);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    final WindowController otherController = other as WindowController;
    return windowId == otherController.windowId &&
        arguments == otherController.arguments;
  }

  @override
  int get hashCode => windowId.hashCode ^ arguments.hashCode;

  @override
  String toString() {
    return 'WindowController(windowId: $windowId, arguments: $arguments)';
  }
}

const _channel = MethodChannel('mixin.one/desktop_multi_window');

Stream<MethodCall> _windowEventAsStream() {
  // This process event stream remains reusable; onCancel removes the native handler.
  // ignore: close_sinks
  late StreamController<MethodCall> controller;
  controller = StreamController<MethodCall>.broadcast(
    onListen: () {
      _channel.setMethodCallHandler((call) async {
        controller.add(call);
      });
    },
    onCancel: () {
      _channel.setMethodCallHandler(null);
    },
  );
  return controller.stream;
}
