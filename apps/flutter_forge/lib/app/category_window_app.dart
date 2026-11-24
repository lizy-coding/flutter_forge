import 'package:desktop_multi_window/desktop_multi_window.dart';
import '../shared/multi_window/focus_window_navigation.dart';
import '../shared/multi_window/multi_window_manager.dart';
import '../module_registry/module_entry.dart';
import '../module_registry/chinese_experiment.dart';
import 'package:forge_localization/forge_localization.dart';
import '../l10n/app_localizations.dart';
import '../l10n/forge_localization_delegates.dart';
import '../l10n/strings.dart';
import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

import '../module_registry/module_catalog_utils.dart';
import '../module_registry/module_category.dart';
import '../module_registry/app_platform_snapshot.dart';
import '../module_registry/app_platform_scope.dart';
import 'module_home_page.dart';
import 'unsupported_module_page.dart';
import 'router/app_route_table.dart';
import 'theme/app_theme.dart';
import 'theme/app_theme_controller.dart';
import 'theme/forge_glass.dart';
import 'desktop_window_host.dart';
import 'desktop_workbench_shell.dart';
import 'theme/app_theme_selection.dart';
import 'navigation_session.dart';

class CategoryWindowApp extends StatefulWidget {
  const CategoryWindowApp({
    super.key,
    required this.category,
    required this.platform,
    required this.themeController,
    this.module,
    this.initialLocation,
    this.mainWindowId,
  });

  final ModuleCategory category;
  final ModuleEntry? module;
  final String? initialLocation;
  final String? mainWindowId;

  List<ModuleEntry> get modules => module != null
      ? [module!]
      : filterModulesByCategory(AppRouteTable.modules, category);

  final AppPlatformSnapshot platform;
  final AppThemeController themeController;

  static GoRouter createRouter(
    ModuleCategory category,
    AppPlatformSnapshot platform, {
    ModuleEntry? module,
    String? initialLocation,
    String? mainWindowId,
  }) {
    final modules = module == null
        ? filterModulesByCategory(AppRouteTable.modules, category)
        : [module];
    final routes = module != null
        ? buildModuleRoutes(
            modules,
            platform,
            unsupportedBuilder: (_, entry) =>
                UnsupportedModulePage(module: entry, platform: platform),
          )
        : <RouteBase>[
            GoRoute(
              path: '/',
              builder: (context, state) => CategoryHomePage(
                category: category,
                modules: modules,
                platform: platform,
                focusedWindow: true,
              ),
              routes: buildCategoryRoutes(
                modules,
                platform,
                unsupportedBuilder: (_, entry) =>
                    UnsupportedModulePage(module: entry, platform: platform),
              ),
            ),
          ];
    final incoming = Uri.tryParse(initialLocation ?? '');
    final modulePath = module?.path;
    final inScope =
        incoming != null &&
        !incoming.hasScheme &&
        !incoming.hasAuthority &&
        modulePath != null &&
        (incoming.path == modulePath ||
            incoming.path.startsWith('$modulePath/'));
    return GoRouter(
      initialLocation: inScope ? initialLocation : modulePath ?? '/',
      overridePlatformDefaultLocation: module != null,
      redirect: module == null
          ? null
          : (_, state) => state.error != null ? module.path : null,
      routes: platform.hostFamily == AppHostFamily.desktop
          ? [
              ShellRoute(
                builder: (context, state, child) => frameworkLanguage(
                  context,
                  DesktopWorkbenchShell(
                    modules: modules,
                    location: state.uri.path,
                    platform: platform,
                    focusedCategory: category,
                    focusedModule: module,
                    mainWindowId: mainWindowId,
                    child: ExperimentNavigatorLocale(
                      router: GoRouter.of(context),
                      modules: modules,
                      child: child,
                    ),
                  ),
                ),
                routes: routes,
              ),
            ]
          : routes,
    );
  }

  @override
  State<CategoryWindowApp> createState() => _CategoryWindowAppState();
}

class _CategoryWindowAppState extends State<CategoryWindowApp> {
  late GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = _createRouter();
  }

  @override
  void didUpdateWidget(CategoryWindowApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.category != widget.category ||
        oldWidget.platform.platform != widget.platform.platform) {
      final previous = _router;
      _router = _createRouter();
      WidgetsBinding.instance.addPostFrameCallback((_) => previous.dispose());
    }
  }

  GoRouter _createRouter() => CategoryWindowApp.createRouter(
    widget.category,
    widget.platform,
    module: widget.module,
    initialLocation: widget.initialLocation,
    mainWindowId: widget.mainWindowId,
  );

  String _title(BuildContext context) =>
      widget.module?.titleFor(context) ??
      widget.category.labelIn(frameworkStrings(context));

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  Widget _withFocusNavigation(Widget child) {
    final mainId = widget.mainWindowId;
    if (widget.module == null || mainId == null) return child;
    return FocusWindowNavigation(
      openInMain: (route) async {
        try {
          await WindowController.fromWindowId(
            mainId,
          ).invokeMethod<void>(MultiWindowManager.openRouteMethod, route);
        } catch (error) {
          debugPrint('[multi-window] failed to open route in main: $error');
          if (!mounted) return;
          final overlay =
              _router.routerDelegate.navigatorKey.currentState?.overlay;
          if (overlay != null) {
            ScaffoldMessenger.of(
              overlay.context,
            ).showSnackBar(const SnackBar(content: Text('无法在主窗口打开页面。')));
          }
        }
      },
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppPlatformScope(
      platform: widget.platform,
      child: NavigationSessionScope(
        child: AppThemeScope(
          controller: widget.themeController,
          child: ListenableBuilder(
            listenable: widget.themeController,
            builder: (context, _) => MaterialApp.router(
              debugShowCheckedModeBanner: false,
              locale:
                  LocaleScope.maybeOf(context)?.effectiveLocale ??
                  const Locale('zh'),
              localizationsDelegates: forgeLocalizationDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              routerConfig: _router,
              title: _title(context),
              theme: AppTheme.light(widget.themeController.palette),
              darkTheme: AppTheme.dark(widget.themeController.palette),
              highContrastTheme: AppTheme.light(AppThemePalette.graphiteForge),
              highContrastDarkTheme: AppTheme.dark(
                AppThemePalette.graphiteForge,
              ),
              themeMode: widget.themeController.themeMode,
              builder: (context, child) => DesktopWindowHost(
                platform: widget.platform,
                mainWindow: false,
                title: _title(context),
                router: _router,
                modules: widget.modules,
                homeLocation: widget.module?.path ?? '/',
                themeMode: widget.themeController.themeMode,
                materialEnabled:
                    widget.themeController.palette ==
                    AppThemePalette.liquidGlass,
                child: ForgeThemeBackdrop(
                  child: ExperimentNavigatorLocale(
                    router: _router,
                    modules: widget.modules,
                    child: _withFocusNavigation(child!),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
