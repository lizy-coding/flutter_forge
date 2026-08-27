# Windows 实机测试清单（待执行）

任务：REL-20260827-windows-testable-packaging  
基线提交：`aa200fa`  运行环境：Windows x64  
状态：待用户批准推送并触发 GitHub Actions Release 构建

## 产物记录

| 项目 | 记录 |
| --- | --- |
| Release workflow run ID | 待批准后触发 |
| 便携包 | `flutter_forge-windows-x64.zip`，待下载 |
| 安装包 | `flutter_forge-setup-x64.exe`，待下载 |
| ZIP SHA256 | 待下载后填写 |
| setup.exe SHA256 | 待下载后填写 |

## 测试前置

- [ ] 下载两个构建产物并记录 SHA256。
- [ ] 任选一种方式启动：运行 `flutter_forge-setup-x64.exe` 安装，或解压 ZIP 后运行 `flutter_forge.exe`。
- [ ] 记录 Windows 版本、CPU 架构、Flutter 版本和测试日期。

## 功能与稳定性

| 编号 | 场景与步骤 | 预期结果 | PASS/FAIL | 备注/日志 |
| --- | --- | --- | --- | --- |
| 1 | 便携 ZIP：解压并运行 `flutter_forge.exe` | 应用正常启动并显示主目录 |  |  |
| 2 | 安装包：运行 setup.exe，安装后从开始菜单启动 | 安装、启动和卸载入口可用 |  |  |
| 3 | 在线视频：联网打开视频并播放 | 正常播放，页面无溢出或崩溃 |  |  |
| 4 | 在线视频：断网后打开或播放 | 显示错误占位，不崩溃 |  |  |
| 5 | 在线视频：连续点击重试 10 次 | 不崩溃、不出现重复控制器或异常窗口 |  |  |
| 6 | 多窗口：连续打开 3 个分类窗口 | 三个窗口均可见，无黑屏 |  |  |
| 7 | 多窗口：观察应用/子窗口日志 | 无 `Invalid engine handle` |  |  |
| 8 | 多窗口：在子窗口打开文件选择器 | 文件选择器可用，选择或取消后可返回 |  |  |
| 9 | 多窗口：关闭分类窗口后再次打开 | 可关闭、无残留，再开可正常复用/创建 |  |  |
| 10 | USB 模块：打开模块目录和页面 | Windows 按平台标注显示可用态；若明确限制则显示清晰不可用态 |  |  |
| 11 | 集成测试：在有 Flutter/桌面设备环境执行 `flutter test integration_test -d windows` | 测试命令通过 |  |  |

## 结果签收

- 测试执行人：
- 测试机器：
- 执行日期：
- 总体结论：PASS / FAIL / BLOCKED
- 失败项及复现步骤：
- 附件（截图、日志、安装路径）：
