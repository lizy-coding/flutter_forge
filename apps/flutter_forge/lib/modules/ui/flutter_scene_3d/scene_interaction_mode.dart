import 'package:flutter/foundation.dart';

enum SceneInteractionMode { interactive, viewOnly }

class SceneInteractionPolicy {
  const SceneInteractionPolicy._();

  static SceneInteractionMode resolve(TargetPlatform platform) =>
      platform == TargetPlatform.android
      ? SceneInteractionMode.viewOnly
      : SceneInteractionMode.interactive;
}
