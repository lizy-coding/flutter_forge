import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/foundation.dart';

import '../../module_registry/module_category.dart';

class MultiWindowManager {
  MultiWindowManager._({MultiWindowPlatform? platform})
    : _platform = platform ?? const DesktopMultiWindowPlatform();

  @visibleForTesting
  MultiWindowManager.forTesting(MultiWindowPlatform platform)
    : _platform = platform;

  static final MultiWindowManager instance = MultiWindowManager._();

  static bool get isSupported =>
      Platform.isMacOS || Platform.isWindows || Platform.isLinux;

  final Map<ModuleCategory, String> _categoryWindows = {};
  final MultiWindowPlatform _platform;
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

    await _calibrateCategoryWindows();

    if (_categoryWindows.containsKey(category)) {
      final existingId = _categoryWindows[category]!;
      final controllers = await _platform.getAllWindows();
      for (final c in controllers) {
        if (c.windowId == existingId) {
          try {
            await _platform.showWindow(c);
            return existingId;
          } catch (_) {
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

    final config = WindowConfiguration(hiddenAtLaunch: true, arguments: args);

    final controller = await _platform.createWindow(config);

    _categoryWindows[category] = controller.windowId;
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
