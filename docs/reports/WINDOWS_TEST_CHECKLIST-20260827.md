# Windows 实机测试清单

任务：REL-20260827-windows-testable-packaging（后续修订：USB 延期 + 多窗口专项）
基线提交：`v1.2.2`（= 200ad0c，2026-08-29 发布）  
运行环境：Windows x64  
状态：**Windows v1.2.2 核心真机验证通过**；多窗口稳定性专项待验证；Windows USB 延期

## 产物记录

| 项目 | 记录 |
| --- | --- |
| GitHub Release | [Flutter Forge v1.2.2](https://github.com/lizy-coding/flutter_forge/releases/tag/v1.2.2)（Latest，2026-08-29） |
| Release workflow run ID | 33231849904（tag push 自动触发，200ad0c，success） |
| 安装包 | `flutter_forge-setup-x64.exe`（12,020,767 bytes，仅此一个 Windows 产物，无 zip） |
| setup.exe SHA256 | `7d3444037e18cffb0595c2e4ac5594ad55db78a82ae02f160a9039435dd0aa21` |
| macOS 产物 | `flutter_forge-macos-x64.zip`（20,611,365 bytes，SHA256 `8a3bdc70189fc138a1e92c51f6461e9439e09885dfe3c056b588f0a5dac8f3d6`） |
| 便携包 | 已取消（2026-08-29 起 Windows 仅发布 setup.exe，不再产 zip；macOS 保留 zip） |
| 历史版本 | v1.2.1（2026-08-23，含 zip 旧形态）保留；1.0.0 空 release 已删除 |

## 测试前置

- [x] 下载构建产物并记录 SHA256（见上表）。
- [x] 运行 `flutter_forge-setup-x64.exe` 安装，从开始菜单启动应用。
- [x] Windows 核心功能真机验证通过（安装、导航、视频、断网重试、文件选择器、集成测试等，以执行记录为准）。
- [ ] 补充测试机器、执行日期和完整证据路径。

## 功能与稳定性

| 编号 | 场景与步骤 | 预期结果 | PASS/FAIL | 备注/日志 |
| --- | --- | --- | --- | --- |
| 1 | 安装包：运行 setup.exe，安装后从开始菜单启动 | PASS：安装、启动和卸载入口可用 | PASS | Windows 真机已通过 |
| 2 | 在线视频：联网打开视频并播放 | PASS：正常播放，页面无溢出或崩溃 | PASS | Windows 真机已通过 |
| 3 | 在线视频：断网后打开或播放 | PASS：显示错误占位，不崩溃 | PASS | Windows 真机已通过 |
| 4 | 在线视频：连续点击重试 10 次 | PASS：不崩溃、不出现重复控制器或异常窗口 | PASS | Windows 真机已通过 |
| 5 | 多窗口：连续打开 3 个分类窗口 | 三个窗口均可见，无黑屏 | PENDING | 下一轮多窗口专项 |
| 6 | 多窗口：观察应用/子窗口日志 | 无 `Invalid engine handle` | PENDING | 下一轮多窗口专项 |
| 7 | 多窗口：在子窗口打开文件选择器 | 文件选择器可用，选择或取消后可返回 | PENDING | 下一轮多窗口专项 |
| 8 | 多窗口：关闭分类窗口后再次打开 | 可关闭、无残留，再开可正常复用/创建 | PENDING | 下一轮多窗口专项 |
| 9 | USB 模块：打开模块目录 | Windows 显示不可用态（Android-only，原生插件已移除） | DEFERRED | Windows USB 不在本阶段适配 |
| 10 | 集成测试：在有 Flutter/桌面设备环境执行 `flutter test integration_test -d windows` | 测试命令通过 | PASS | Windows 真机已通过 |
| 11 | 文件选择器：打开 file_picker 模块 | 系统文件对话框打开/取消/选择返回 | PASS | Windows 真机已通过 |

## 结果签收

- 测试执行人：
- 测试机器：
- 执行日期：
- 总体结论：核心功能 PASS；多窗口 PENDING；Windows USB DEFERRED
- 失败项及复现步骤：
- 附件（截图、日志、安装路径）：
