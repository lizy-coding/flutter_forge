import 'package:flutter/material.dart';
import 'package:flutter_forge_app/module_registry/app_platform_snapshot.dart';
import 'package:flutter_forge_app/module_registry/module_catalog_utils.dart';
import 'package:flutter_forge_app/module_registry/module_category.dart';
import 'package:flutter_forge_app/module_registry/module_entry.dart';
import 'package:flutter_forge_app/module_registry/module_platform_support.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  for (final nested in [false, true]) {
    testWidgets(
      'route semantics survive ${nested ? 'category' : 'main'} composition',
      (tester) async {
        final navigatorKey = GlobalKey<NavigatorState>();
        var exits = 0;
        final module = ModuleEntry(
          title: 'example',
          path: '/example',
          subtitle: 'example',
          category: ModuleCategory.basic,
          difficulty: Difficulty.beginner,
          concepts: const ['test'],
          estimatedMinutes: 1,
          status: ModuleStatus.ready,
          builder: (_) => const Text('module'),
          platformSupport: const ModulePlatformSupport(),
          routes: [
            GoRoute(
              path: '/legacy',
              redirect: (_, __) => '/example/details/leaf',
            ),
            GoRoute(
              path: '/details',
              builder: (_, __) => const Text('details'),
              routes: [
                GoRoute(
                  path: '/leaf',
                  name: 'leaf',
                  parentNavigatorKey: navigatorKey,
                  pageBuilder: (_, state) => MaterialPage<void>(
                    key: state.pageKey,
                    child: const Text('named page'),
                  ),
                  onExit: (_, __) {
                    exits++;
                    return false;
                  },
                ),
              ],
            ),
          ],
        );
        final moduleRoutes = buildModuleRoutes(
          [module],
          const AppPlatformSnapshot(platform: AppTargetPlatform.macOS),
          nested: nested,
          unsupportedBuilder: (_, __) => const Text('unsupported'),
        );
        final router = GoRouter(
          navigatorKey: navigatorKey,
          initialLocation: '/example/legacy',
          routes: nested
              ? [
                  GoRoute(
                    path: '/',
                    builder: (_, __) => const Text('home'),
                    routes: moduleRoutes,
                  ),
                ]
              : [
                  GoRoute(path: '/', builder: (_, __) => const Text('home')),
                  ...moduleRoutes,
                ],
        );
        addTearDown(router.dispose);
        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        await tester.pumpAndSettle();
        expect(router.namedLocation('leaf'), '/example/details/leaf');
        expect(find.text('named page'), findsOneWidget);
        router.go('/');
        await tester.pumpAndSettle();
        expect(exits, 1);
        expect(find.text('named page'), findsOneWidget);
      },
    );
  }
}
