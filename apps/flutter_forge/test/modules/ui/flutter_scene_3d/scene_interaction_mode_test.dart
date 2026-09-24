import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_forge_app/modules/ui/flutter_scene_3d/scene_interaction_mode.dart';

void main() {
  test('Android uses view-only mode while desktop remains interactive', () {
    expect(
      SceneInteractionPolicy.resolve(TargetPlatform.android),
      SceneInteractionMode.viewOnly,
    );
    expect(
      SceneInteractionPolicy.resolve(TargetPlatform.macOS),
      SceneInteractionMode.interactive,
    );
    expect(
      SceneInteractionPolicy.resolve(TargetPlatform.windows),
      SceneInteractionMode.interactive,
    );
  });
}
