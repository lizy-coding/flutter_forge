# GenUI 模块探索 P0/P1 接入记录

日期：2026-10-24。范围：当前未提交工作区中本轮 GenUI 模块探索改动；不是发布版本验收。工作区内另有并行进行的桌面交互/主题改动（forge_nav_tile、forge_pressable_card、forge_selectable_list、forge_interaction_tokens、glass_quota_test 等），不属于本轮范围，仅按门禁要求对未格式化的 glass_quota_test.dart 做了格式化。

2026-10-24 同日补充：多端逻辑评估与差异修复见文末「多端评估与适配」。

## 交付内容

### P0-1 渐进渲染管线

`ModuleDiscoverySession.submit` 由"整响应校验后一次性提交"改为逐条解析、逐条校验、逐条应用（`_applyMessage`）：每条 A2UI 消息先完整通过组件白名单与结构校验再进入 `SurfaceController`，无效尾消息抛错时保留已应用的有效前缀，界面随消息到达逐步更新。任何增量交付的传输源（未来真 token 流式桥接）无需改动即可获得渐进渲染。

桥接 `tool/genui_codex_bridge.py` 本轮未改动：仍等待 Codex CLI 最终结果后分块交付，不是逐 token 流。客户端渐进应用已就绪，桥接流式化留待单独验证（见"未验证"）。

### P0-2 动作分级：本地过滤零模型调用

`RefineChoice` 新增可选 `filter={by: difficulty|category|concept, value}`（带 filter 时 `prompt` 可省略）。点击后由本地按模块注册元数据过滤当前推荐树，经同一条 `UpdateComponentsMessage` 管线驱动 Surface，不调用模型、不发起 SDK 事件往返；面板在结果区显示"本地过滤：…"chip，一键清除并恢复过滤前组件快照。仅带 `prompt` 的 `RefineChoice` 才触发 `refineIntent` 重新理解意图。新一轮模型输出自动取代本地过滤状态。无匹配时保留原树并说明原因。

### P1-3 组件目录扩展

新增三个受限组件，模块事实（分类、难度、时长、概念、平台支持）全部由本地渲染，模型只提供引用与短文本：

- `CompareTable`：2～3 个模块的多维对比表，可选 `focus` 对比重点；列头提供本地打开按钮。
- `LearningPath`：2～4 步顺序建议，每步 `goal`（模型撰写，≤120 字）+ 本地模块卡片与进入按钮。
- `RecentHint`：渲染本地最近访问（最多 3 个，复用 WorkbenchHistory），快照与系统提示均携带 recents；无最近访问时渲染为空，提示词明确此时不使用。

`Note` 继续承担"为什么没有推荐某类"的说明职责。全部新组件进入白名单校验：引用必须真实存在、数量与嵌套受限、文本长度受限。

### P1-4 访客离线回放

新增 `ReplayDiscoverySource`（`module_discovery_replay.dart`）：覆盖三个示例问题（异步卡界面、宽度与布局、网络诊断），回放树使用新组件目录并引用真实模块路径；澄清请求以单条 Note 局部更新演示"只更新必要组件"；超范围问题明确报错并指引连接真实模型。面板默认使用回放源，未配置模型的访客可直接体验完整链路；状态行与结果区徽标持续标注"固定回放 · 未调用模型"，不冒充真实生成。连接真实模型仍经右上角调节按钮。

## 验证

- 定向测试：`apps/flutter_forge/test/shared/module_discovery_p0p1_test.dart` 新增 6 项——渐进应用保留有效前缀、本地过滤/清除零调用、无匹配保树说明、360dp 下三新组件渲染与本地打开、白名单校验拒绝虚构引用与非法过滤、默认面板回放端到端（含澄清局部更新与超范围报错）。既有 `module_discovery_test.dart` 3 项全部通过。
- 回归：`test/shared/` 目录 122 项全部通过。
- 质量门禁：`bash tool/quality_gate.sh` PASS（退出码 0），日志 `/tmp/p0p1-gate2.log`；生成契约含 `module_discovery_replay.dart` entrypoint 与 progressive/local-filter/replay owns 项，由 `tool/agent_indexes/contracts.js` 同步后重新生成。

