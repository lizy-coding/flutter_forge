import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../shared/multi_window/multi_window_manager.dart';
import 'app.dart';
import 'category_window_app.dart';

/// Resolves the host-specific application shell before mounting Flutter.
Future<void> bootstrapFlutterForgeApp() async {
  WidgetsFlutterBinding.ensureInitialized();

  Widget root = const App();
  if (MultiWindowManager.isSupported) {
    final windowController = await WindowController.fromCurrentEngine();
    final arguments = MultiWindowManager.parseArguments(
      windowController.arguments,
    );
    if (arguments.type == WindowType.category && arguments.category != null) {
      root = CategoryWindowApp(category: arguments.category!);
    }
  }

  runApp(ProviderScope(child: root));
}
