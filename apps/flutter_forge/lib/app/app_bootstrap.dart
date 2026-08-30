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
  WindowController? childWindowController;
  WindowArguments? childWindowArguments;
  if (MultiWindowManager.isSupported) {
    final windowController = await WindowController.fromCurrentEngine();
    final arguments = MultiWindowManager.parseArguments(
      windowController.arguments,
    );
    if (arguments.type == WindowType.category && arguments.category != null) {
      childWindowController = windowController;
      childWindowArguments = arguments;
      root = CategoryWindowApp(category: arguments.category!);
    } else {
      await MultiWindowManager.instance.initialize();
    }
  }

  runApp(ProviderScope(child: root));

  // Keep child windows hidden until Flutter has produced their first frame.
  // Showing the native window immediately after create() can expose a black
  // surface while a later macOS Flutter engine is still attaching its view.
  if (childWindowController != null && childWindowArguments != null) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // A post-frame callback runs after layout/paint has been scheduled, but
      // macOS may still be attaching the engine surface. Wait for the frame
      // future and retry a bounded number of times before giving up.
      await WidgetsBinding.instance.endOfFrame;
      for (var attempt = 0; attempt < 3; attempt++) {
        await Future<void>.delayed(const Duration(milliseconds: 80));
        try {
          await childWindowController!.show();
          return;
        } catch (_) {
          if (attempt == 2) rethrow;
        }
      }
    });
  }
}
