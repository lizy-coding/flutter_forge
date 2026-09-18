import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'module_root.dart';
import 'scene_interaction_mode.dart';

class FlutterScene3dEntry extends StatelessWidget {
  const FlutterScene3dEntry({super.key});

  @override
  Widget build(BuildContext context) => FlutterScene3dPage(
    interactionMode: SceneInteractionPolicy.resolve(defaultTargetPlatform),
  );
}
