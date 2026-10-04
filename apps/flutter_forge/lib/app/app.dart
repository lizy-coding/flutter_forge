import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'theme/app_theme.dart';
import 'theme/app_theme_controller.dart';

class App extends StatelessWidget {
  const App({super.key, required this.router, required this.themeController});

  final GoRouter router;
  final AppThemeController themeController;

  @override
  Widget build(BuildContext context) {
    return AppThemeScope(
      controller: themeController,
      child: ListenableBuilder(
        listenable: themeController,
        builder: (context, _) => MaterialApp.router(
          routerConfig: router,
          title: 'Flutter Forge',
          theme: AppTheme.light(themeController.palette),
          darkTheme: AppTheme.dark(themeController.palette),
          themeMode: themeController.themeMode,
        ),
      ),
    );
  }
}
