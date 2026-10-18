import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'theme/app_theme.dart';
import 'theme/app_theme_controller.dart';
import 'theme/forge_glass.dart';
import 'desktop_window_host.dart';
import 'theme/app_theme_selection.dart';
import 'router/app_route_table.dart';
import 'app_platform_provider.dart';

class App extends ConsumerWidget {
  const App({super.key, required this.router, required this.themeController});

  final GoRouter router;
  final AppThemeController themeController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final platform = ref.watch(appPlatformProvider);
    return AppThemeScope(
      controller: themeController,
      child: ListenableBuilder(
        listenable: themeController,
        builder: (context, _) => MaterialApp.router(
          debugShowCheckedModeBanner: false,
          routerConfig: router,
          title: 'Flutter Forge',
          theme: AppTheme.light(themeController.palette),
          darkTheme: AppTheme.dark(themeController.palette),
          highContrastTheme: AppTheme.light(AppThemePalette.graphiteForge),
          highContrastDarkTheme: AppTheme.dark(AppThemePalette.graphiteForge),
          themeMode: themeController.themeMode,
          builder: (context, child) => DesktopWindowHost(
            platform: platform,
            router: router,
            modules: AppRouteTable.modules,
            themeMode: themeController.themeMode,
            child: ForgeThemeBackdrop(child: child!),
          ),
        ),
      ),
    );
  }
}
