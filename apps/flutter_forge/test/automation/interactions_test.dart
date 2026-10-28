import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_forge_app/app/app.dart';
import 'package:flutter_forge_app/app/theme/app_theme_controller.dart';
import 'package:flutter_forge_app/module_registry/app_platform_snapshot.dart';

import '../support/automation/interactions.dart';
import '../support/automation/app_fixture.dart';

void main() {
  testWidgets('readiness timeout fails rather than silently continuing', (
    tester,
  ) async {
    await expectLater(
      () => waitForCondition(
        tester,
        () => false,
        reason: 'missing terminal state',
        timeout: const Duration(milliseconds: 160),
      ),
      throwsA(isA<TestFailure>()),
    );
  });

  testWidgets('ambiguous controls cannot receive an arbitrary first tap', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Row(
          children: [
            TextButton(onPressed: () => calls++, child: const Text('open')),
            TextButton(onPressed: () => calls++, child: const Text('open')),
          ],
        ),
      ),
    );
    await expectLater(
      () => tapVisible(tester, find.text('open')),
      throwsA(isA<TestFailure>()),
    );
    expect(calls, 0);
  });

  testWidgets('occluded controls time out without invoking handlers', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Stack(
          children: [
            TextButton(
              key: const ValueKey('covered'),
              onPressed: () => calls++,
              child: const Text('open'),
            ),
            const Positioned.fill(
              child: AbsorbPointer(child: ColoredBox(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
    await expectLater(
      () => tapVisible(tester, find.byKey(const ValueKey('covered'))),
      throwsA(isA<TestFailure>()),
    );
    expect(calls, 0);
  });
  testWidgets(
    'fixture unmounts and releases owned state when a scenario fails',
    (tester) async {
      late AppThemeController theme;
      await expectLater(
        () => withApp(
          tester,
          const AppPlatformSnapshot(platform: AppTargetPlatform.android),
          (app) async {
            theme = app.theme;
            throw StateError('scenario failed');
          },
        ),
        throwsA(isA<StateError>()),
      );
      expect(find.byType(App), findsNothing);
      expect(() => theme.addListener(() {}), throwsFlutterError);
    },
  );
}
