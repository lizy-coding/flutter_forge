import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_forge_app/module_registry/app_platform_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/support/automation/app_fixture.dart';
import '../test/support/automation/interactions.dart';
import '../test/support/automation/platform_adapter.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('3D viewer desktop interaction flow', (tester) async {
    expect(
      {TargetPlatform.macOS, TargetPlatform.windows},
      contains(defaultTargetPlatform),
      reason: 'This acceptance flow requires a desktop Flutter GPU host.',
    );

    final platform = AppPlatformSnapshot.detect();
    await withApp(tester, platform, (app) async {
      final router = app.router;
      final adapter = PlatformAdapter(platform);
      await waitForWidget(tester, adapter.home);
      final module = moduleByPath('/flutter-scene-3d');
      await adapter.openCategory(tester, module.category);
      await adapter.openModule(tester, module);
      final categoryPage = find.byKey(
        ValueKey('category-page:${module.category.name}'),
      );
      await waitForWidget(
        tester,
        find.byKey(const Key('scene-interaction-surface')),
      );
      expect(find.byKey(const Key('scene-error')), findsNothing);
      expect(find.text('设备部件检查'), findsOneWidget);

      await tester.tap(find.byTooltip('暂停环绕'));
      await tester.pump();
      expect(find.textContaining('状态：已暂停'), findsOneWidget);

      await tester.tap(find.byKey(const Key('basic-mode')));
      await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowLeft);
      await tester.sendKeyRepeatEvent(LogicalKeyboardKey.arrowLeft);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(find.text('教学型 3D 查看器'), findsWidgets);

      final surface = find.byKey(const Key('scene-interaction-surface'));
      await tester.tap(find.byKey(const Key('enhanced-mode')));
      await tester.sendEventToBinding(
        PointerScrollEvent(
          position: tester.getCenter(surface),
          scrollDelta: const Offset(0, -160),
        ),
      );
      await pumpFrames(tester, const Duration(milliseconds: 250));
      expect(find.textContaining('缩放：1.19×'), findsOneWidget);
      await tester.tap(find.byKey(const Key('scene-orientation-thumbnail')));
      await pumpFrames(tester, const Duration(milliseconds: 450));

      await tester.tapAt(tester.getCenter(surface));
      await waitForWidget(tester, find.text('传感器'));
      expect(find.byKey(const Key('focus-selected-part')), findsOneWidget);

      final focusButton = find.byKey(const Key('focus-selected-part'));
      await tester.ensureVisible(focusButton);
      await tester.tap(focusButton);
      await pumpFrames(tester, const Duration(milliseconds: 450));
      expect(find.textContaining('距离：3.0'), findsOneWidget);

      final clearButton = find.byKey(const Key('clear-selected-part'));
      await tester.ensureVisible(clearButton);
      await tester.tap(clearButton);
      await tester.pump();
      expect(find.text('传感器'), findsNothing);

      router.go('/category/ui');
      await pumpFrames(tester, const Duration(milliseconds: 400));
      expect(categoryPage, findsOneWidget);
      router.go('/');
      await pumpFrames(tester, const Duration(milliseconds: 400));
      expect(find.byKey(const ValueKey('workbench-home')), findsOneWidget);
    });
  });
}
