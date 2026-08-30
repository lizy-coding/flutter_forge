# Flutter Forge 自动化界面测试验收报告

- 执行日期：2026-08-27（Asia/Shanghai）
- 执行者：Codex
- flutter_forge HEAD：`7c262c35e5c4c0ed7232e9ae36bc22423c65c735`（`dev`，本地领先 `origin/dev` 12 个提交）
- flutter_forge origin/dev：`432ad04c5cfdfb0080f0373f0d5d54badd7e6a17`
- agent-hub HEAD：`f46292b0ced88f6fe5c54548035dcf69861520fe`（`main`）
- agent-hub origin/main：`6fc68fba1a5fa8d6eb4582f7d9019e163cfb6d32`

## 分层结果

### L0 / S1：环境与编排自检 — PASS

- Flutter `3.44.6` / Dart `3.12.2` 可用。
- `agent_hub` 可导入。
- `workspace/config.json` 将 `flutter_forge` 声明为唯一活动主仓库，路径为 `../../langGraph/flutter_forge`。
- Agent Hub 全量测试：`Ran 149 tests in 98.179s`，`OK`。

### L1 + L3 + L4 / S2 + S3：Flutter 仓库门禁 — PASS

- `bash tool/quality_gate.sh`：exit `0`，6/6 阶段通过。
- 主应用测试：52 项通过。
- 包测试：`gcode_core` 31、`flutter_study_learning` 11、`file_picker_bridge` 3、`flutter_ioc_core` 22，全部通过。
- 测试布局：20/20 模块均有测试，缺失 0。
- `flutter analyze`：No issues found。
- FlutterGuard：5 个 MEDIUM，0 个 HIGH，门禁通过。

### L2 / S4：远端 CI — PASS（基于已批准远端基线）

- `gh run list --branch dev` 最新 push CI：run `32803551802`，`completed success`。
- 该 run 的 `headSha` 为 `432ad04c5cfdfb0080f0373f0d5d54badd7e6a17`，与当前 `origin/dev` 一致。
- 当前本地 HEAD 尚未推送，因此没有把远端 CI 结果冒充为当前本地提交的验证。

### L5 / S5：LangGraph ShadowBenchmark — PASS

- Shadow cases：6/6 通过。
- repository precision/recall：`1.0 / 1.0`。
- evidence/rule coverage：`1.0 / 1.0`。
- unknown preservation：`1.0`；false-positive rate：`0.0`。
- architecture ownership/extraction accuracy：`1.0 / 1.0`。
- unsupported promotions：`0`；architecture disagreement：`0`。

### UI-E2E：真实 macOS Release 界面验收 — FAIL

执行目标：`apps/flutter_forge/build/macos/Build/Products/Release/Flutter Forge.app`，通过 Computer Use 操作真实窗口并读取无障碍树/截图。

通过项：

- 主目录成功启动，展示分类、模块卡片、难度/状态信息和平台不支持模块态。
- “三棵树与生命周期”入口成功导航。
- 子页“基础 Widget 重建”成功进入；点击“触发重建”后，页面状态由 `0` 更新为 `1`。
- 分层返回从子页回到模块页成功。
- G-code 页面成功进入，示例文本、解析器、轨迹画布和播放控件均可见。
- 智能吸附线画板成功进入，画板工具栏、颜色/线宽控制、清空按钮和元素计数均可见。
- 下载飞入动效成功进入；下载按钮触发了飞入动画。
- 字体选择器成功进入；切换字体行后预览和选中态更新；系统字体文件对话框可打开并可取消返回。
- Overlay 跟随方案、Dio 拦截器和文件选择器页面均可进入；Dio 在当前环境显示可恢复的错误态和“重试”按钮。
- 在线视频页面成功连接并播放视频，播放时间从 `00:00` 推进到 `00:08`，页面未崩溃。
- Isolate 页面成功进入；流畅示例启动后显示进度和计算日志。
- Flutter IoC 页面成功进入；输入 `demo` 并点击新增后，名称变为 `demo`、计数由 `0` 变为 `1`。
- 桌面分类入口点击后应用仍保持存活；未观察到窗口创建导致的主窗口崩溃。

