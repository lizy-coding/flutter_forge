# G-code 下一轮优化记录

## 已提交检查点

- gcode_core dev：74d7a37，固定预览、背压、模型首帧保护及回归测试。
- Forge dev：1a46315，本地包快照、通知拆分和初始 GPU 专项。
- 两仓库均未推送。本检查点是用户明确要求的本地联调提交，不是正式依赖或质量门禁通过声明；已知审计问题留到本轮修复。

## 本轮实现（未提交）

1. 以 previewLimit 对应的源行截取 commands、errors、segments，并固定同一前缀的 bounds。即使首次预览延迟到更多行之后，模型仍使用共同 cutoff。
2. GcodeLoadSnapshot 新增 previewLineLimit、commandCount、errorCount、segmentCount。实际处理总数与预览列表长度分开，Forge 不再硬编码行数来猜测预览是否冻结。
3. 中间 timing issues 有界交付；issueCount 保留完整总数，issuesTruncated 标记截断。isComplete 根据总数判断，零条诊断预览不会把不完整估时变成完整。
4. commandSelection 独立通知，指令列表不再监听连续进度。seek 每帧合并为最新请求，只更新局部进度；reset、新加载和 dispose 取消排队请求。
5. 可选 GcodeRenderStats 记录 CPU 几何构建、顶点上传、帧合成、surface 和资源集合清理。原生专项验证进度/高亮、像素变化、播放复用和重复卸载；不将这些计数解释为 GPU 显存回收。

## 验证

- gcode_core：bare analyze 无 issue；79 个包测试、33 个 example 测试通过。新测试覆盖直接/后台混合指令预览、bounds、错误密集诊断以及零诊断预览的完整性语义。
- Forge：19 个 G-code 定向测试通过，覆盖 seek 合并、选择通知、取消以及真实页面内指令列表/编辑器实例不随段内播放重建。
- Forge 全量 App 测试 580 通过，8 个按原配置跳过；全量门禁的最终状态仍受本地依赖覆盖限制，不能标为 PASS。
- macOS Debug 初次增强专项通过。macOS Profile 使用已有通用 integration driver，60 帧采样、seek、播放暂停、模型替换和三次重复挂载/卸载通过。seek/播放期间几何构建和顶点上传增量均为零；所有资源集合退出时均调用 clear。
- 最近 Profile 样本：构建 P50/P95 为 0.343/0.440ms，raster P50/P95 为 0.294/0.406ms（nearest rank）。该值仅对应本次短样本，不代表持续 FPS 或与旧版的性能提升。
- 1 万条错误指令、batch=100、preview=100 的检查点对照：累计 timing issues 引用 515000 → 20000，降低约96.1%；parser errors 引用均为20000。耗时56/58ms是单次运行，不宣称吞吐提升。

原始 Profile 数据与诊断对照：`docs/evidence/gcode_phase2_profile_20261117.json`；源码快照哈希：`.local/gcode_core_snapshot.json`。

## 审计闭环状态

|问题|状态|依据|
|---|---|---|
|预览指令与轨迹边界|已修复|直接/后台混合指令和 bounds 回归|
|计时诊断累计复制|已修复|诊断上限/总数回归与检查点对照|
|指令列表每帧重建|已修复|独立选择通知与页面实例回归|
|seek 整页通知|已修复|同帧多次 seek 仅一次局部通知；取消回归|
|刷新与资源验收不足|部分完成|增加 Profile、像素与 CPU 工作计数；仍缺 A/B/C 和长期大文件内存对照|
|正式依赖和门禁|未关闭|仍使用本地 snapshot override；Git 声明/lock 不一致|

## 重复执行

从 Forge 的 apps/flutter_forge 目录：

```sh
flutter drive --no-pub -d macos --profile --target integration_test/gcode_refresh_test.dart --driver test_driver/scene_diagnostics.dart
```

flutter test 不提供 --profile；Profile 使用 flutter drive。Widget 测试中的 Flutter GPU 初始化失败分支不代表真实 GPU 验收。

gcode_core 的 `tool/phase2_diagnostics_benchmark.dart` 可用于 direct-load 引用量对照。对照源为已提交74d7a37的独立临时导出，未回退或改写用户工作区。

正式 Git 依赖收口仍需可获取的包提交及对应授权；本轮不推送、不修改门禁、不以临时本地覆盖伪造正式集成通过。

最终补充：macOS Debug 宿主热重载成功（93ms），DTD 运行时错误查询为空。完整门禁已重跑，格式、bare analyze、模块测试存在性通过；生成契约及4个依赖事实工具测试仍因本地path覆盖失败。验证过程中产生的镜像URL锁文件变化已恢复到检查点，仅保留本轮相关代码。
