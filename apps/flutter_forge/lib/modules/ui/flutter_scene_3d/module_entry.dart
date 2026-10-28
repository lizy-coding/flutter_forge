import 'package:flutter/material.dart';
import 'package:forge_scene_viewer/forge_scene_viewer.dart';

import '../../../module_registry/app_platform_scope.dart';
import 'module_root.dart';
import 'scene_interaction_mode.dart';

class FlutterScene3dEntry extends StatelessWidget {
  const FlutterScene3dEntry({super.key, this.runtime});

  final SceneViewerRuntime? runtime;

  @override
  Widget build(BuildContext context) => FlutterScene3dPage(
    runtime: runtime,
    interactionMode: SceneInteractionPolicy.resolve(
      AppPlatformScope.of(context),
    ),
  );
}
