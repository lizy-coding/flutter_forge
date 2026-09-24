import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import '../module_registry/app_platform_snapshot.dart';
import '../shared/multi_window/multi_window_manager.dart';
import 'app.dart';
import 'app_platform_provider.dart';
import 'category_window_app.dart';
import 'router/app_router.dart';

/// Resolves the host-specific application shell before mounting Flutter.
Future<void> bootstrapFlutterForgeApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  final platform = AppPlatformSnapshot.detect();

  Widget root = App(router: AppRouter.create(platform));
  if (!platform.isWeb && MultiWindowManager.isSupported) {
    final windowController = await WindowController.fromCurrentEngine();
    final arguments = MultiWindowManager.parseArguments(
      windowController.arguments,
    );
    if (arguments.type == WindowType.category && arguments.category != null) {
      root = CategoryWindowApp(
        category: arguments.category!,
        platform: platform,
      );
    } else {
      await MultiWindowManager.instance.initialize();
    }
  }

  runApp(
    ProviderScope(
      overrides: [appPlatformProvider.overrideWithValue(platform)],
      child: root,
    ),
  );
}
