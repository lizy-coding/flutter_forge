import '../../../module_registry/app_platform_snapshot.dart';
import '../../../module_registry/module_platform_policies.dart';

enum SceneInteractionMode { interactive, viewOnly }

class SceneInteractionPolicy {
  const SceneInteractionPolicy._();

  static SceneInteractionMode resolve(AppPlatformSnapshot platform) =>
      modulePlatformPolicies['flutter_scene_3d']!.supportsFeature(
        'scene_controls',
        platform,
      )
      ? SceneInteractionMode.interactive
      : SceneInteractionMode.viewOnly;
}
