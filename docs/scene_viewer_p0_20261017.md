# 内部 3D 查看包与 P0 绘制观测验收

日期：2026-10-17。范围：当前工作区，基础 HEAD `6910044320f33ae27aa32d8ff5e2617672ccb248`，包含本批与既有未提交内容；不表示发布版本验收。

## 已实现

先建立 `packages/forge_scene_viewer`，将相机、选择和 Flutter Scene 适配迁入包内，迁移阶段原有 20 项定向回归通过。教学模块保留学习内容、三个部件的定义及平台交互策略。应用构建 hook 通过内部包公开入口访问构建辅助 API；上游依赖继续固定为 `flutter_scene 0.23.0`。

随后在内部包实现按需、持续和手动重绘；支持保持姿态的单帧重绘，采样启停、清空统计、只含元数据的单帧 Pass 抓取和诊断快照复制。采集绘制请求与合并次数、实际渲染调用、正常返回与异常、调用频率、场景 CPU 耗时分位数、Flutter 窗口 build/raster、超预算比例和绘制规格。诊断面板包含最近活动窗口趋势及最近动作。

相机运动由可见性敏感的独立帧驱动推进；静止后停止主动调度，恢复时重置时钟。状态文字与方向缩略图已移除各自的周期 Timer，改为共享发布信号。诊断面板与场景使用独立重绘边界，统计发布、采样控制和清空不会触发场景绘制。初始化失败在视图挂载之前也能发布错误；退出释放本包监听、计时器和采样回调。

Android 继续仅显示只读诊断，维持既有只读查看与自动巡展策略。模块路由保持 `/flutter-scene-3d`；平台范围未扩大。

## 验证

| 检查 | 结果 | 证据范围 |
|---|---|---|
| P0 与教学模块定向测试 | PASS，35 项 | 调度、计数、窗口边界、抓取失败恢复、复制、只读界面与生命周期；其中内部包 22 项、应用模块 13 项 |
| 完整质量门禁 | PASS，5 阶段 | 生成契约、只读格式、bare analyze、workspace／工具测试、模块测试存在性 |
| 应用全量测试 | PASS，299 项 | 当前工作区结果；不全部归因于本批 |
| 工作区包全量测试 | PASS，154 项 | 原有包 132 项、查看包 22 项 |
| 工具测试与脚手架测试 | PASS | Node 25 项与模块脚手架回归；30／30 模块具有测试 |
| macOS Profile 真实绘制流程 | PASS | 稳定后静止 5 秒调用数不增长；单帧恰好 +1；持续绘制保持相机姿态；Pass 抓取及停止采样保持语义 |
| macOS Debug 与热重载 | PASS | 正常应用界面显示三个部件、选中高亮及诊断面板；热重载成功 |
| Windows／Android 真实主机 | PENDING | 本批未执行相应真实主机 GPU 验收 |

Profile 流程命令（在 `apps/flutter_forge` 执行）：

```bash
flutter drive --driver=test_driver/scene_diagnostics.dart \
  --target=integration_test/flutter_scene_3d_diagnostics_test.dart \
  -d macos --profile --no-pub
```

实测诊断快照见 [Profile JSON](evidence/scene_viewer_p0_20261017_profile.json)。该次场景物理尺寸为 1768 × 640，DPR 2，实际抗锯齿策略为 MSAA；抓取到 ScenePass 与 ResolvePass。CPU 示例窗口只有 13 个普通场景样本，P50 0.502ms、P95 0.659ms，仅展示数据链路，不作为吞吐基准或其他模型的性能承诺。

## 口径与限制

渲染调用返回、GPU 完成和屏幕可见首帧分别解释。P0 没有采集 GPU 执行时间、显存或底层 draw call；相应值保持为空。Flutter 帧耗时覆盖当前窗口，包括普通 UI，不能归因于 3D 本身。详细数据窗口在采样时随活动推进，静止或停止采样后保留最后窗口；Pass 抓取单独标记并排除在普通场景 CPU 分位数之外。

界面检查通过辅助访问树与截图观察进行，未代替用户手工操作体验或读屏专项验收。期间观察到 Flutter 引擎 AXTree 更新错误日志，Dart 运行时错误查询为空；该引擎日志仍需单独归因，不纳入本批绘制控制通过结论。

既有改动已按任务开始时保存的文件内容校验：除本批需要更新的 AI_PROJECT_CONTEXT、CONTEXT 和 ADR 索引外，其余原有已修改文件保持原内容；这些重叠文档在原内容上追加或定点更新。未修改质量门禁或 CI 语义，未提交、未推送、未发布。

架构决策见 [ADR 0017](adr/0017-scene-viewer-package-and-render-observability.md)，使用与指标口径见 [内部包 README](../packages/forge_scene_viewer/README.md)。
