import 'package:forge_scene_viewer/forge_scene_viewer.dart';

SceneViewerRuntime createDeviceSceneRuntime() => FlutterSceneViewerRuntime(
  parts: const [
    ScenePartDefinition(
      id: 'cuboid',
      label: '机身',
      shape: ScenePartShape.cuboid,
      x: -1.4,
      width: 1.2,
      height: 1,
      depth: 1,
    ),
    ScenePartDefinition(
      id: 'sphere',
      label: '传感器',
      shape: ScenePartShape.sphere,
      width: 1.24,
    ),
    ScenePartDefinition(
      id: 'cylinder',
      label: '驱动轴',
      shape: ScenePartShape.cylinder,
      x: 1.4,
      width: 1.1,
      height: 1.2,
    ),
  ],
);
