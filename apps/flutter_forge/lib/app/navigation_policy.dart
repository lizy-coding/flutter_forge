import '../module_registry/app_platform_snapshot.dart';

enum CategoryNavigationMode { inApp, separateWindow }

class NavigationPolicy {
  const NavigationPolicy._();

  static const double compactWidthBreakpoint = 600;

  static CategoryNavigationMode resolve({
    required AppPlatformSnapshot platform,
    required double width,
    required bool multiWindowSupported,
  }) {
    if (platform.hostFamily != AppHostFamily.desktop) {
      return CategoryNavigationMode.inApp;
    }

    if (width < compactWidthBreakpoint || !multiWindowSupported) {
      return CategoryNavigationMode.inApp;
    }

    return CategoryNavigationMode.separateWindow;
  }
}
