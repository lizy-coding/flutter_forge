import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'shared/multi_window/category_window_app.dart';
import 'shared/multi_window/multi_window_manager.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  if (MultiWindowManager.isSupported) {
    final wc = await WindowController.fromCurrentEngine();
    final windowArgs = MultiWindowManager.parseArguments(wc.arguments);

    if (windowArgs.type == WindowType.category && windowArgs.category != null) {
      runApp(
        ProviderScope(
          child: CategoryWindowApp(category: windowArgs.category!),
        ),
      );
      return;
    }
  }

  runApp(const ProviderScope(child: MainApp()));
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const App();
  }
}
