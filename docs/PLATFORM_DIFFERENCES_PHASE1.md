# 移动端与桌面端差异维护：第一阶段

状态：用户已批准实施；本地基础实现与定向测试已通过，macOS Debug 启动与热重载已确认；完整质量门禁受新增并行 Windows 语义测试的格式和断言失败阻断，见验证范围。未提交、未派遣、未合并或发布。

## 范围与实现

本阶段复用已有 `AppHostFamily` 与支持策略，不增加新的平台清单或能力框架。支持摘要从原有逐平台声明派生移动端、桌面端、Web 三列，保留具体平台名称；机器声明与模块入口支持范围不变。iOS 仍仅建模，不由分组获得宿主或验收声明。

新增 `module_registry/AppPlatformScope`，由主应用与分类专注窗口注入各自持有的平台快照。3D 模块通过 Scope 获取身份，`SceneInteractionPolicy` 继续消费原有 `scene_controls` 功能策略：Android 只读，macOS/Windows 可操控。窗口宽度只控制布局，不决定模块的功能模式。模块不依赖 `app/` 获取平台信息。

教学内容和已有操作布局复用；既有权限行为不变。NFC 产品方案保持独立，本阶段不实现 NFC 桥接或原生分发。权限、开关与硬件状态的共用处理留到下一阶段，按具体业务逐步推进。

新增模块与差异维护规则记录在 [支持维护入口](module_availability/README.md)，生成摘要见 [支持矩阵](module_availability/matrix.md)。

## Agent Hub 边界

工程身份为 `flutter-forge`，运行仓库为 `flutter_forge`。已通过有界 `agent-context` 获取当前上下文；返回 PARTIAL 且无 blockers，不能将未读取候选解释为已分析。

本期任务通过 [dispatch 声明](agent/platform-phase1.dispatch.json) 明确单个 MEDIUM 风险任务的源码、测试与生成输出范围，已用 Hub 的 `spec_errors` 和实际 workspace 配置完成离线契约校验，错误列表为空。当前在用户批准的开发工作区本地实施；spec 的离线契约校验不等于 Graph PLAN_ONLY 运行、Worker 派遣或受管集成。当前树包含用户原有文档与 `release/1.2.10/`，不擅自清理、提交或冻结脏树以满足 Hub 集成条件。

Hub 现有命令标识用于 analyze 和定向 Flutter 测试。Forge 根质量门禁另行执行并记录，不更改门禁脚本，也不把 analyze 单项当作完整验收。

## 验证范围

- 工具定向测试 26 项通过：分组摘要保留具体平台边界与功能范围，机器声明不变，生成物无漂移。
- Flutter 定向测试 30 项通过：注入 Android/macOS 身份分别在 360dp、1280dp 保持只读/交互模式；Web、iOS及非目标平台不获得桌面控件；主窗口和分类窗口可读取平台快照；已有 3D 功能与路由守卫回归。入口允许注入已有 `SceneViewerRuntime` 接口，Widget 测试使用 fake，不触发真实 GPU。
- 首轮完整质量门禁：生成物、bare analyze、workspace 与工具测试、35 个模块测试存在性通过；两份并行变更文件需要格式整理，整体退出 1。用户随后明确批准仅格式化 `packages/desktop_multi_window/test/desktop_multi_window_test.dart` 和 `tool/module_scaffold_test.dart`，这两份文件已执行 `dart format`。
- 授权格式整理后的完整门禁：生成物、bare analyze、模块测试存在性通过；期间新增的未跟踪 `apps/flutter_forge/test/shared/windows_semantics_test.dart` 格式未通过，且 `slider in a pushed route sends no orphan semantics nodes` 断言失败（预期空列表，实际 `[6]`），整体仍退出 1。该测试单独构造 Flutter MaterialApp/Slider，不导入本任务的平台 Scope 或 3D 模块；保留并行工作原样，未扩大用户“仅这两个文件”的授权。完整门禁不能描述为通过。
- 门禁执行使用 `PUB_HOSTED_URL=https://pub.dev`，没有改写锁文件；验证针对当时整个工作区。日志保留于本机 `/private/tmp/forge-platform-phase1-quality-gate-final.log`，后续并行源码变化后需重新验证，不能沿用本次结果。
- macOS Debug 应用构建并启动，完成热重载；经快速打开进入 3D 页，截图可见真实 Impeller Metal 场景和桌面操控区。鼠标滚轮使场景从自动巡展转为手动操控并改变缩放，运行时错误查询为空。此为当前 Mac 的局部操作确认，不是完整桌面或硬件验收。
- Android/iOS/Windows 真机或真实主机验收：本阶段未完成，不从当前 Mac 或测试注入推定。


## 后续：按平台组织自动化测试

2026-10-26 基于本阶段的平台身份与能力策略，后续测试拆分、真实宿主专项和执行记录统一见 [平台自动化测试实施计划](PLATFORM_AUTOMATION_TEST_PLAN.md)。本文上方保留当时执行记录；Windows #33 回归修复及后续门禁结果见 [修复说明](reports/WINDOWS_ISSUE33_FIXES-20261026.md)。历史失败不代表当前工作区仍失败，也不由新的本地测试结果推定所有平台已验收。
