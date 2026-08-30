import 'package:flutter/foundation.dart';
import 'package:flutter_forge_app/app/navigation_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android always uses in-app navigation', () {
    expect(
      NavigationPolicy.resolve(
        platform: TargetPlatform.android,
        width: 1200,
        multiWindowSupported: true,
      ),
      CategoryNavigationMode.inApp,
    );
  });

  test('iOS always uses in-app navigation', () {
    expect(
      NavigationPolicy.resolve(
        platform: TargetPlatform.iOS,
        width: 1200,
        multiWindowSupported: true,
      ),
      CategoryNavigationMode.inApp,
    );
  });

  test('compact desktop windows use in-app navigation', () {
    expect(
      NavigationPolicy.resolve(
        platform: TargetPlatform.macOS,
        width: 599,
        multiWindowSupported: true,
      ),
      CategoryNavigationMode.inApp,
    );
  });

  test('600dp desktop windows can use separate windows', () {
    expect(
      NavigationPolicy.resolve(
        platform: TargetPlatform.macOS,
        width: 600,
        multiWindowSupported: true,
      ),
      CategoryNavigationMode.separateWindow,
    );
  });

  test('unsupported multi-window hosts fall back to in-app navigation', () {
    expect(
      NavigationPolicy.resolve(
        platform: TargetPlatform.linux,
        width: 1200,
        multiWindowSupported: false,
      ),
      CategoryNavigationMode.inApp,
    );
  });
}
