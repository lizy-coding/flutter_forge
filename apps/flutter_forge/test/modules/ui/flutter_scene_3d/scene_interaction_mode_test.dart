import 'package:flutter_forge_app/module_registry/app_platform_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_forge_app/modules/ui/flutter_scene_3d/scene_interaction_mode.dart';

void main() {
  test('Android uses view-only mode while desktop remains interactive', () {
    expect(
      SceneInteractionPolicy.resolve(
        const AppPlatformSnapshot(platform: AppTargetPlatform.android),
      ),
      SceneInteractionMode.viewOnly,
    );
    expect(
      SceneInteractionPolicy.resolve(
        const AppPlatformSnapshot(platform: AppTargetPlatform.macOS),
      ),
      SceneInteractionMode.interactive,
    );
    expect(
      SceneInteractionPolicy.resolve(
        const AppPlatformSnapshot(platform: AppTargetPlatform.windows),
      ),
      SceneInteractionMode.interactive,
    );
  });

  test('unopened platforms do not acquire desktop controls', () {
    for (final platform in [
      AppTargetPlatform.web,
      AppTargetPlatform.iOS,
      AppTargetPlatform.unsupported,
    ]) {
      expect(
        SceneInteractionPolicy.resolve(AppPlatformSnapshot(platform: platform)),
        SceneInteractionMode.viewOnly,
      );
    }
  });
}
