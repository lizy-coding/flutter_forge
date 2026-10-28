import 'package:flutter/widgets.dart';

import 'app_platform_snapshot.dart';

class AppPlatformScope extends InheritedWidget {
  const AppPlatformScope({
    super.key,
    required this.platform,
    required super.child,
  });

  final AppPlatformSnapshot platform;

  static AppPlatformSnapshot of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<AppPlatformScope>();
    if (scope == null) {
      throw StateError('AppPlatformScope was not initialized');
    }
    return scope.platform;
  }

  @override
  bool updateShouldNotify(AppPlatformScope oldWidget) =>
      oldWidget.platform.platform != platform.platform;
}
