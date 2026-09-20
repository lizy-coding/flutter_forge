import 'package:flutter/foundation.dart';

/// Declares where a module is available without coupling routing to a host.
class ModulePlatformSupport {
  const ModulePlatformSupport({this.nativePlatforms, this.web = false});

  /// A null set means every native Flutter host is supported.
  final Set<TargetPlatform>? nativePlatforms;

  /// Whether the browser implementation is supported.
  final bool web;

  bool supports(TargetPlatform platform, {required bool isWeb}) {
    if (isWeb) return web;
    final platforms = nativePlatforms;
    return platforms == null || platforms.contains(platform);
  }
}
