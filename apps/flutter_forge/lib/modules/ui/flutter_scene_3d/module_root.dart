import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_forge_app/shared/learning/learning_scaffold.dart';

import 'scene_camera_controller.dart';
import 'scene_runtime.dart';
import 'scene_selection_controller.dart';

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
      title: '教学型 3D 查看器',
      interactiveDemo: _SceneDemo(
        runtime: _runtime,
        initialization: _initialization,
      ),
      sections: const [
        LearningObjectives(
          objectives: [
            '理解 Scene、Node、Mesh 与 PerspectiveCamera 的最小协作关系',
            '比较离散按钮与拖拽、滚轮、键盘共同驱动的轨道相机',
            '使用方向缩略图、扩展缩放和实时状态保持空间定位感',
            '使用屏幕射线选择最近部件，并将镜头平滑聚焦到命中对象',
            '实现自动巡展、手动接管、惯性滑行与低动态观察模式',
            '把快速演进的 flutter_scene API 隔离在模块本地运行时边界',
          ],
        ),
        ConceptChips(
          concepts: ['Flutter GPU', 'Scene', 'Raycast', 'Node', 'Camera'],
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
            '不要让自动巡展在使用者接管后自行恢复，避免相机争夺控制权。',
            '缩略图只表达方向与缩放，不应重复创建第二个 GPU 场景。',
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
  final FocusNode _focusNode = FocusNode(debugLabel: '3d-viewer-controls');
  final GlobalKey _sceneSurfaceKey = GlobalKey();
  bool? _lastReducedMotion;

  SceneCameraController get _camera => widget.runtime.camera;

  @override
  void initState() {
    super.initState();
    _camera.addListener(_onCameraChanged);
    widget.runtime.selection.addListener(_onCameraChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    if (_lastReducedMotion != reducedMotion) {
      _lastReducedMotion = reducedMotion;
      _camera.setReducedMotion(reducedMotion);
    }
  }

  @override
  void dispose() {
    _camera.removeListener(_onCameraChanged);
    widget.runtime.selection.removeListener(_onCameraChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _onCameraChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('设备部件检查', style: TextStyle(fontWeight: FontWeight.bold)),
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
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Listener(
                        onPointerDown: (_) => _focusNode.requestFocus(),
                        onPointerSignal: (event) {
                          if (event is PointerScrollEvent &&
                              _camera.enhancedMode) {
                            _focusNode.requestFocus();
                            _camera.beginInteraction();
                            _camera.zoomBy(event.scrollDelta.dy * 0.004);
                          }
                        },
                        child: KeyedSubtree(
                          key: const Key('scene-interaction-surface'),
                          child: GestureDetector(
                            key: _sceneSurfaceKey,
                            behavior: HitTestBehavior.opaque,
                            onTapUp: (details) {
                              final box =
                                  _sceneSurfaceKey.currentContext
                                          ?.findRenderObject()
                                      as RenderBox?;
                              if (box != null) {
                                widget.runtime.selectAt(
                                  details.localPosition,
                                  box.size,
                                );
                              }
                            },
                            onPanStart: (_) => _camera.beginInteraction(),
                            onPanUpdate: (details) =>
                                _camera.dragBy(details.delta),
                            onPanEnd: (details) => _camera.endInteraction(
                              details.velocity.pixelsPerSecond,
                            ),
                            child: widget.runtime.buildView(),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 12,
                        right: 12,
                        child: _OrientationThumbnail(camera: _camera),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            children: [
              ChoiceChip(
                key: const Key('basic-mode'),
                label: const Text('基础模式'),
                selected: !_camera.enhancedMode,
                onSelected: (_) => _camera.setEnhancedMode(false),
              ),
              ChoiceChip(
                key: const Key('enhanced-mode'),
                label: const Text('增强模式'),
                selected: _camera.enhancedMode,
                onSelected: (_) => _camera.setEnhancedMode(true),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _camera.enhancedMode
                ? '拖拽环绕 · 滚轮缩放 · 方向键与 +/- 控制'
                : '使用下方按钮观察离散控制效果',
            textAlign: TextAlign.center,
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
          _CameraStatus(camera: _camera),
          const SizedBox(height: 8),
          _SelectionPanel(
            selection: widget.runtime.selection,
            onFocus: widget.runtime.focusSelection,
            onClear: widget.runtime.clearSelection,
          ),
        ],
      ),
    );
  }

  List<Widget> _controls() => [
    IconButton.filledTonal(
      tooltip: '向左环绕',
      onPressed: () => _camera.orbitBy(-0.25),
      icon: const Icon(Icons.rotate_left),
    ),
    IconButton.filledTonal(
      tooltip: '向右环绕',
      onPressed: () => _camera.orbitBy(0.25),
      icon: const Icon(Icons.rotate_right),
    ),
    IconButton.filledTonal(
      tooltip: '拉近相机',
      onPressed: () => _camera.animateZoomBy(-0.4),
      icon: const Icon(Icons.zoom_in),
    ),
    IconButton.filledTonal(
      tooltip: '拉远相机',
      onPressed: () => _camera.animateZoomBy(0.4),
      icon: const Icon(Icons.zoom_out),
    ),
    IconButton.filledTonal(
      tooltip: _camera.motionState == SceneMotionState.paused ? '继续环绕' : '暂停环绕',
      onPressed: _camera.togglePaused,
      icon: Icon(
        _camera.motionState == SceneMotionState.paused
            ? Icons.play_arrow
            : Icons.pause,
      ),
    ),
    IconButton.filledTonal(
      tooltip: '重置相机',
      onPressed: _camera.reset,
      icon: const Icon(Icons.restart_alt),
    ),
  ];

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final isRepeat = event is KeyRepeatEvent;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowLeft) {
      _camera.orbitBy(-0.15);
    } else if (key == LogicalKeyboardKey.arrowRight) {
      _camera.orbitBy(0.15);
    } else if (key == LogicalKeyboardKey.arrowUp) {
      _camera.beginInteraction();
      _camera.dragBy(const Offset(0, -12));
    } else if (key == LogicalKeyboardKey.arrowDown) {
      _camera.beginInteraction();
      _camera.dragBy(const Offset(0, 12));
    } else if (key == LogicalKeyboardKey.equal ||
        key == LogicalKeyboardKey.numpadAdd) {
      _camera.animateZoomBy(-0.3);
    } else if (key == LogicalKeyboardKey.minus ||
        key == LogicalKeyboardKey.numpadSubtract) {
      _camera.animateZoomBy(0.3);
    } else if (key == LogicalKeyboardKey.space) {
      if (!isRepeat) _camera.togglePaused();
    } else if (key == LogicalKeyboardKey.keyR) {
      if (!isRepeat) _camera.reset();
    } else if (key == LogicalKeyboardKey.escape) {
      widget.runtime.clearSelection();
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }
}

class _SelectionPanel extends StatelessWidget {
  const _SelectionPanel({
    required this.selection,
    required this.onFocus,
    required this.onClear,
  });

  final SceneSelectionController selection;
  final VoidCallback onFocus;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final selected = selection.selected;
    if (selected == null) {
      return const Text('点击部件查看命中信息；拖拽仍用于环绕观察', textAlign: TextAlign.center);
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            Text(selected.label, style: Theme.of(context).textTheme.titleSmall),
            Text('命中距离 ${selected.distance.toStringAsFixed(2)}'),
            Text(
              '法线 (${selected.normalX.toStringAsFixed(2)}, '
              '${selected.normalY.toStringAsFixed(2)}, '
              '${selected.normalZ.toStringAsFixed(2)})',
            ),
            FilledButton.tonalIcon(
              key: const Key('focus-selected-part'),
              onPressed: onFocus,
              icon: const Icon(Icons.center_focus_strong),
              label: const Text('聚焦'),
            ),
            TextButton(onPressed: onClear, child: const Text('取消选择')),
          ],
        ),
      ),
    );
  }
}