失败项：

- “三棵树 & 生命周期示例”页面在当前 macOS 窗口尺寸下出现真实布局错误：`BOTTOM OVERFLOWED BY 48 PIXELS`。这不是测试框架误报，截图中可见黄色/黑色溢出条，且遮挡了 `RepaintBoundary` 行。
- G-code 播放按钮点击后 Computer Use 返回 `AXError.failure`；应用进程仍存活、页面仍显示，但该播放交互不能判定为通过。
- “弹窗与列表交互”页面的“弹窗组件”入口跳转到 `Page Not Found`，错误为 `GoException: no routes for location: /popup`。
- 同页面的“列表交互”入口跳转到 `Page Not Found`，错误为 `GoException: no routes for location: /list`。

上述两个路由错误与当前嵌套路由声明相吻合：`module_routes.dart` 声明的是相对路径 `popup`/`list`，但页面入口实际发起了根路径导航。

### 持久化 E2E 测试资产 — GAP

- 仓库当前没有 `integration_test/` 或 `test_driver/`。
- 因此本次 UI 验收是一次性真实窗口验收，不是可在 CI 中重复执行的 Flutter Driver/integration_test 套件。
- 建议补充主目录、模块导航、关键交互和响应式窗口尺寸的持久化 E2E 用例，并先修复上述布局溢出后再将 UI-E2E 纳入发布门禁。

### L6 / S6：发布层 — PENDING

- 本次 macOS Release 构建成功：`Flutter Forge.app`（51.3 MB）。
- Windows 安装包与 Windows 实机清单未执行，不能判定发布层通过。

## 汇总

| 层 | 状态 |
|---|---|
| L0 环境/编排 | PASS |
| L1 仓库门禁 | PASS |
| L2 远端 CI（origin/dev 基线） | PASS |
| L3 静态分析/安全扫描 | PASS |
| L4 测试层 | PASS |
| L5 LangGraph 套件 | PASS |
| UI-E2E 真实 macOS 界面 | **FAIL** |
| L6 发布/Windows 实机 | PENDING |

## 结论

当前基线不能通过“完整自动化界面测试验收”：代码质量、全量测试和编排套件均通过，但真实 macOS UI 存在 48 像素底部溢出，且 G-code 播放交互未能确认通过；同时仓库缺少可重复执行的 `integration_test` 资产。建议修复 UI 溢出、定位播放按钮的 AX 失败原因，并补齐持久化 E2E 后重新验收。

## 边界声明

本次未修改源码、基准数据、门禁脚本或 CI 工作流；未执行 `git commit` 或 `git push`。仅新增本报告；flutter_forge 中既有未跟踪文件 `tool/migrate_agent_readme_workspace_name.py` 保持不动。

## 修复后回归（2026-08-27）

本次基于上述失败项完成了最小范围修复：

- `DemoHomePage` 的固定高度入口区域改为内部可滚动列表，消除桌面窗口下的 RenderFlex 溢出。
- 弹窗与列表模块保留相对嵌套路由声明，同时将调用常量改为完整绝对地址，修复 `/popup` 与 `/list` 的 Page Not Found。
- 新增布局回归测试，以及弹窗/列表两个真实点击导航回归测试。

回归证据：

- 定向回归：5 项通过。
- `flutter analyze`：No issues found。
- `bash tool/test_all.sh`：5/5 套件通过，主应用 55 项测试通过；新增路由与布局测试均通过。
- `bash tool/verify_test_layout.sh`：20/20 模块测试存在。
- FlutterGuard：0 HIGH，5 MEDIUM，扫描通过。
- `flutter build macos --release`：成功生成 `Flutter Forge.app`（51.3 MB）。本次先执行 `flutter clean`，再串行构建，确认产物包含最新修复。
- 新 Release 真实界面回归：三棵树页面无溢出条；“弹窗组件”进入成功；“列表交互”进入“二维滚动表格演示”成功。

修复后，原报告中的两个布局/路由问题已关闭。当前仍保留的验收边界是：Windows 实机未执行，仓库尚无完整持久化 `integration_test` 套件；`quality_gate.sh` 的 Dart diff 自检在未提交工作树上会失败，因此本次以独立格式化、分析、测试、布局和扫描结果作为代码回归证据。未执行 commit/push。

