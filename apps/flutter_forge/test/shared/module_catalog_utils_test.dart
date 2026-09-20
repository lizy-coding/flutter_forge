import 'package:flutter/material.dart';
import 'package:flutter_forge_app/module_registry/app_platform_snapshot.dart';
import 'package:flutter_forge_app/module_registry/module_catalog_utils.dart';
import 'package:flutter_forge_app/module_registry/module_category.dart';
import 'package:flutter_forge_app/module_registry/module_entry.dart';
import 'package:flutter_forge_app/module_registry/module_platform_support.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  const android = AppPlatformSnapshot(platform: AppTargetPlatform.android);
  const macOS = AppPlatformSnapshot(platform: AppTargetPlatform.macOS);
  const web = AppPlatformSnapshot(platform: AppTargetPlatform.web);
  const windows = AppPlatformSnapshot(platform: AppTargetPlatform.windows);
  const unsupported = AppPlatformSnapshot(
    platform: AppTargetPlatform.unsupported,
  );

  ModuleEntry createModule({
    required String path,
    required ModuleCategory category,
    List<GoRoute> routes = const [],
    Set<AppTargetPlatform> excludedPlatforms = const {},
  }) => ModuleEntry(
    title: path,
    path: path,
    subtitle: 'test',
    category: category,
    difficulty: Difficulty.beginner,
    concepts: const ['test'],
    estimatedMinutes: 1,
    status: ModuleStatus.ready,
    builder: (_) => const SizedBox.shrink(),
    routes: routes,
    platformSupport: ModulePlatformSupport(
      excludedPlatforms: excludedPlatforms,
    ),
  );

  Widget unsupportedBuilder(BuildContext context, ModuleEntry module) =>
      const Text('unsupported');

  test('filters modules without changing catalog order', () {
    final modules = [
      createModule(path: '/basic-a', category: ModuleCategory.basic),
      createModule(path: '/ui-a', category: ModuleCategory.ui),
      createModule(path: '/basic-b', category: ModuleCategory.basic),
    ];
    expect(
      filterModulesByCategory(modules, ModuleCategory.basic).map((m) => m.path),
      ['/basic-a', '/basic-b'],
    );
  });

  test('rebases module and child paths for a category window', () {
    final module = createModule(
      path: '/basic-a',
      category: ModuleCategory.basic,
      routes: [
        GoRoute(path: '/details', builder: (_, __) => const SizedBox.shrink()),
      ],
    );
    final route = buildCategoryRoutes(
      [module],
      android,
      unsupportedBuilder: unsupportedBuilder,
    ).single;
    expect(route.path, 'basic-a');
    expect((route.routes.single as GoRoute).path, 'details');
  });

  test('target platforms are available unless explicitly excluded', () {
    final module = createModule(
      path: '/platform-neutral',
      category: ModuleCategory.basic,
    );
    for (final platform in [android, macOS, web, windows]) {
      expect(isModuleAvailable(module, platform), isTrue);
    }
    expect(isModuleAvailable(module, unsupported), isFalse);
  });

  test('excluded platforms are unavailable', () {
    final module = createModule(
      path: '/macos-only',
      category: ModuleCategory.platform,
      excludedPlatforms: {
        AppTargetPlatform.android,
        AppTargetPlatform.iOS,
        AppTargetPlatform.web,
        AppTargetPlatform.windows,
      },
    );
    expect(isModuleAvailable(module, macOS), isTrue);
    expect(isModuleAvailable(module, windows), isFalse);
    expect(availableModules([module], windows), isEmpty);
  });

  test('unavailable modules keep a guarded category route', () {
    final module = createModule(
      path: '/windows-only',
      category: ModuleCategory.platform,
      excludedPlatforms: {AppTargetPlatform.android},
    );
    final route = buildCategoryRoutes(
      [module],
      android,
      unsupportedBuilder: unsupportedBuilder,
    ).single;
    expect(route.path, 'windows-only');
    expect(route.routes, isEmpty);
  });
}
