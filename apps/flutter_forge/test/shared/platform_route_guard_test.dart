import 'package:flutter/material.dart';
import 'package:flutter_forge_app/app/app.dart';
import 'package:flutter_forge_app/app/app_platform_provider.dart';
import 'package:flutter_forge_app/app/router/app_router.dart';
import 'package:flutter_forge_app/app/unsupported_module_page.dart';
import 'package:flutter_forge_app/module_registry/app_platform_snapshot.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpAt(
    WidgetTester tester, {
    required AppPlatformSnapshot platform,
    required String location,
  }) async {
    final router = AppRouter.create(platform)..go(location);
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appPlatformProvider.overrideWithValue(platform)],
        child: App(router: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('unsupported module path renders the stable guard page', (
    tester,
  ) async {
    await pumpAt(
      tester,
      platform: const AppPlatformSnapshot(platform: AppTargetPlatform.iOS),
      location: '/file-picker',
    );

    expect(find.byType(UnsupportedModulePage), findsOneWidget);
    expect(find.text('当前平台暂不支持此模块'), findsOneWidget);
    expect(find.text('当前平台：iOS'), findsOneWidget);
    expect(find.text('支持平台：Android、macOS、Web、Windows'), findsOneWidget);

    await tester.tap(find.text('返回模块目录'));
    await tester.pumpAndSettle();
    expect(find.text('Flutter 学习实验室'), findsOneWidget);
  });

  testWidgets('supported module path renders its business page', (
    tester,
  ) async {
    await pumpAt(
      tester,
      platform: const AppPlatformSnapshot(platform: AppTargetPlatform.android),
      location: '/file-picker',
    );

    expect(find.byType(UnsupportedModulePage), findsNothing);
    expect(find.byKey(const Key('pick-file-button')), findsOneWidget);
  });
}
