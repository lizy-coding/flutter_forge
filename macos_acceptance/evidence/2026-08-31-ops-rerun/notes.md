# macOS 最新产物界面化自测复验

任务：`OPS-20260901-macos-ui-acceptance-rerun`

## 门禁结论

- `PRECHECK artifact_identity=NOT_IN_ARTIFACT`
- `MACOS_GATE=HOLD`
- `windows_ready=false`
- UI 任务结果：`PASS 4 / FAIL 2 / BLOCKED 20 / NOT_IN_ARTIFACT 9`
- 自测清单结果：`PASS 17 / FAIL 2 / BLOCKED 25 / NOT_IN_ARTIFACT 20`

本轮不能进入 Windows 验收。唯一现有 Release bundle 的修改时间为 2026-08-27 17:57:14 CST，早于当前源码 HEAD `ce814fbc249bd3c36ca5ab41151bb29fe70cc980` 的提交时间 2026-08-31 12:57:13 +08:00，且没有产物来源记录证明其包含该提交。

## 已确认结果

- 两次启动 Release 产物均出现主进程并持续存活，首屏完成渲染，窗口标题为 Flutter Forge。
- 首屏真实可见中文分类、模块标题、副标题、难度、概念、预计时长和状态。
- 两次启动均出现 `Invalid engine handle`，M13 / UI-24 为 `FAIL`。
- 两次启动均出现 `Failed to send message to Flutter engine`，M14 / UI-25 为 `FAIL`。
- `Running with merged UI and platform thread. Experimental.` 仅记录运行模式，不作为独立 FAIL。
- 最近一小时未发现 Flutter Forge 崩溃报告，进程日志未匹配 `EXC_BAD_ACCESS` 或 `SIGABRT`；这不覆盖 M13/M14 的失败。

## 交互阻塞

Computer Use 可以读取辅助功能树并保存截图，但对 Flutter Forge 执行 accessibility element 点击或坐标点击时均返回：

```text
Sky Computer Use native pipe closed before response
```

重新连接后主窗口仍停留在原首屏，证明动作没有生效。因此核心导航、三分类多窗口、同类复用、关闭重开、三轮循环和子窗口 file_picker 均逐项标记 `BLOCKED`，未根据静态首屏推断通过。

## 响应式边界

R1-R10、H1-H10 全部为 `NOT_IN_ARTIFACT`。即使旧产物首屏可见，也不能归因于 `ce814fb feat(ui): make debounce throttle demo responsive`。

## 证据

- `MACOS_UI_ACCEPTANCE_REPORT.json`：UI-01 至 UI-35 逐项判定、清单汇总、门禁和 Windows 决策。
- `screenshots/UI-01-main-window.png`：本轮首屏截图。
- `logs/preflight.log`：系统、Flutter、Git、产物路径、bundle mtime、版本和 SHA256。
- `logs/runtime.log`：两次启动 PID 与存活证据。
- `logs/app-console.log`：两次启动的完整终端输出和引擎错误。
- `logs/final-runtime-evidence.log`：错误计数、进程、崩溃报告查询和自动化阻塞。

## 解除 HOLD 条件

1. 提供明确包含当前 HEAD `ce814fb` 或更新提交的 macOS Release 产物，并记录可校验的来源。
2. 修复或解释并消除两项多窗口引擎错误，再复验 M13/M14。
3. 在点击可工作的真实桌面会话完成核心导航、三分类窗口、复用、关闭重开、三轮循环和子窗口 file_picker。
4. 使用最新产物补齐 360dp、600dp、1024dp 的 `debounce_throttle` 截图与操作证据。

本任务未修改源码、产物、CI 或门禁脚本，未 commit，未 push。
