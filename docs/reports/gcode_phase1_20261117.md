# G-code 一期本地集成

范围：加载快照、后台背压、播放通知和资源所有权。源码基线为 gcode_core 2eea0b7、Forge b4ce502 加会话开始时已有生命周期改动。

## 实现

- gcode_core 新增可选 previewLimit 和 minimumSnapshotInterval；默认值保持既有累计快照 API。Forge 使用 2000 条固定预览、100ms 最小通知间隔，终态完整交付。
- 后台 worker 每次发送快照后等待 ACK，消费取消由既有 finally 关闭 port 并停止 worker。不存在无界消息积压。
- Forge 在后台读取文件/文本，冻结预览几何和 bounds；最终结果更新完整模型。页面提示预览上限。
- 播放使用独立 ValueNotifier，画布和播放面板局部更新；指令通过预建 lineNumber 索引查找。新加载和 dispose 清理旧模型引用。
- 包内 GPU readiness 回调绑定 segment-list 版本，避免替换模型后旧回调误报。

## 本地依赖

`pubspec_overrides.yaml` 指向仓库内 `.local/gcode_core`，后者是本地包 lib、shaders、pubspec.yaml 快照。正式依赖声明仍是 Git v0.2.1。这些联调文件不应直接作为正式发布版本。后续升级正式 Git revision 后需要重新生成契约并运行完整门禁。

## 定向测量

相同本地包、10 万条 G1、batchSize=2000、关闭时间节流，单进程各运行一次：

|模式|快照数|累计发布列表引用数|耗时|
|---|---:|---:|---:|
|累计快照|52|5,300,000|317ms|
|固定 2000 预览|52|400,000|256ms|

这是 direct-load 数据复制规模对照，不是 A/B/C 全链路性能验收；耗时无统计显著性结论，RSS 同进程受 GC 历史影响，不作内存改善证据。工具位于本地 gcode_core 的 tool/phase1_snapshot_benchmark.dart。

## 范围与后续

本轮以固定预览替代全量增量模型协议；最终完整模型仍需 O(N) 分配和一次完整 GPU 上传。完整 GPU 分块追加、纹理化和显存预算仍待后续。播放面板仍局部重建，尚未把所有控件拆为逐字段监听。GPU 资源清理遵循现有 Flutter GPU API，解除引用不等于同步释放显存。

## 验证结果

- gcode_core：bare analyze 无 issue；包内 74 个测试和 example 33 个测试通过。
- Forge：Flutter 3.47.8 bare analyze 无 issue；G-code 16 个定向测试通过；全量 App 测试 577 通过、8 按原配置跳过；其余 workspace Flutter 测试通过。
- Forge macOS Debug GPU 专项通过：10000 条指令（9999 非零线段）、首次绘制回调、seek、播放暂停、模型替换后的第二次 ready、销毁。测试登记为 automation_catalog 的 gcode-refresh。
- 真实宿主构建及启动成功，日志显示 Impeller MetalSDF；DTD 热重载成功，运行时错误查询为空。上述不是 Profile 帧率或 GPU 显存稳定性证据。
- 完整 quality_gate 已执行：格式、bare analyze、模块测试存在性通过。Generated contracts 及依赖事实相关工具测试因本地 path override 与正式 Git 声明不一致失败；未修改门禁或伪造生成物。正式 Git 集成后必须再跑全门禁。
- 原生专项第一次与宿主构建争用 Xcode 数据库失败；串行重跑通过，采用重跑结果。

## 可重复命令

联调 SDK：`/private/tmp/forge-flutter-3.47.8/bin/flutter`（从本机 SDK 仓库的 3.47.8 tag 创建临时 checkout，不修改原 SDK）。

在 apps/flutter_forge 下执行 `flutter test integration_test/gcode_refresh_test.dart -d macos`；普通测试从仓库根执行 `flutter test apps/flutter_forge/test/modules/ui/gcode_visualizer`。本地包使用仓库根 pubspec_overrides.yaml；内容哈希见 `.local/gcode_core_snapshot.json`。保留 local override 时不要将 lockfile 和本地快照直接用于正式发布。

后续仍需：Profile 模式 A/B/C 全链路对照、反复开关/切文件后的内存稳定值、GPU 上传和几何重建计数；本轮没有声称这些指标已经验收。