## 全局自测复核（2026-08-27）

- Agent Hub 全量测试：`Ran 149 tests in 94.272s`，`OK`。
- ShadowBenchmark：6/6 cases 通过；precision/recall、evidence/rule coverage、unknown preservation 均为 `1.0`；false-positive rate `0.0`；架构 ownership/extraction accuracy `1.0/1.0`；disagreement `0`。
- Flutter Forge `bash tool/test_all.sh`：5/5 套件通过，主应用 55 项测试通过。
- `flutter analyze`：No issues found。
- `bash tool/verify_test_layout.sh`：20/20 模块测试存在。
- FlutterGuard：扫描通过，0 HIGH、5 MEDIUM。
- `flutter doctor -v`：Flutter、Android toolchain、Xcode、Chrome 和网络资源均通过；仅局域网设备 `刘煤球` 因未连接/未开启 Developer Mode 不可用。
- macOS Release 产物继续可启动，单一 Release 进程存活；可用设备为 macOS 与 Chrome。

本轮未执行 Windows 实机、Android 实机/模拟器和局域网设备验收；这些属于当前主机不可用或尚未授权的外部运行环境，不纳入本机自动化失败统计。工作树未产生测试副作用；未执行 commit/push。

## 模块交互验收（2026-08-27）

在 macOS Release 真机窗口上完成了全部 20 个注册模块的入口覆盖（包含本轮与前序同一验收批次的连续操作）：

| 模块类别 | 验收结果 | 关键交互 |
|---|---|---|
| 基础机制 | PASS | 三棵树页面、生命周期子页、重建计数更新、返回链路 |
| 异步并发 | PASS | Stream 入口、Isolate 基础/多任务入口、计算进度页面 |
| 状态管理 | PASS | 状态管理演进页面、IoC 输入 `demo` 后计数 `0 -> 1` |
| UI 与动效 | PASS | G-code 页面、吸附画板、下载动画、字体切换 |
| 弹窗与列表 | PASS | AlertDialog 打开/关闭、弹窗组件子页、列表交互二维表格、Overlay 页面 |
| 网络与平台 | PASS | Dio 错误态/重试入口、文件选择器取消、在线视频实际播放 |
| 平台禁用态 | PASS | USB 模块正确显示当前 macOS 不支持，不可点击 |

模块交互结果：入口覆盖 `20/20`；关键交互通过；未发现新的崩溃或布局溢出。在线视频在真实窗口中从 `00:00` 播放至约 `00:04`；文件选择器系统对话框成功打开并通过 Escape 取消返回；修复后的 `/popup`、`/list` 子路由均进入目标页面。

本模块验收仍不等同于 CI 可重复执行的 integration_test：仓库尚无持久化 `integration_test/` / `test_driver/`，本次证据由 Widget 回归测试与 macOS Release 真机操作共同组成。

## 维护执行结果（2026-08-27）

- 已新增 `apps/flutter_forge/integration_test/app_test.dart`，并为模块卡片增加稳定 `ValueKey`。
- macOS integration test：`flutter test integration_test/app_test.dart -d macos`，2/2 通过。
  - 逐一点击并返回所有 macOS 可用模块入口。
  - 验证“弹窗组件”和“列表交互”两个嵌套路由。
- `flutter analyze`：No issues found。
- `bash tool/test_all.sh`：5/5 套件通过，主应用 55 项测试通过。
- `bash tool/verify_test_layout.sh`：20/20 模块测试存在。
- FlutterGuard：扫描通过，0 HIGH、5 MEDIUM。
- `flutter build macos --release`：成功生成 `Flutter Forge.app`（51.3 MB）。
- Web integration test 未执行：Flutter 当前明确提示 `Web devices are not supported for integration tests yet`，不是项目测试失败。

本轮新增的 integration test 已关闭此前“完全没有持久化 E2E 资产”的缺口；后续仍需在 Windows/Android 主机执行对应平台集成测试，并在干净提交上重新执行包含 Dart diff 自检的完整 `quality_gate.sh`。
