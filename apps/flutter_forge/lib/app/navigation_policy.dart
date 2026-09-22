enum AppNavigationLayout { compact, rail, sidebar }

class NavigationPolicy {
  const NavigationPolicy._();

  static const double compactWidthBreakpoint = 600;
  static const double sidebarWidthBreakpoint = 1024;

  static AppNavigationLayout layoutFor({
    required double width,
    required bool sidebarExpanded,
  }) {
    if (width < compactWidthBreakpoint) return AppNavigationLayout.compact;
    if (width < sidebarWidthBreakpoint || !sidebarExpanded) {
      return AppNavigationLayout.rail;
    }
    return AppNavigationLayout.sidebar;
  }
}
