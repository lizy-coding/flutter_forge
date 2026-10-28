import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_forge_app/app/desktop_window_host.dart';
import 'package:flutter_forge_app/module_registry/app_platform_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/automation/app_fixture.dart';
import '../support/automation/smoke_scenarios.dart';

void main() {
  final targets = kIsWeb
      ? [AppTargetPlatform.web]
      : [
          AppTargetPlatform.android,
          AppTargetPlatform.macOS,
          AppTargetPlatform.windows,
          AppTargetPlatform.web,
        ];
  for (final target in targets) {
    testWidgets(
      'smoke.core.${target.name}',
      (tester) async {
        // Widget evidence only; real host integration uses the same fixture
        // without this channel mock.
        final messenger = tester.binding.defaultBinaryMessenger;
        messenger.setMockMethodCallHandler(
          DesktopWindowHost.channel,
          (_) async => <String, Object?>{},
        );
        addTearDown(
          () => messenger.setMockMethodCallHandler(
            DesktopWindowHost.channel,
            null,
          ),
        );
        tester.view.physicalSize = target == AppTargetPlatform.android
            ? const Size(390, 844)
            : const Size(1280, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await withApp(
          tester,
          AppPlatformSnapshot(platform: target),
          (app) => runCoreSmoke(tester, app),
        );
      },
      variant: TargetPlatformVariant.only(switch (target) {
        AppTargetPlatform.android => TargetPlatform.android,
        AppTargetPlatform.macOS => TargetPlatform.macOS,
        _ => TargetPlatform.windows,
      }),
    );
  }
}
