import 'package:flutter/foundation.dart';

enum CategoryNavigationMode { inApp, separateWindow }

class NavigationPolicy {
  const NavigationPolicy._();

  static const double compactWidthBreakpoint = 600;

  static CategoryNavigationMode resolve({
    required TargetPlatform platform,
    required double width,
    required bool multiWindowSupported,
  }) {
    if (platform == TargetPlatform.android ||
        platform == TargetPlatform.iOS ||
        platform == TargetPlatform.fuchsia) {
      return CategoryNavigationMode.inApp;
    }

    if (width < compactWidthBreakpoint || !multiWindowSupported) {
      return CategoryNavigationMode.inApp;
    }

    return CategoryNavigationMode.separateWindow;
  }
}
