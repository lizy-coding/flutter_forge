import 'package:flutter/material.dart';
import 'package:flutter_forge_app/shared/learning/learning_scaffold.dart';

import 'scene_runtime.dart';

class FlutterScene3dPage extends StatefulWidget {
  const FlutterScene3dPage({super.key, this.runtime});

  final SceneDemoRuntime? runtime;

  @override
  State<FlutterScene3dPage> createState() => _FlutterScene3dPageState();
}

class _FlutterScene3dPageState extends State<FlutterScene3dPage> {
  late final SceneDemoRuntime _runtime =
      widget.runtime ?? FlutterSceneRuntime();
  late final Future<void> _initialization = _runtime.initialize();

  @override
  Widget build(BuildContext context) {
    return LearningScaffold(
      title: 'Flutter Scene 3D 入门',
      interactiveDemo: _SceneDemo(
        runtime: _runtime,
        initialization: _initialization,
      ),
      sections: const [
        LearningObjectives(
          objectives: [
            '理解 Scene、Node、Mesh 与 PerspectiveCamera 的最小协作关系',
            '使用 SceneView 自带帧循环实现环绕观察、缩放、暂停与重置',
            '把快速演进的 flutter_scene API 隔离在模块本地运行时边界',
          ],
        ),
        ConceptChips(
          concepts: ['Flutter GPU', 'Scene', 'Node', 'Mesh', 'Camera'],
        ),
        CodeSnippetCard(
          title: '一个长方体的最小场景',
          code: '''final scene = Scene();
scene.add(Node(
  mesh: Mesh(
    CuboidGeometry(Vector3(1.8, 1.2, 1)),
    PhysicallyBasedMaterial(),
  ),
));

SceneView(scene, cameraBuilder: buildOrbitCamera);''',
          explanation: '几何体和材质只在初始化时创建；SceneView 负责渲染帧循环。',
        ),
        CommonPitfalls(
          pitfalls: [
            '不要在 build 中重复创建 GPU 几何体或材质。',
            '启用 Flutter GPU 只是主机前提，不能代替逐平台运行证据。',
            '首课刻意不加入 GLB、物理、着色器、后处理或场景编辑。',
          ],
        ),
      ],
    );
  }
}

class _SceneDemo extends StatefulWidget {
  const _SceneDemo({required this.runtime, required this.initialization});

  final SceneDemoRuntime runtime;
  final Future<void> initialization;

  @override
  State<_SceneDemo> createState() => _SceneDemoState();
}

class _SceneDemoState extends State<_SceneDemo> {
  void _change(void Function() action) => setState(action);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('交互长方体', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        SizedBox(
          height: 320,
          child: FutureBuilder<void>(
            future: widget.initialization,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(
                  key: Key('scene-error'),
                  child: Text('3D 场景初始化失败，请确认 Flutter GPU 已启用'),
                );
              }
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(
                  key: Key('scene-loading'),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text('正在准备 3D 场景'),
                    ],
                  ),
                );
              }
              return ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: widget.runtime.buildView(),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final controls = _controls();
            if (constraints.maxWidth >= 620) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: controls
                    .map(
                      (control) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: control,
                      ),
                    )
                    .toList(),
              );
            }
            return Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: controls,
            );
          },
        ),
        const SizedBox(height: 8),
        Text(
          '相机距离：${widget.runtime.zoom.toStringAsFixed(1)}',
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  List<Widget> _controls() => [
    IconButton.filledTonal(
      tooltip: '向左环绕',
      onPressed: () => _change(() => widget.runtime.orbitBy(-0.25)),
      icon: const Icon(Icons.rotate_left),
    ),
    IconButton.filledTonal(
      tooltip: '向右环绕',
      onPressed: () => _change(() => widget.runtime.orbitBy(0.25)),
      icon: const Icon(Icons.rotate_right),
    ),
    IconButton.filledTonal(
      tooltip: '拉近相机',
      onPressed: () => _change(() => widget.runtime.zoomBy(-0.4)),
      icon: const Icon(Icons.zoom_in),
    ),
    IconButton.filledTonal(
      tooltip: '拉远相机',
      onPressed: () => _change(() => widget.runtime.zoomBy(0.4)),
      icon: const Icon(Icons.zoom_out),
    ),
    IconButton.filledTonal(
      tooltip: widget.runtime.isPaused ? '继续环绕' : '暂停环绕',
      onPressed: () => _change(widget.runtime.togglePaused),
      icon: Icon(widget.runtime.isPaused ? Icons.play_arrow : Icons.pause),
    ),
    IconButton.filledTonal(
      tooltip: '重置相机',
      onPressed: () => _change(widget.runtime.resetCamera),
      icon: const Icon(Icons.restart_alt),
    ),
  ];
}
