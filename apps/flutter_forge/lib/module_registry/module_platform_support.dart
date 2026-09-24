import 'app_platform_snapshot.dart';

/// Declares where a module is available without coupling routing to a host.
class ModulePlatformSupport {
  const ModulePlatformSupport({this.excludedPlatforms = const {}});

  /// Product target platforms that this module explicitly does not support.
  final Set<AppTargetPlatform> excludedPlatforms;

  bool supports(AppPlatformSnapshot snapshot) {
    return snapshot.isProductTarget &&
        !excludedPlatforms.contains(snapshot.platform);
  }
}
