import 'dart:async';
import 'dart:convert';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/foundation.dart';

import '../../module_registry/module_category.dart';
import 'platform_support_io.dart'
    if (dart.library.js_interop) 'platform_support_web.dart';

class MultiWindowManager {
  MultiWindowManager._({MultiWindowPlatform? platform})
    : _platform = platform ?? const DesktopMultiWindowPlatform(),
      _startupTimeout = const Duration(seconds: 15),
      _diagnosticSink = _printDiagnostic;

  @visibleForTesting
  MultiWindowManager.forTesting(
    MultiWindowPlatform platform, {
    MultiWindowDiagnosticSink? diagnosticSink,
    Duration startupTimeout = const Duration(seconds: 15),
  }) : _platform = platform,
       _startupTimeout = startupTimeout,
       _diagnosticSink = diagnosticSink ?? _printDiagnostic;

  static final MultiWindowManager instance = MultiWindowManager._();

  static bool get isSupported => multiWindowPlatformSupported;

  final Map<ModuleCategory, String> _categoryWindows = {};
  final Map<ModuleCategory, Future<String?>> _pendingCategoryWindows = {};
  final Set<String> _unreadyWindowIds = {};
  final Map<ModuleCategory, MultiWindowController> _failedStartupWindows = {};
  int _windowStateVersion = 0;
  final MultiWindowPlatform _platform;
  final Duration _startupTimeout;
  final MultiWindowDiagnosticSink _diagnosticSink;
  // The singleton observes windows for the process lifetime.
  // ignore: cancel_subscriptions
  StreamSubscription<void>? _windowCloseListener;
  String _themeSelectionPayload = 'system';

  static const themeSelectionMethod = 'themeSelectionChanged';
  static const readyMethod = 'windowReady';

  /// Starts window lifecycle observation and removes stale category entries.
  Future<void> initialize() async {
    if (!isSupported) return;
    _windowCloseListener ??= onWindowsChanged.listen((_) {
      unawaited(_calibrateCategoryWindows());
    });
    await _calibrateCategoryWindows();
  }

  Future<String?> createCategoryWindow(ModuleCategory category) {
    if (!isSupported) return Future.value(null);

    return _pendingCategoryWindows.putIfAbsent(category, () async {
      try {
        return await _createCategoryWindow(category);
      } finally {
        // The removed future is already returned to the callers.
        unawaited(_pendingCategoryWindows.remove(category));
      }
    });
  }

