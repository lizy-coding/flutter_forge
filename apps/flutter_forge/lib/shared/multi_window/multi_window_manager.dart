import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/foundation.dart';

import '../../module_registry/module_category.dart';

class MultiWindowManager {
  MultiWindowManager._({MultiWindowPlatform? platform})
    : _platform = platform ?? const DesktopMultiWindowPlatform(),
      _diagnosticSink = _printDiagnostic;

  @visibleForTesting
  MultiWindowManager.forTesting(
    MultiWindowPlatform platform, {
    MultiWindowDiagnosticSink? diagnosticSink,
  }) : _platform = platform,
       _diagnosticSink = diagnosticSink ?? _printDiagnostic;

  static final MultiWindowManager instance = MultiWindowManager._();

  static bool get isSupported =>
      Platform.isMacOS || Platform.isWindows || Platform.isLinux;

  final Map<ModuleCategory, String> _categoryWindows = {};
  final MultiWindowPlatform _platform;
  final MultiWindowDiagnosticSink _diagnosticSink;
  StreamSubscription<void>? _windowCloseListener;

  /// Starts window lifecycle observation and removes stale category entries.
  Future<void> initialize() async {
    if (!isSupported) return;
    _windowCloseListener ??= onWindowsChanged.listen((_) {
      unawaited(_calibrateCategoryWindows());
    });
    await _calibrateCategoryWindows();
  }

  Future<String?> createCategoryWindow(ModuleCategory category) async {
    if (!isSupported) return null;

    final stopwatch = Stopwatch()..start();
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
            _categoryWindows.remove(category);
            break;
          }
        }
      }
      _categoryWindows.remove(category);
    }

    final args = jsonEncode({'type': 'category', 'category': category.name});

    final config = WindowConfiguration(hiddenAtLaunch: false, arguments: args);

    final controller = await _platform.createWindow(config);

    _categoryWindows[category] = controller.windowId;
    _recordDiagnostic(
      category: category,
      arguments: controller.arguments,
      controllerId: controller.windowId,
      operation: 'create_window',
      stopwatch: stopwatch,
    );
    return controller.windowId;
  }

  Future<void> _calibrateCategoryWindows() async {
    final controllers = await _platform.getAllWindows();
    final liveCategoryWindows = <ModuleCategory, String>{};
    for (final controller in controllers) {
      final arguments = parseArguments(controller.arguments);
      if (arguments.type == WindowType.category && arguments.category != null) {
        liveCategoryWindows[arguments.category!] = controller.windowId;
      }
    }
    _categoryWindows
      ..clear()
      ..addAll(liveCategoryWindows);
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
}

enum WindowType { main, category }

class WindowArguments {
  final WindowType type;
  final ModuleCategory? category;

  const WindowArguments({required this.type, this.category});

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
    return WindowArguments(type: type, category: category);
  }
}
