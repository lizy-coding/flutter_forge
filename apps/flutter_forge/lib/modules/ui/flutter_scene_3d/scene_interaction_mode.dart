import 'package:flutter/foundation.dart';

import '../../../module_registry/app_platform_snapshot.dart';
import '../../../module_registry/module_platform_policies.dart';

enum SceneInteractionMode { interactive, viewOnly }

class SceneInteractionPolicy {
  const SceneInteractionPolicy._();

  static SceneInteractionMode resolve(TargetPlatform platform) =>
      modulePlatformPolicies['flutter_scene_3d']!.supportsFeature(
        'scene_controls',
        AppPlatformSnapshot.fromFlutter(
          isWeb: kIsWeb,
          targetPlatform: platform,
        ),
      )
      ? SceneInteractionMode.interactive
      : SceneInteractionMode.viewOnly;
}
