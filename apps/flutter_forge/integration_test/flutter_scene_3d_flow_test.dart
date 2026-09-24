import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_forge_app/app/app.dart';
import 'package:flutter_forge_app/app/app_platform_provider.dart';
import 'package:flutter_forge_app/app/router/app_router.dart';
import 'package:flutter_forge_app/module_registry/app_platform_snapshot.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  late AppPlatformSnapshot platform;
  late GoRouter router;

  setUp(() {
    platform = AppPlatformSnapshot.detect();
    router = AppRouter.create(platform)..go('/');
  });

  tearDown(() => router.dispose());

  testWidgets('3D viewer desktop interaction flow', (tester) async {
    expect(
      {TargetPlatform.macOS, TargetPlatform.windows},
      contains(defaultTargetPlatform),
      reason: 'This acceptance flow requires a desktop Flutter GPU host.',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appPlatformProvider.overrideWithValue(platform)],
        child: App(router: router),
      ),
    );
    await _pumpFrames(tester, const Duration(milliseconds: 600));
    expect(find.text('Flutter 学习实验室'), findsOneWidget);

    final moduleTile = find.byKey(const ValueKey('module:/flutter-scene-3d'));
    await tester.scrollUntilVisible(
      moduleTile,
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(moduleTile);
    await _pumpFrames(tester, const Duration(milliseconds: 200));
    await tester.tap(moduleTile);
    await _pumpUntil(
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
    await _pumpFrames(tester, const Duration(milliseconds: 250));
    expect(find.textContaining('缩放：1.19×'), findsOneWidget);
    await tester.tap(find.byKey(const Key('scene-orientation-thumbnail')));
    await _pumpFrames(tester, const Duration(milliseconds: 450));

    await tester.tapAt(tester.getCenter(surface));
    await _pumpUntil(tester, find.text('传感器'));
    expect(find.byKey(const Key('focus-selected-part')), findsOneWidget);

    final focusButton = find.byKey(const Key('focus-selected-part'));
    await tester.ensureVisible(focusButton);
    await tester.tap(focusButton);
    await _pumpFrames(tester, const Duration(milliseconds: 450));
    expect(find.textContaining('距离：3.0'), findsOneWidget);

    final clearButton = find.byKey(const Key('clear-selected-part'));
    await tester.ensureVisible(clearButton);
    await tester.tap(clearButton);
    await tester.pump();
    expect(find.text('传感器'), findsNothing);

    await tester.pageBack();
    await _pumpFrames(tester, const Duration(milliseconds: 400));
    expect(find.text('Flutter 学习实验室'), findsOneWidget);
  });
}

Future<void> _pumpFrames(WidgetTester tester, Duration duration) async {
  const step = Duration(milliseconds: 50);
  var elapsed = Duration.zero;
  while (elapsed < duration) {
    await tester.pump(step);
    elapsed += step;
  }
}

Future<void> _pumpUntil(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 8),
}) async {
  const step = Duration(milliseconds: 80);
  var elapsed = Duration.zero;
  while (finder.evaluate().isEmpty && elapsed < timeout) {
    await tester.pump(step);
    elapsed += step;
  }
  expect(finder, findsOneWidget);
}
