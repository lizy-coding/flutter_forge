# Windows 端功能补全计划（Phase 2，2026-08-31 收敛版）

> 当前结论：Windows v1.2.2 真机核心功能已通过；USB Windows 适配延期；多窗口稳定性专项待验证；Android 不作为本阶段主方向。

## 验收基线（2026-08-31）
- PASS: Windows 安装包、主界面、模块导航、在线视频、视频断网/重试、吸附线、文件选择器、集成测试及其他核心功能（以 Windows 真机结果为准）
- DEFERRED: Windows USB；当前 `usb_detector` 保持 Android-only，Windows 显示平台不可用态
- PENDING: Windows/macOS 多窗口稳定性专项（3 个不同分类窗口、子窗口文件选择、关闭重开、引擎错误日志）
- DEFERRED: Android host、Android 真机/模拟器验收，不阻塞本阶段 PC 工作

## 路线（当前阶段）

| 任务 | 内容 | 依赖 | 产出/验收 |
|------|------|------|-----------|
| **W0 测试链路** | 已完成：integration_test 按运行平台选择模块 | 无 | Windows 集成测试链路可执行 |
| **W1 文件选择器** | 已完成：Windows 使用官方 `file_selector` 适配；模块标注 `{macOS, windows}` | W0 | Windows 系统文件对话框打开/取消/选择返回 |
| **W2 USB 识别** | 本阶段延期：保留 Android 通道，Windows 不实现原生插件 | - | Windows 显示 Android-only 不可用态 |
| **W3 设备通信** | 延期：等待明确设备类型与通信协议 | W2 | 不阻塞本阶段 |
| **W4 稳定性** | 核心 Windows 真机已通过；视频专项保留为发布回归项 | 无 | 断网/重试不崩溃 |
| **W5 多窗口闭环** | 下一轮专项：macOS + Windows 三分类窗口、子窗口文件选择、关闭重开、日志检查 | W1 | 多窗口稳定性证据完整 |

## 当前执行顺序
多窗口稳定性验证 → 结果归档与发布基线更新 → 存量质量/测试债务 → 新学习模块。

Android、Windows USB 和设备通信均保留为后续阶段，不阻塞本阶段的新模块规划；但多窗口专项必须先取得真实窗口证据。

## 约束
- 平台判定继续走 module_catalog_utils(isModuleAvailable), 模块页不直接调 Platform API
- 新增原生通道须与既有模式一致(method_channel 风格), 遵守 AGENTS.md 平台可用性规则
- 多窗口任务：macOS/Windows 真实窗口证据；环境不可用时逐项标记 `BLOCKED`，不得虚构 `PASS`
- 代码任务仍需 `quality_gate` 6/6；纯验收任务不得修改源码、产物或门禁脚本
- 仅本地 commit, 推送须批准
