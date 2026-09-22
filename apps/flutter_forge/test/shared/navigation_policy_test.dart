import 'package:flutter_forge_app/app/navigation_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('compact windows use hidden navigation', () {
    expect(
      NavigationPolicy.layoutFor(width: 599, sidebarExpanded: true),
      AppNavigationLayout.compact,
    );
  });

  test('medium windows use a navigation rail', () {
    expect(
      NavigationPolicy.layoutFor(width: 600, sidebarExpanded: true),
      AppNavigationLayout.rail,
    );
    expect(
      NavigationPolicy.layoutFor(width: 1023, sidebarExpanded: true),
      AppNavigationLayout.rail,
    );
  });

  test('expanded windows use a sidebar', () {
    expect(
      NavigationPolicy.layoutFor(width: 1024, sidebarExpanded: true),
      AppNavigationLayout.sidebar,
    );
  });

  test('manual collapse keeps a wide window on the rail', () {
    expect(
      NavigationPolicy.layoutFor(width: 1440, sidebarExpanded: false),
      AppNavigationLayout.rail,
    );
  });
}
