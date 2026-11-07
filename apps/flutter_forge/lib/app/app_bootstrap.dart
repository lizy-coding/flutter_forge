import 'package:forge_localization/forge_localization.dart';
import 'localization/app_locale_host.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import '../module_registry/app_platform_snapshot.dart';
import '../shared/multi_window/multi_window_manager.dart';
import 'app.dart';
import 'app_platform_provider.dart';
import 'category_window_app.dart';
import 'router/app_router.dart';
import 'theme/app_theme_controller.dart';
import 'theme/app_theme_selection.dart';
import 'workbench_history.dart';

/// Resolves the host-specific application shell before mounting Flutter.
Future<void> bootstrapFlutterForgeApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  final platform = AppPlatformSnapshot.detect();

  Widget? root;
  final startupReady = Completer<void>();
  WindowController? currentWindow;
  var arguments = const WindowArguments(type: WindowType.main);
  if (!platform.isWeb && MultiWindowManager.isSupported) {
    currentWindow = await WindowController.fromCurrentEngine();
    arguments = MultiWindowManager.parseArguments(currentWindow.arguments);
  }

  final history = WorkbenchHistory(
    preferences: await SharedPreferences.getInstance(),
  );
  final themeController = await AppThemeController.load(
    defaultSelection: AppThemeSelection(
      palette: platform.hostFamily == AppHostFamily.desktop
          ? AppThemePalette.liquidGlass
          : AppThemePalette.graphiteForge,
    ),
    initialSelectionPayload: arguments.type == WindowType.category
        ? arguments.themeSelectionPayload
        : null,
  );

  final manager = MultiWindowManager.instance;
  var localeRevision = arguments.localeRevision;
  late final LocaleController localeControllerForSync;
  void applyLocaleSnapshot(dynamic payload) {
    if (payload is! Map ||
        payload['revision'] is! int ||
        payload['preference'] is! String) {
      return;
    }
    final revision = payload['revision'] as int;
    if (revision < localeRevision) return;
    localeRevision = revision;
    localeControllerForSync.applyRemotePreference(
      payload['preference'] as String,
    );
  }

  final localeController = await AppLocaleHost.load(
    initialPreference: arguments.type == WindowType.category
        ? arguments.localePreference
        : null,
    persist:
        arguments.type == WindowType.category && arguments.mainWindowId != null
        ? (value) async {
            final response = await WindowController.fromWindowId(
              arguments.mainWindowId!,
            ).invokeMethod(MultiWindowManager.localeRequestMethod, value);
            applyLocaleSnapshot(response);
          }
        : null,
    onSaved: currentWindow != null && arguments.type == WindowType.main
        ? manager.updateLocalePreference
        : null,
  );
  localeControllerForSync = localeController;
  if (currentWindow != null && arguments.type == WindowType.main) {
    manager.configureLocale(
      currentWindow.windowId,
      localeController.preference,
    );
    await currentWindow.setWindowMethodHandler((call) async {
      if (call.method == MultiWindowManager.localeRequestMethod) {
        if (call.arguments is! String) {
          throw ArgumentError('Invalid locale preference');
        }
        await localeController.setPreference(call.arguments as String);
        if (localeController.saveError != null) {
          throw StateError('Locale was not saved');
        }
        return manager.localeSnapshot;
      }
      if (call.method == MultiWindowManager.localeSnapshotMethod) {
        return manager.localeSnapshot;
      }
      return null;
    });
  }

  if (currentWindow != null) {
    if (arguments.type == WindowType.category && arguments.category != null) {
      await currentWindow.setWindowMethodHandler((call) async {
        if (call.method == MultiWindowManager.readyMethod) {
          await startupReady.future;
        } else if (call.method == MultiWindowManager.themeSelectionMethod) {
          themeController.applyRemoteSelection(call.arguments as String?);
        } else if (call.method == MultiWindowManager.localeSnapshotMethod) {
          applyLocaleSnapshot(call.arguments);
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
    AppLocaleHost(
      controller: localeController,
      child: WorkbenchHistoryScope(
        history: history,
        child: ProviderScope(
          overrides: [appPlatformProvider.overrideWithValue(platform)],
          child:
              root ??
              App(
                router: AppRouter.create(platform),
                themeController: themeController,
              ),
        ),
      ),
    ),
  );
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    if (currentWindow != null && platform.hostFamily == AppHostFamily.desktop) {
      try {
        await currentWindow.markReady();
        if (arguments.type == WindowType.category &&
            arguments.mainWindowId != null) {
          applyLocaleSnapshot(
            await WindowController.fromWindowId(
              arguments.mainWindowId!,
            ).invokeMethod(MultiWindowManager.localeSnapshotMethod),
          );
        }
      } catch (error) {
        debugPrint('Native window readiness failed: $error');
        return;
      }
    }
    if (!startupReady.isCompleted) startupReady.complete();
  });
}
