# forge_scene_viewer

Forge workspace 内部的 Flutter Scene 查看、绘制控制与诊断包。依赖精确固定为 `flutter_scene 0.23.0`；应用通过本包 API 描述场景，并负责宿主 Flutter GPU 配置。

## 职责

包拥有相机、选择、场景适配、绘制调度、CPU 采样、Flutter 窗口帧耗时和诊断面板。教学内容、示例部件、模块注册、路由、平台入口与交互准入由应用负责。包不依赖 Forge 应用目录或教学组件。

```dart
final runtime = FlutterSceneViewerRuntime(
  parts: const [
    ScenePartDefinition(
      id: 'body', label: '机身', shape: ScenePartShape.cuboid,
      width: 1.2, height: 1, depth: 1,
    ),
  ],
);
await runtime.initialize();
// 置于有界布局内；同一运行时同时只允许挂载一个视图。
final view = runtime.buildView();
final diagnostics = SceneDiagnosticsPanel(controller: runtime.rendering);
// 运行时的创建者在页面卸载后调用 runtime.dispose()。
```

宿主构建 hook 可从 `package:forge_scene_viewer/build_hooks.dart` 导入 `buildScenes` 与 `buildMaterials`，保持上游构建 API 入口集中在内部包。应用继续管理生成资产目录。

## 绘制动作

| 模式／动作 | 语义 |
|---|---|
| 按需绘制 | 有相机运动时连续驱动，静止后只响应状态或布局变化 |
| 持续绘制 | 持续请求场景绘制，不自动改变相机运动状态 |
| 手动重绘 | 暂停相机运动和连续驱动；调用方应禁用直接操控 |
| 重绘一帧 | 请求一次绘制，不推进相机时间；同一显示帧内请求会合并 |
| 开始／停止采样 | 独立控制详细耗时采样；停止后保留最后统计窗口 |
| 清空统计 | 清空采样与计数，不改变场景或调度模式 |
| 抓取一帧 Pass | 仅抓元数据和 CPU 耗时，不抓图片，不改变当前模式 |

从手动模式返回按需模式会保持相机暂停；继续巡展需要用户明确操作。系统低动态偏好始终保留。视图响应 TickerMode 和应用前后台状态，恢复时重置运动时钟；卸载视图停止采样与诊断发布，dispose 释放自身监听和计时器。

## 数据口径

- 请求次数与合并次数来自调度器；实际调用、正常返回和异常计数在 `Scene.render` 调用边界采集。Ticker 不计为绘制。
- 场景调用频率是最近一秒的渲染调用数，不表示显示器实际呈现 FPS。正常返回不证明 GPU 完成或可见首帧。
- 场景 CPU 耗时仅包围实际渲染调用，不是 GPU 执行时间；冷启动与稳定运行应分别采样对比。
- Flutter build/raster 来自当前引擎窗口的 FrameTiming 回调，包含诊断面板等 UI，不能单独归因于 3D；回调可能批量延迟到达。
- 超预算比例按窗口刷新率比较 build 或 raster 任一阶段，不能把二者相加当作 GPU 耗时。刷新率不可读时使用 60Hz 基准。
- 详细统计保留最近活动窗口（最多十秒／1200 条）；静止后不主动刷新窗口，停止采样后冻结耗时样本。新数据到达时淘汰旧样本。
- Pass 抓取单独标记，排除在正常场景 CPU 分位数之外；并发请求被合并为单个进行中任务，失败可再次操作。
- 诊断数据最多每 500ms 合并发布；静止后发布最后的零调用频率便停止计时器。窗口帧回调本身不触发面板刷新，避免诊断 UI 自己形成刷新循环。
- GPU 执行耗时、显存、底层 draw call 和实际 GPU 后端未采集时明确保持空值。物理像素尺寸是当前配置推导值，单帧抓取尺寸来自引擎结果。

`Scene.render` 是上游公开的低层接口。本包用它提供可检测的调用边界与单帧调度，通过独立 RepaintBoundary 避免诊断或相机说明文字刷新导致场景重绘。新增引擎语义组件或其他 SceneView 自动能力时，需要在适配器中显式评估。

## 验证

```bash
flutter test --no-pub packages/forge_scene_viewer/test
```

仓库根目录执行完整 `bash tool/quality_gate.sh`。GPU 验收使用应用内 `integration_test/flutter_scene_3d_diagnostics_test.dart`；纯逻辑和 Widget 测试不代表真实 GPU 首帧或平台验收。
