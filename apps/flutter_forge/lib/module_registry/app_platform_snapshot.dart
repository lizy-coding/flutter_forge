import 'package:flutter/foundation.dart';

enum AppTargetPlatform { android, iOS, macOS, web, windows, unsupported }

enum AppHostFamily { mobile, desktop, web, unsupported }

extension AppTargetPlatformLabel on AppTargetPlatform {
  String get label => switch (this) {
    AppTargetPlatform.android => 'Android',
    AppTargetPlatform.iOS => 'iOS',
    AppTargetPlatform.macOS => 'macOS',
    AppTargetPlatform.web => 'Web',
    AppTargetPlatform.windows => 'Windows',
    AppTargetPlatform.unsupported => '非产品目标平台',
  };
}

/// Immutable host identity captured once for the current application process.
class AppPlatformSnapshot {
  const AppPlatformSnapshot({required this.platform});

  factory AppPlatformSnapshot.detect() {
    return AppPlatformSnapshot.fromFlutter(
      isWeb: kIsWeb,
      targetPlatform: defaultTargetPlatform,
    );
  }

  factory AppPlatformSnapshot.fromFlutter({
    required bool isWeb,
    required TargetPlatform targetPlatform,
  }) {
    if (isWeb) {
      return const AppPlatformSnapshot(platform: AppTargetPlatform.web);
    }

    return AppPlatformSnapshot(
      platform: switch (targetPlatform) {
        TargetPlatform.android => AppTargetPlatform.android,
        TargetPlatform.iOS => AppTargetPlatform.iOS,
        TargetPlatform.macOS => AppTargetPlatform.macOS,
        TargetPlatform.windows => AppTargetPlatform.windows,
        TargetPlatform.linux ||
        TargetPlatform.fuchsia => AppTargetPlatform.unsupported,
      },
    );
  }

  final AppTargetPlatform platform;

  bool get isWeb => platform == AppTargetPlatform.web;

  bool get isProductTarget => platform != AppTargetPlatform.unsupported;

  AppHostFamily get hostFamily => switch (platform) {
    AppTargetPlatform.android || AppTargetPlatform.iOS => AppHostFamily.mobile,
    AppTargetPlatform.macOS ||
    AppTargetPlatform.windows => AppHostFamily.desktop,
    AppTargetPlatform.web => AppHostFamily.web,
    AppTargetPlatform.unsupported => AppHostFamily.unsupported,
  };
}
