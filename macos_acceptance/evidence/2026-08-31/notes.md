# Flutter Forge macOS 界面化验收记录

## 结论

- 总体结论：`FAIL`
- 已执行：`PASS 17`、`FAIL 2`
- 未执行：`BLOCKED 35`、`NOT_IN_ARTIFACT 10`
- 失败原因：Release 产物每次启动均出现 `Invalid engine handle` 和 `Failed to send message to Flutter engine`，不满足 M13、M14。
- 阻塞原因：Computer Use 可以读取和截图窗口，但对 Flutter Forge 执行任意点击时原生管道关闭，动作未生效；因此未把未真实操作的项目判为 PASS。
- 响应式产物边界：Release bundle 修改时间为 2026-08-27 17:57:14 CST，当前响应式提交 `ce814fbc249bd3c36ca5ab41151bb29fe70cc980` 的提交时间为 2026-08-31 12:57:13 +08:00。R1-R10 全部判为 `NOT_IN_ARTIFACT`。

## 测试基线

| 项目 | 记录 |
|---|---|
| 测试执行人 | Codex Computer Use |
| 测试日期 | 2026-08-31 |
| macOS 版本 | 26.5 (25F71) |
| Mac 型号 / CPU | Apple M5 |
| CPU 架构 | arm64 |
| 内存 | 24 GiB |
| Flutter 版本 | 3.44.6 stable；Dart 3.12.2 |
| 应用版本 | 1.2.0 (1.2.0) |
| 应用来源 | 本地 Release build |
| 应用路径 | `apps/flutter_forge/build/macos/Build/Products/Release/Flutter Forge.app` |
| 主可执行文件 SHA256 | `35022d7fa3d01811a00747c987dd3a1cb3068a1995bc2bdddb950399414db80d` |
| Bundle ID | `com.flutterforge.preview` |
| 网络初始状态 | `en0` 存在默认路由；样例视频 Range 探测返回 HTTP 403，未据此判定视频播放结果 |

## 执行结果

| 分组 | PASS | FAIL | BLOCKED | NOT_IN_ARTIFACT | 说明 |
|---|---:|---:|---:|---:|---|
| P1-P9 | 9 | 0 | 0 | 0 | 产物、SHA、架构、磁盘、目录、Flutter、网络、旧进程和来源均已记录 |
| S1-S6 | 6 | 0 | 0 | 0 | Release 启动、首帧、标题、重启、进程存活、bundle 结构通过；启动日志异常计入 M13/M14 |
| N1-N8 | 1 | 0 | 7 | 0 | N1 首屏分类、模块标题、副标题、难度和状态可见；点击操作受阻 |
| V1-V6 | 0 | 0 | 6 | 0 | 无法进入在线视频模块，也未修改系统网络状态 |
| M1-M15 | 1 | 2 | 12 | 0 | M13/M14 失败；M15 未发现本轮崩溃报告；其余多窗口操作受阻 |
| R1-R10 | 0 | 0 | 0 | 10 | 当前 Release 产物早于响应式提交 |
| H1-H10 | 0 | 0 | 10 | 0 | 无法进入模块进行窄窗口操作 |
| 总计 | 17 | 2 | 35 | 10 | 总体 FAIL |

## 关键证据

- `screenshots/S2-main-window.png`：主窗口首帧，窗口标题为 Flutter Forge，主目录完整显示基础机制、异步并发、状态管理等分类；可见模块中文标题、副标题、难度、概念、预计时长和状态。
- `logs/baseline.txt`：系统、Flutter、应用版本、Bundle ID、SHA256 和启动 PID。
- `logs/app-console.log`：两次启动均出现多窗口引擎句柄错误；应用进程随后仍存活。
- `logs/runtime-checks.txt`：网络路由、重启 PID、崩溃报告查询、产物与当前提交时间边界。

## 复现与后续验收条件

1. 使用包含 `ce814fbc249bd3c36ca5ab41151bb29fe70cc980` 或更新提交的 macOS Release 重新构建产物。
2. 启动产物并观察控制台；若仍出现 `Invalid engine handle` 或 `Failed to send message to Flutter engine`，M13/M14 保持 FAIL，并另建修复任务。
3. 由可正常向 Flutter 窗口注入点击的人工桌面会话执行 N2-N8、V1-V6、M1-M12、R1-R10、H1-H10；本轮自动化工具的点击动作没有生效。
4. 多窗口首帧、关闭重开、file_picker、断网重试和 360/600/1024dp 布局必须补齐截图或日志后才能改判 PASS。
