# macOS AX 语义桥崩溃（引擎缺陷）分析与暴露面收拢

日期：2026-10-25。分支 `dev` + 未提交工作树。本记录描述未提交工作区修改，不代表 v1.2.10 或任何已发布安装包行为变化；不修改引擎、框架或依赖版本。

## 输入证据与范围

用户提供 Flutter Forge `1.2.9 (3)` 崩溃报告（bundle `com.flutterforge.preview`，父进程 `dartvm`，责任进程 ChatGPT / coalition `com.openai.codex`，崩溃时间 2026-10-24 00:06:53，运行约 39 分钟，主线程触发）：

```text
EXC_BAD_ACCESS (SIGSEGV), KERN_INVALID_ADDRESS at 0x48
0  flutter::AccessibilityBridge::CreateRemoveReparentedNodesUpdate() + 168
1  flutter::AccessibilityBridge::CommitUpdates() + 64
2  -[FlutterViewController updateSemantics:] + 184
…（以下直到 NSApplicationMain 全部为引擎/AppKit 帧）
```

从帧 0 到应用入口之间没有任何本项目 Dart/Swift/插件帧——崩溃完全发生在 FlutterMacOS 引擎内。

## 定位

- 引擎仅在语义（semantics）启用时才走 `updateSemantics` 路径。生产代码不调用 `ensureSemantics`（仅测试调用），因此当时有外部 AX 客户端 attached（VoiceOver、录屏、密码管理器一类）。夜跑自动化期间具体是哪个客户端 attached，`.ips` 无法判定，保留为未知。
- 上游对应 [flutter/flutter#193588](https://github.com/flutter/flutter/issues/193588)（macOS only）：框架在特定结构（如 `OverlayPortal` graft）下会发出"父节点声称的移动子节点不在同一提交内"的非法语义更新；引擎桥 `CommitUpdates` 未依据 `Unserialize` 返回值恢复，节点已释放，后续提交/AX 查询解引用悬空指针 → SIGSEGV。维护者 10-16 的复现在 debug 模式即先命中 `CreateRemoveReparentedNodesUpdate`——与本报告帧一致。
- 修复状态（2026-10-25 查证）：无已合并修复。框架侧 PR flutter#193372 待落地，issue 标 waiting for customer response；引擎侧修复暂列 P2。上游记录无应用侧 workaround。
- 版本面：本地 SDK 与发布 CI 均为 Flutter 3.47.2（engine `1cf1c4773f`）。v1.2.10 发布二进制与崩溃的 preview 构建共用同一引擎，风险同源，不只影响调试预览；当前无带修复的 stable 版本可升。
- 应用侧审计：生产 `lib/` 无 `OverlayPortal`（仅 popup_table 教学模块演示裸 `OverlayEntry`，机制不同）；genui_workbench 的 `Surface` key 由固定 surface id 构成，流式期间稳定，无整树重挂载。结论：应用不构成已知触发形状；引擎缺陷无法在应用层修复，本轮只收拢暴露面并建立可重复压测入口。

## 修改（全部未提交）

- `apps/flutter_forge/lib/modules/ui/genui_workbench/genui_workbench_page.dart`：观察面板中快照 JSON（机器调试输出，流式期间逐消息整段重写）以 `ExcludeSemantics` 不进语义树；转写 `SelectableText` 以 `MergeSemantics` 收拢为单语义节点，内容仍可读。可见 UI 不变。
- `apps/flutter_forge/test/modules/ui/genui_workbench/genui_workbench_test.dart`：+1 widget 测试。`ensureSemantics` 后遍历语义树，断言 JSON 不暴露、转写文本（文本字段 value 属性）可达。
- `apps/flutter_forge/integration_test/genui_ax_soak_test.dart`（新）：AX 语义压力浸泡。integration test 运行于真实 macOS embedder，`tester.ensureSemantics()` 等价于 AX 客户端 attached，AccessibilityBridge 随每帧提交更新——即崩溃报告的原生路径。用固定回放（零网络、确定性）驱动多轮流式重建 + 参数 churn + 周期性解释请求；测试进程存活到断言结束即该轮次未触发 SIGSEGV。`--dart-define=FORGE_AX_SOAK=true` 启用，`FORGE_AX_SOAK_ROUNDS` 调轮数（默认 24）。

不修改：引擎/框架、依赖与 `dependency_overrides`、发布流程、genui/a2ui_core 外部包、其他模块语义声明。

## 本地验证

- `flutter test test/modules/ui/genui_workbench/genui_workbench_test.dart`：7/7 PASS（含新增语义断言；analyze 零 issue）。
- soak 默认轮（最终文件版本复跑）：PASS，`AX_SOAK_RESULT:{"rounds":24,"submitted":30,"revision":40,"records":40,"surfaceIds":["constraint-lab"]}`。
- 扩展浸泡 240 轮：PASS，`AX_SOAK_RESULT:{"rounds":240,"submitted":300,"revision":400,"records":40,"surfaceIds":["constraint-lab"]}`，用时 3:49（测试内超时上限已放宽到 20 分钟；240 轮首跑曾命中旧的 8 分钟超时被杀，属测试时限而非崩溃）。240 轮结果在删除一个未使用 import 前取得，随后以最终文件复跑 24 轮确认行为一致。
- 600 轮尝试（2026-10-25 补记）：与全量门禁/冒烟并行跑时命中 20 分钟测试超时被终止，期间 app 进程存活、无崩溃证据；对照空闲机器 240 轮仅 3:49，判定为 CPU 争用失速而非缺陷信号，未取得有效数据点。长时间浸泡应避免与其他全量验证并行。
- 回归入口固化（2026-10-25）：`bash tool/smoke_baseline.sh --ax-soak` 把 AX 浸泡并入基线冒烟；用例选型见 `docs/TESTING.md`「基线冒烟」。
- `bash tool/quality_gate.sh`：**GATE_EXIT=0，5/5 PASS**（生成契约无漂移、Dart 格式、analyze 零 issue、workspace/tool 测试、模块测试存在性）。

## 边界与未证明

- soak PASS ≠ 引擎缺陷不存在。#193588 的触发需要框架产生特定非法更新形状；本 soak 用回放源且树中无 `OverlayPortal`，可能天然不产生该形状。它证明的是：当前工作台流式 churn 在语义强制开启下经过多轮提交不崩，并作为上游修复落地后的对照回归入口。
- 未做：真实 VoiceOver 长时浸泡；其他 AX 客户端（录屏/密码管理器）组合；崩溃原始样本无法按需复现（39 分钟运行仅 1 例）。
- Windows/Android/Web 语义路径未声明（该缺陷 macOS only）。
- 跟踪：关注 flutter#193588 与 PR flutter#193372；修复随 stable 发布后升级 `FLUTTER_VERSION`（须联动评估 `video_player_avfoundation` 2.11.0 override 的兼容，参见 v1.2.10 发布记录），再用本 soak 对照回归。

## 指纹（测试身份）

- Flutter 3.47.2 stable（framework `d3b14c8769`，engine `1cf1c4773f`），本机 Xcode 27.1。
- 崩溃输入：`Flutter Forge 1.2.9 (3)`，slice uuid `de7c3f87-14e0-36cf-a397-d3461810c971`，incident `6CC8D4CD-A92E-443D-9CDB-2017B686C06A`。