class _CameraStatus extends StatefulWidget {
  const _CameraStatus({required this.camera});

  final SceneCameraController camera;

  @override
  State<_CameraStatus> createState() => _CameraStatusState();
}

class _CameraStatusState extends State<_CameraStatus> {
  late final Timer _refreshTimer;

  @override
  void initState() {
    super.initState();
    widget.camera.addListener(_refresh);
    _refreshTimer = Timer.periodic(
      const Duration(milliseconds: 200),
      (_) => _refresh(),
    );
  }

  @override
  void didUpdateWidget(covariant _CameraStatus oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.camera != widget.camera) {
      oldWidget.camera.removeListener(_refresh);
      widget.camera.addListener(_refresh);
    }
  }

  @override
  void dispose() {
    _refreshTimer.cancel();
    widget.camera.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final camera = widget.camera;
    return Column(
      children: [
        Text(
          '状态：${_motionStateLabel(camera.motionState)} · '
          '距离：${camera.distance.toStringAsFixed(1)} · '
          '缩放：${camera.zoomScale.toStringAsFixed(2)}× · '
          '水平角：${_degrees(camera.yaw)}° · '
          '俯仰角：${_degrees(camera.pitch)}°',
          key: const Key('camera-status'),
          textAlign: TextAlign.center,
        ),
        if (camera.reducedMotion)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              '已启用低动态观察模式',
              key: Key('reduced-motion-status'),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }

  static int _degrees(double radians) =>
      (radians * 180 / 3.141592653589793).round();

  static String _motionStateLabel(SceneMotionState state) => switch (state) {
    SceneMotionState.autoTour => '自动巡展',
    SceneMotionState.manual => '手动操控',
    SceneMotionState.coasting => '惯性滑行',
    SceneMotionState.paused => '已暂停',
    SceneMotionState.transitioning => '平滑过渡',
  };
}

class _OrientationThumbnail extends StatefulWidget {
  const _OrientationThumbnail({required this.camera});

  final SceneCameraController camera;

  @override
  State<_OrientationThumbnail> createState() => _OrientationThumbnailState();
}

class _OrientationThumbnailState extends State<_OrientationThumbnail> {
  late final Timer _refreshTimer;

  @override
  void initState() {
    super.initState();
    widget.camera.addListener(_refresh);
    _refreshTimer = Timer.periodic(
      const Duration(milliseconds: 200),
      (_) => _refresh(),
    );
  }

  @override
  void didUpdateWidget(covariant _OrientationThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.camera != widget.camera) {
      oldWidget.camera.removeListener(_refresh);
      widget.camera.addListener(_refresh);
    }
  }

  @override
  void dispose() {
    _refreshTimer.cancel();
    widget.camera.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: '方向缩略图，点击重置视角',
      child: Tooltip(
        message: '方向缩略图 · 点击重置',
        child: Material(
          color: colorScheme.surface.withValues(alpha: 0.90),
          elevation: 2,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            key: const Key('scene-orientation-thumbnail'),
            onTap: widget.camera.reset,
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 84,
              height: 68,
              child: CustomPaint(
                painter: _OrientationThumbnailPainter(
                  yaw: widget.camera.yaw,
                  pitch: widget.camera.pitch,
                  zoomScale: widget.camera.zoomScale,
                  colorScheme: colorScheme,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OrientationThumbnailPainter extends CustomPainter {
  const _OrientationThumbnailPainter({
    required this.yaw,
    required this.pitch,
    required this.zoomScale,
    required this.colorScheme,
  });

  final double yaw;
  final double pitch;
  final double zoomScale;
  final ColorScheme colorScheme;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 - 4);
    final objectScale =
        13.0 * math.sqrt(zoomScale).clamp(0.72, 1.35).toDouble();
    final topDepth =
        5.0 +
        5.0 *
            ((pitch - SceneCameraController.minPitch) /
                    (SceneCameraController.maxPitch -
                        SceneCameraController.minPitch))
                .clamp(0.0, 1.0);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(yaw);
    final front = Rect.fromCenter(
      center: Offset.zero,
      width: objectScale * 1.45,
      height: objectScale,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(front, const Radius.circular(2)),
      Paint()..color = colorScheme.primaryContainer,
    );
    final top = Path()
      ..moveTo(front.left, front.top)
      ..lineTo(front.left + topDepth, front.top - topDepth)
      ..lineTo(front.right + topDepth, front.top - topDepth)
      ..lineTo(front.right, front.top)
      ..close();
    canvas.drawPath(
      top,
      Paint()..color = colorScheme.primary.withValues(alpha: 0.55),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(front, const Radius.circular(2)),
      Paint()
        ..color = colorScheme.outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    canvas.restore();

    final direction = Offset(math.sin(yaw), -math.cos(yaw));
    final arrowStart = center + direction * 19;
    final arrowEnd = center + direction * 27;
    canvas.drawLine(
      arrowStart,
      arrowEnd,
      Paint()
        ..color = colorScheme.tertiary
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _OrientationThumbnailPainter oldDelegate) =>
      oldDelegate.yaw != yaw ||
      oldDelegate.pitch != pitch ||
      oldDelegate.zoomScale != zoomScale ||
      oldDelegate.colorScheme != colorScheme;
}
