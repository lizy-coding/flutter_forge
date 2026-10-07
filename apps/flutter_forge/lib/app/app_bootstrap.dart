import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import '../module_registry/app_platform_snapshot.dart';
import '../shared/multi_window/multi_window_manager.dart';
import 'app.dart';
import 'app_platform_provider.dart';
import 'category_window_app.dart';
import 'router/app_router.dart';
import 'theme/app_theme_controller.dart';

/// Resolves the host-specific application shell before mounting Flutter.
Future<void> bootstrapFlutterForgeApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  final platform = AppPlatformSnapshot.detect();

  Widget? root;
  WindowController? currentWindow;
  var arguments = const WindowArguments(type: WindowType.main);
  if (!platform.isWeb && MultiWindowManager.isSupported) {
    currentWindow = await WindowController.fromCurrentEngine();
    arguments = MultiWindowManager.parseArguments(currentWindow.arguments);
  }

  final themeController = await AppThemeController.load(
    initialSelectionPayload: arguments.type == WindowType.category
        ? arguments.themeSelectionPayload
        : null,
  );

  if (currentWindow != null) {
    if (arguments.type == WindowType.category && arguments.category != null) {
      await currentWindow.setWindowMethodHandler((call) async {
        if (call.method == MultiWindowManager.themeSelectionMethod) {
          themeController.applyRemoteSelection(call.arguments as String?);
        }
      });
      root = CategoryWindowApp(
        category: arguments.category!,
        platform: platform,
        themeController: themeController,
      );
    } else {
      MultiWindowManager.instance.setThemeSelectionPayload(
        themeController.selection.encode(),
      );
      themeController.setChangeHandler(
        MultiWindowManager.instance.updateThemeSelection,
      );
      await MultiWindowManager.instance.initialize();
    }
  }

  runApp(
    ProviderScope(
      overrides: [appPlatformProvider.overrideWithValue(platform)],
      child:
          root ??
          App(
            router: AppRouter.create(platform),
            themeController: themeController,
          ),
    ),
  );
}