  Future<String> _createCategoryWindow(ModuleCategory category) async {
    final stopwatch = Stopwatch()..start();
    final failed = _failedStartupWindows[category];
    if (failed != null) {
      await _platform.closeWindow(failed).timeout(const Duration(seconds: 3));
      _failedStartupWindows.remove(category);
    }
    await _calibrateCategoryWindows();

    if (_categoryWindows.containsKey(category)) {
      final existingId = _categoryWindows[category]!;
      final controllers = await _platform.getAllWindows();
      for (final c in controllers) {
        if (c.windowId == existingId) {
          try {
            await _platform.showWindow(c);
            _recordDiagnostic(
              category: category,
              arguments: c.arguments,
              controllerId: existingId,
              operation: 'reuse_window',
              stopwatch: stopwatch,
            );
            return existingId;
          } catch (error, stackTrace) {
            _recordDiagnostic(
              category: category,
              arguments: c.arguments,
              controllerId: existingId,
              operation: 'show_window_failed',
              stopwatch: stopwatch,
              error: error,
              stackTrace: stackTrace,
            );
            final liveWindowIds = (await _platform.getAllWindows())
                .map((controller) => controller.windowId)
                .toSet();
            if (liveWindowIds.contains(existingId)) rethrow;
            _removeCategoryWindow(category);
            break;
          }
        }
      }
      _removeCategoryWindow(category);
    }

    final args = jsonEncode({
      'type': 'category',
      'category': category.name,
      'themeSelection': _themeSelectionPayload,
    });

    final config = WindowConfiguration(
      hiddenAtLaunch: true,
      arguments: args,
      enableFlutterGpu: true,
    );

    // Future.timeout cannot cancel native creation. A late result must be
    // closed, rather than becoming an orphaned hidden engine.
    var abandoned = false;
    final creation = _platform.createWindow(config).then((controller) async {
      if (abandoned) {
        _unreadyWindowIds.add(controller.windowId);
        _windowStateVersion++;
        if (!await _closeFailedWindow(controller)) {
          _failedStartupWindows[category] = controller;
        }
      }
      return controller;
    });
    late final MultiWindowController controller;
    try {
      controller = await creation.timeout(_startupTimeout);
    } catch (_) {
      abandoned = true;
      rethrow;
    }
    if (controller.windowId.isEmpty) {
      throw StateError('Native window creation returned an empty identity');
    }

    _unreadyWindowIds.add(controller.windowId);
    _windowStateVersion++;

    try {
      await _platform.waitUntilReady(controller).timeout(_startupTimeout);
      await _platform.showWindow(controller).timeout(_startupTimeout);
    } catch (error, stackTrace) {
      _removeCategoryWindow(category);
      if (!await _closeFailedWindow(controller)) {
        _failedStartupWindows[category] = controller;
      }
      _recordDiagnostic(
        category: category,
        arguments: controller.arguments,
        controllerId: controller.windowId,
        operation: 'startup_failed',
        stopwatch: stopwatch,
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }

    _unreadyWindowIds.remove(controller.windowId);
    _categoryWindows[category] = controller.windowId;
    _windowStateVersion++;
    _recordDiagnostic(
      category: category,
      arguments: controller.arguments,
      controllerId: controller.windowId,
      operation: 'create_window',
      stopwatch: stopwatch,
    );
    return controller.windowId;
  }

  Future<bool> _closeFailedWindow(MultiWindowController controller) async {
    try {
      await _platform
          .closeWindow(controller)
          .timeout(const Duration(seconds: 3));
      return true;
    } catch (error) {
      debugPrint(
        '[multi-window] startup cleanup failed for ${controller.windowId}: $error',
      );
      return false;
    }
  }

  Future<void> _calibrateCategoryWindows() async {
    final version = _windowStateVersion;
    final controllers = await _platform.getAllWindows();
    // A list captured before a concurrent mutation cannot replace newer state.
    if (version != _windowStateVersion) return;
    final liveIds = controllers
        .map((controller) => controller.windowId)
        .toSet();
    _unreadyWindowIds.retainWhere(liveIds.contains);
    final liveCategoryWindows = <ModuleCategory, String>{};
    for (final controller in controllers) {
      final arguments = parseArguments(controller.arguments);
      if (arguments.type == WindowType.category && arguments.category != null) {
        // Native inventory includes hidden windows still starting. They must
        // not be advertised as reusable until their startup barrier completes.
        if (_unreadyWindowIds.contains(controller.windowId)) continue;
        liveCategoryWindows[arguments.category!] = controller.windowId;
      }
    }
    // Even an unchanged accepted snapshot supersedes older pending snapshots.
    _windowStateVersion++;
    if (mapEquals(_categoryWindows, liveCategoryWindows)) return;
    _categoryWindows
      ..clear()
      ..addAll(liveCategoryWindows);
  }

  void _removeCategoryWindow(ModuleCategory category) {
    if (_categoryWindows.remove(category) != null) _windowStateVersion++;
  }

  void _recordDiagnostic({
    required ModuleCategory category,
    required Object? arguments,
    required String controllerId,
    required String operation,
    required Stopwatch stopwatch,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _diagnosticSink({
      'category': category.name,
      'argumentsType': arguments.runtimeType.toString(),
      'controllerId': controllerId,
      'operation': operation,
      'elapsedMs': stopwatch.elapsedMilliseconds,
      if (error != null) 'error': error.toString(),
      if (stackTrace != null) 'stackTrace': stackTrace.toString(),
    });
  }

  bool isCategoryOpen(ModuleCategory category) =>
      _categoryWindows.containsKey(category);

  void setThemeSelectionPayload(String payload) {
    _themeSelectionPayload = payload;
  }

  Future<void> updateThemeSelection(String payload) async {
    _themeSelectionPayload = payload;
    final controllers = await _platform.getAllWindows();
    for (final controller in controllers) {
      final arguments = parseArguments(controller.arguments);
      if (arguments.type == WindowType.category) {
        try {
          await _platform.invokeMethod(
            controller,
            themeSelectionMethod,
            payload,
          );
        } catch (error) {
          debugPrint(
            '[multi-window] theme sync skipped for ${controller.windowId}: '
            '$error',
          );
        }
      }
    }
  }

  static WindowArguments parseArguments(dynamic args) {
    if (args is! String || args.isEmpty) {
      return const WindowArguments(type: WindowType.main);
    }
    try {
      final map = jsonDecode(args) as Map<String, dynamic>;
      return WindowArguments.fromJson(map);
    } catch (_) {
      return const WindowArguments(type: WindowType.main);
    }
  }
}

typedef MultiWindowDiagnosticSink = void Function(Map<String, Object> fields);

void _printDiagnostic(Map<String, Object> fields) {
  debugPrint('[multi-window] ${jsonEncode(fields)}');
}

abstract interface class MultiWindowPlatform {
  Future<List<MultiWindowController>> getAllWindows();

  Future<MultiWindowController> createWindow(WindowConfiguration configuration);

  Future<void> showWindow(MultiWindowController controller);

  Future<void> waitUntilReady(MultiWindowController controller);

  Future<void> closeWindow(MultiWindowController controller);

  Future<void> invokeMethod(
    MultiWindowController controller,
    String method,
    Object? arguments,
  );
}

class MultiWindowController {
  const MultiWindowController({
    required this.windowId,
    required this.arguments,
    required this.nativeController,
  });

  final String windowId;
  final String arguments;
  final WindowController? nativeController;
}

class DesktopMultiWindowPlatform implements MultiWindowPlatform {
  const DesktopMultiWindowPlatform();

  @override
  Future<List<MultiWindowController>> getAllWindows() async =>
      (await WindowController.getAll())
          .map(
            (controller) => MultiWindowController(
              windowId: controller.windowId,
              arguments: controller.arguments,
              nativeController: controller,
            ),
          )
          .toList();

  @override
  Future<MultiWindowController> createWindow(
    WindowConfiguration configuration,
  ) async {
    final controller = await WindowController.create(configuration);
    return MultiWindowController(
      windowId: controller.windowId,
      arguments: controller.arguments,
      nativeController: controller,
    );
  }

  @override
  Future<void> showWindow(MultiWindowController controller) =>
      controller.nativeController!.show();

  @override
  Future<void> closeWindow(MultiWindowController controller) async {
    final elapsed = Stopwatch()..start();
    const timeout = Duration(seconds: 3);
    Future<bool> exists() async {
      final remaining = timeout - elapsed.elapsed;
      if (remaining <= Duration.zero) {
        throw TimeoutException('Window cleanup did not complete');
      }
      return (await WindowController.getAll().timeout(
        remaining,
      )).any((window) => window.windowId == controller.windowId);
    }

    try {
      await controller.nativeController!.closeNative().timeout(timeout);
    } catch (_) {
      // The window may have closed between the inventory read and this call.
      if (!await exists()) return;
      rethrow;
    }
    while (await exists()) {
      await Future<void>.delayed(const Duration(milliseconds: 25));
    }
  }

  @override
  Future<void> waitUntilReady(MultiWindowController controller) async {
    final elapsed = Stopwatch()..start();
    const timeout = Duration(seconds: 15);
    while (true) {
      final remaining = timeout - elapsed.elapsed;
      if (remaining <= Duration.zero) {
        throw TimeoutException('Window did not become ready');
      }
      try {
        await controller.nativeController!
            .invokeMethod<void>(MultiWindowManager.readyMethod)
            .timeout(remaining);
        break;
      } on WindowChannelException catch (error) {
        if (error.code != 'CHANNEL_UNREGISTERED' &&
            error.code != 'CHANNEL_NOT_FOUND') {
          rethrow;
        }
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
    }
    if (waitsForNativeFirstFrame) {
      while (true) {
        final remaining = timeout - elapsed.elapsed;
        if (remaining <= Duration.zero) {
          throw TimeoutException('No native first frame');
        }
        if (await controller.nativeController!.isReadyToShow().timeout(
          remaining,
        )) {
          return;
        }
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
    }
  }

  @override
  Future<void> invokeMethod(
    MultiWindowController controller,
    String method,
    Object? arguments,
  ) => controller.nativeController!.invokeMethod<void>(method, arguments);
}

enum WindowType { main, category }

class WindowArguments {
  final WindowType type;
  final ModuleCategory? category;
  final String themeSelectionPayload;

  const WindowArguments({
    required this.type,
    this.category,
    this.themeSelectionPayload = 'system',
  });

  factory WindowArguments.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String? ?? 'main';
    final type = typeStr == 'category' ? WindowType.category : WindowType.main;
    ModuleCategory? category;
    if (type == WindowType.category && json['category'] != null) {
      category = ModuleCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => ModuleCategory.basic,
      );
    }
    return WindowArguments(
      type: type,
      category: category,
      themeSelectionPayload:
          json['themeSelection'] as String? ??
          json['themeMode'] as String? ??
          'system',
    );
  }
}
