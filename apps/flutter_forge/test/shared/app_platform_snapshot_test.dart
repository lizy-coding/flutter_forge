import 'package:flutter/foundation.dart';
import 'package:flutter_forge_app/module_registry/app_platform_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Web identity wins over the browser operating system', () {
    final snapshot = AppPlatformSnapshot.fromFlutter(
      isWeb: true,
      targetPlatform: TargetPlatform.macOS,
    );

    expect(snapshot.platform, AppTargetPlatform.web);
    expect(snapshot.hostFamily, AppHostFamily.web);
  });

  test('maps the five product target platforms', () {
    const expected = {
      TargetPlatform.android: AppTargetPlatform.android,
      TargetPlatform.iOS: AppTargetPlatform.iOS,
      TargetPlatform.macOS: AppTargetPlatform.macOS,
      TargetPlatform.windows: AppTargetPlatform.windows,
    };

    for (final entry in expected.entries) {
      final snapshot = AppPlatformSnapshot.fromFlutter(
        isWeb: false,
        targetPlatform: entry.key,
      );
      expect(snapshot.platform, entry.value);
      expect(snapshot.isProductTarget, isTrue);
    }
  });

  test('maps Linux and Fuchsia outside the product target set', () {
    for (final platform in [TargetPlatform.linux, TargetPlatform.fuchsia]) {
      final snapshot = AppPlatformSnapshot.fromFlutter(
        isWeb: false,
        targetPlatform: platform,
      );
      expect(snapshot.platform, AppTargetPlatform.unsupported);
      expect(snapshot.isProductTarget, isFalse);
    }
  });
}
