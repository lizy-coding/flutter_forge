import 'package:flutter/material.dart';
import 'package:flutter_forge_app/app/app.dart';
import 'package:flutter_forge_app/app/app_platform_provider.dart';
import 'package:flutter_forge_app/app/router/app_router.dart';
import 'package:flutter_forge_app/app/theme/app_theme_controller.dart';
import 'package:flutter_forge_app/module_registry/app_platform_snapshot.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final width in [320.0, 390.0]) {
    testWidgets('search is reachable without scrolling at $width dp', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(Size(width, 720));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      const platform = AppPlatformSnapshot(platform: AppTargetPlatform.android);
      final router = AppRouter.create(platform);
      final theme = AppThemeController.forTesting();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [appPlatformProvider.overrideWithValue(platform)],
          child: App(router: router, themeController: theme),
        ),
      );
      await tester.pumpAndSettle();
      final search = find.byKey(const ValueKey('learning-home-search'));
      expect(search.hitTestable(), findsOneWidget);
      expect(tester.getBottomRight(search).dy, lessThan(360));
      await tester.tap(search);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, 'gpu');
      await tester.pumpAndSettle();
      expect(find.text('图形绘制背景：认识 GPU、纹理与 Shader'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      router.dispose();
      theme.dispose();
    });
  }
}