测试需注意：回放源与脚本源的 `async*` 流在 FakeAsync 下偶发不关闭，定向测试沿用既有 `runAsync` 真实事件循环模式驱动提交与澄清。

## 未验证 / 边界

- 真实模型本轮未重新验收（上一轮验收见 `GENUI_MODULE_DISCOVERY-20261023.md`，桥接与传输协议未变；系统提示新增组件说明，实际生成质量需下一次真实调用确认）：PENDING。
- 桥接逐 token 流式与 `codex exec --json` 事件模式未核查：UNVERIFIED。
- Windows／移动／浏览器真实交互与发布构建：本轮未执行，不以 macOS 桌面测试替代。
- 学习示例工程边界保持：无后台任务、多会话管理、任意代码生成或跨模块依赖；组件与消息上限、白名单校验、平台判定规则全部沿用。

## 多端评估与适配（2026-10-24 同日）

按当前逻辑可用性评估（不做平台构建验证），并修复发现的多端差异：

| 平台 | 结论 | 依据 |
| --- | --- | --- |
| macOS | 功能完整可用 | 真实模型闭环已验收（2026-10-23/24）；audioplayers 传递插件注册后的主/子窗口引擎已检查；本轮全部定向与回归测试通过 |
| Windows | 逻辑兼容，真机证据待补 | GenUI 链路无平台分支：受限 Catalog 组件为纯 Flutter Widget，传输为 dio（HTTP/SSE），回访持久化为 SharedPreferences；`genui_surface` 能力声明含全部五端； audioplayers 支持 Windows。Windows 真机 GenUI 交互未执行（20261022 报告标 UNVERIFIED；Windows 维护报告明确不含 GenUI） |
| Android | 回放链路功能可用；真实模型属开发机边界 | 回放纯本地无网络依赖；360dp 紧凑布局已测；recents 走本机 SharedPreferences；INTERNET 权限已具备。桥接仅监听回环且传输层拒绝非 localhost 明文（模拟器 10.0.2.2 亦被拒），真机连不上开发桥——按设计属开发侧工具，访客体验由回放承担 |

发现并修复的多端差异：

1. **回放树引用平台排除模块**：网络主题的学习路径第一步 `/network-diagnostics` 在 Android/iOS/Web 被排除；异步主题的 `/isolate-basic` 在 Web 被排除。`ReplayDiscoverySource` 改为平台感知数据表——候选卡片/对比表/路径步骤统一按 `isSupportedOn(platform)` 过滤；对比表保留至少 2 个、学习路径保留至少 2 步，不足时降级为普通卡片，保证每个平台只推荐可实际进入的模块。新增示例问题只需增加一条主题数据。
2. **入口文案不一致**：`ModuleCard` 对排除模块显示「查看平台限制」，而 `CompareTable`/`LearningPath` 的入口按钮无任何提示。新增 `moduleActionLabel` 单一出口（`进入模块`/`查看平台限制`），三个组件统一使用；不支持模块仍按既有契约路由到统一不可用说明页。
3. **测试断言适配**：360dp 用例的 tooltip 统一后按索引定位；澄清轮在 widget 测试 FakeAsync 环境下状态正确但 SDK Surface 不重绘（真实运行单 zone 无此问题），澄清断言改为会话状态级，与既有测试模式一致。

验证：`module_discovery_p0p1_test.dart` 增至 10 项（新增 Android 网络树过滤、Web 异步树过滤、排除步骤文案三端用例与默认面板回放用例），`test/shared/` 126 项全部通过，`bash tool/quality_gate.sh` PASS（退出码 0，日志 `/tmp/p0p1-gate3.log`）。

仍属设计边界（不修复）：Android/iOS/Web 真实模型接入依赖可达的 HTTPS 端点，本机 Codex 桥接不作为公共后端；`network-diagnostics` 等模块的平台排除来自共用能力规则推导，不在此调整。
