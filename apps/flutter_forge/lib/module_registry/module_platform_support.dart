import 'app_platform_snapshot.dart';

/// Declares where a module entry is open without claiming device acceptance.
class ModulePlatformSupport {
  const ModulePlatformSupport({
    this.excludedPlatforms = const {},
    this.features = const {},
  });

  /// Product target platforms where this module entry remains closed.
  final Set<AppTargetPlatform> excludedPlatforms;

  final Map<String, Set<AppTargetPlatform>> features;

  bool supportsFeature(String feature, AppPlatformSnapshot snapshot) =>
      supports(snapshot) &&
      (features[feature]?.contains(snapshot.platform) ?? false);

  Iterable<AppTargetPlatform> get openTargetPlatforms => AppTargetPlatform
      .values
      .where((platform) => platform != AppTargetPlatform.unsupported)
      .where((platform) => supports(AppPlatformSnapshot(platform: platform)));

  bool supports(AppPlatformSnapshot snapshot) {
    return snapshot.isProductTarget &&
        !excludedPlatforms.contains(snapshot.platform);
  }
}
