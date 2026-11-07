import 'package:flutter/material.dart';
import 'package:flutter_forge_app/app/module_discovery_panel.dart';
import 'package:flutter_forge_app/module_registry/module_manifest.dart';
import 'package:flutter_forge_app/module_registry/app_platform_snapshot.dart';
import 'package:flutter_forge_app/shared/platform/build_features.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('offline discovery exposes only three runnable fixed examples', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ModuleDiscoveryPanel(
              modules: moduleManifest,
              platform: const AppPlatformSnapshot(
                platform: AppTargetPlatform.android,
              ),
            ),
          ),
        ),
      ),
    );
    for (var frame = 0; frame < 8; frame++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byKey(const ValueKey('discovery-question')), findsNothing);
    expect(find.byKey(const ValueKey('discovery-submit')), findsNothing);
    for (final label in ['布局与尺寸', '异步与并发', '网络与设备']) {
      final button = find.widgetWithText(TextButton, label);
      await tester.ensureVisible(button);
      for (var frame = 0; frame < 8; frame++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.tap(button);
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(
        find.byKey(const ValueKey('discovery-replay-badge')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(const SizedBox.shrink());
  }, skip: !offlineEdition);
}
