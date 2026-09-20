import 'package:flutter_forge_app/app/navigation_policy.dart';
import 'package:flutter_forge_app/module_registry/app_platform_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android always uses in-app navigation', () {
    expect(
      NavigationPolicy.resolve(
        platform: const AppPlatformSnapshot(
          platform: AppTargetPlatform.android,
        ),
        width: 1200,
        multiWindowSupported: true,
      ),
      CategoryNavigationMode.inApp,
    );
  });

  test('iOS always uses in-app navigation', () {
    expect(
      NavigationPolicy.resolve(
        platform: const AppPlatformSnapshot(platform: AppTargetPlatform.iOS),
        width: 1200,
        multiWindowSupported: true,
      ),
      CategoryNavigationMode.inApp,
    );
  });

  test('Web always uses in-app navigation on a desktop browser', () {
    expect(
      NavigationPolicy.resolve(
        platform: const AppPlatformSnapshot(platform: AppTargetPlatform.web),
        width: 1200,
        multiWindowSupported: true,
      ),
      CategoryNavigationMode.inApp,
    );
  });

  test('compact desktop windows use in-app navigation', () {
    expect(
      NavigationPolicy.resolve(
        platform: const AppPlatformSnapshot(platform: AppTargetPlatform.macOS),
        width: 599,
        multiWindowSupported: true,
      ),
      CategoryNavigationMode.inApp,
    );
  });

  test('600dp desktop windows can use separate windows', () {
    expect(
      NavigationPolicy.resolve(
        platform: const AppPlatformSnapshot(platform: AppTargetPlatform.macOS),
        width: 600,
        multiWindowSupported: true,
      ),
      CategoryNavigationMode.separateWindow,
    );
  });

  test('unsupported multi-window hosts fall back to in-app navigation', () {
    expect(
      NavigationPolicy.resolve(
        platform: const AppPlatformSnapshot(
          platform: AppTargetPlatform.unsupported,
        ),
        width: 1200,
        multiWindowSupported: false,
      ),
      CategoryNavigationMode.inApp,
    );
  });
}
