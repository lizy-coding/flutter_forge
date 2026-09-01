# Flutter Forge Windows 真机自测清单

用途：在 Windows x64 真机上对 Flutter Forge 安装包执行发布回归、多窗口稳定性验证，以及响应式布局改造后的桌面紧凑窗口验收。

本清单只记录真实执行结果。任何无法执行的项目必须标记 `BLOCKED` 并填写原因，不得根据历史报告或预期结果填写 `PASS`。

## 1. 验收范围

### 本轮必须验证

- Windows 安装包安装、启动和卸载入口
- 主目录和模块导航
- 在线视频联网播放
- 在线视频断网错误态
- 视频断网连续重试 10 次
- 三个不同分类窗口同时打开
- 分类窗口首帧与无黑屏
- 子窗口文件选择器
- 分类窗口关闭、重开和同分类复用
- Windows Event Viewer / 应用日志
- Windows 紧凑窗口下的模块布局
- `debounce_throttle` 响应式改造的桌面回归

### 明确延期或不在本轮范围

- Windows USB 原生适配：`usb_detector` 继续 Android-only
- HID / Serial / WinUSB 设备通信
- Android host、Android 真机或模拟器
- 无障碍第二阶段：Semantics、读屏、对比度、键盘焦点专项
- 修改源码、修改安装包、修改 CI 或 Release 配置
- `git push`、tag、Release、merge

## 2. 测试基线记录

| 项目 | 记录 |
|---|---|
| 测试执行人 |  |
| 测试日期 |  |
| Windows 版本 |  |
| Windows 架构 | x64 / other |
| CPU |  |
| 内存 |  |
| Flutter 版本（如可用） |  |
| 应用版本 |  |
| 应用来源 | GitHub Release / Actions artifact / 本地构建 |
| 安装包文件名 | `flutter_forge-setup-x64.exe` |
| 安装包 SHA256 |  |
| 安装路径 |  |
| 应用进程名/PID |  |
| 测试报告目录 | `windows_acceptance/evidence/<date>/` |
| 总体结论 | PASS / FAIL / BLOCKED |

建议 Windows SHA256 命令：

```powershell
Get-FileHash .\flutter_forge-setup-x64.exe -Algorithm SHA256
```

## 3. 证据约定

每个 `PASS` 至少记录操作结果；下列专项必须附截图或日志：

- 三窗口首帧：每个窗口一张截图
- 子窗口文件选择器：打开、取消或选择返回截图
- 关闭重开：关闭前、关闭后、重开后截图
- 视频断网和重试：页面状态截图 + 应用日志
- 紧凑窗口布局：默认窗口、窄窗口、最大化窗口截图
- 崩溃或黑屏：Windows Event Viewer 事件详情、故障模块、异常代码、WER bucket

建议目录：

```text
windows_acceptance/
└── evidence/
    └── YYYY-MM-DD/
        ├── screenshots/
        ├── logs/
        └── notes.md
```

不要把安装包、`.dmp`、完整日志或临时解压目录提交到仓库；只保留必要的小型证据文件或外部证据路径。

## 4. 前置检查

| ID | 检查项 | 预期 | 结果 | 证据/备注 |
|---|---|---|---|---|
| P1 | 安装包存在 | 找到指定 `setup.exe` |  |  |
| P2 | SHA256 已记录 | 与交付来源记录一致或已说明差异 |  |  |
| P3 | Windows 为 x64 | 目标架构匹配 |  |  |
| P4 | 磁盘空间足够 | 安装和运行无空间错误 |  |  |
| P5 | 测试目录已创建 | 截图和日志有明确路径 |  |  |
| P6 | Flutter 可用性 | 可用则记录版本；不可用只阻塞集成测试项 |  |  |
| P7 | 网络初始状态 | 记录联网/断网测试前状态 |  |  |
| P8 | 既有应用进程已关闭 | 避免旧版本进程干扰 |  |  |

## 5. 安装与启动

| ID | 操作 | 预期结果 | 结果 | 证据/备注 |
|---|---|---|---|---|
| W1 | 运行 `flutter_forge-setup-x64.exe` | 安装程序正常打开，无异常退出 |  |  |
| W2 | 使用默认或指定非管理员路径完成安装 | 安装成功，不要求不必要的管理员权限 |  |  |
| W3 | 从开始菜单启动 Flutter Forge | 主窗口出现并完成首帧渲染 |  |  |
| W4 | 检查安装目录关键文件 | exe、`flutter_windows.dll`、data 目录和插件 DLL 存在 |  |  |
| W5 | 打开系统卸载入口 | 存在 Flutter Forge 卸载条目 |  |  |
| W6 | 关闭并重新启动应用 | 可正常再次启动 |  |  |

## 6. 主目录与导航

| ID | 操作 | 预期结果 | 结果 | 证据/备注 |
|---|---|---|---|---|
| N1 | 查看主目录 | 分类、模块标题、副标题、难度和状态可见 |  |  |
| N2 | 浏览全部可用模块 | 可用模块可点击进入 |  |  |
| N3 | 查看 USB 模块 | Windows 显示 Android-only 不可用态，不启动 Windows USB 功能 |  |  |
| N4 | 打开并返回基础机制模块 | 页面打开、返回后主窗口正常 |  |  |
| N5 | 打开并返回状态管理模块 | 页面打开、返回后主窗口正常 |  |  |
| N6 | 打开并返回网络与平台模块 | 页面打开、返回后主窗口正常 |  |  |
| N7 | 打开“弹窗与列表交互” | 不出现 Page Not Found 或 GoException |  |  |
| N8 | 从模块页面返回主目录 | 返回链路正确，无空白页 |  |  |

## 7. 视频专项

每项独立判定。失败不能阻塞后续项。

| ID | 操作 | 预期结果 | 结果 | 证据/备注 |
|---|---|---|---|---|
| V1 | 联网打开在线视频模块 | 页面正常打开，视频进入可播放或明确加载态 |  |  |
| V2 | 播放并等待至少 10 秒 | 播放位置推进，应用不崩溃 |  |  |
| V3 | 断开网络后重新打开视频 | 在合理等待时间内显示错误占位或重试入口，不崩溃 |  |  |
| V4 | 断网状态连续点击重试 10 次，间隔约 2 秒 | 不崩溃、不出现重复窗口或明显重复控制器 |  |  |
| V5 | 恢复网络后点击重试 | 可以恢复播放，或显示明确可解释的失败状态 |  |  |
| V6 | 检查应用日志和事件查看器 | 无新增 `0xc0000005`、`0xc000041d` 或相关崩溃事件 |  |  |

## 8. 多窗口稳定性专项

必须使用三个不同分类：

```text
基础机制
状态管理
网络与平台
```

同一分类重复打开属于复用测试，不可替代三窗口测试。

| ID | 操作 | 预期结果 | 结果 | 证据/备注 |
|---|---|---|---|---|
| M1 | 从主窗口打开“基础机制”分类窗口 | 分类窗口出现且首帧正常 |  |  |
| M2 | 从主窗口打开“状态管理”分类窗口 | 分类窗口出现且首帧正常 |  |  |
| M3 | 从主窗口打开“网络与平台”分类窗口 | 分类窗口出现且首帧正常 |  |  |
| M4 | 同时观察三个窗口 | 三窗内容对应正确分类，无黑屏 |  |  |
| M5 | 在一个子窗口打开 file_picker 模块 | 系统文件选择器正常打开 |  |  |
| M6 | 在文件选择器中取消 | 子窗口正常返回，不崩溃 |  |  |
| M7 | 在文件选择器中选择文件（如测试条件允许） | 返回路径或结果正常显示 |  |  |
| M8 | 重复点击已经打开的同一分类 | 复用既有窗口，不产生异常重复窗口 |  |  |
| M9 | 关闭一个分类窗口 | 目标窗口关闭，其他窗口和主窗口存活 |  |  |
| M10 | 关闭剩余分类窗口 | 所有分类窗口关闭，主窗口存活 |  |  |
| M11 | 重新打开已关闭分类 | 可重新创建或复用，首帧正常 |  |  |
| M12 | 连续执行打开/关闭/重开循环至少 3 次 | 无黑屏、无主窗口退出、无明显窗口注册残留 |  |  |
| M13 | 检查应用控制台或日志 | 无 `Invalid engine handle` |  |  |
| M14 | 检查应用控制台或日志 | 无 `Failed to send message to Flutter engine` |  |  |
| M15 | 检查 Windows Event Viewer | 无 Flutter Forge 相关崩溃事件 |  |  |
| M16 | 连续快速打开/关闭三个分类窗口 3 轮 | 子窗口首帧正常显示，无黑屏、无 `Invalid engine handle`、无 `Failed to send message to Flutter engine` |  |  |
| M17 | 检查主窗口关闭行为 | 关闭最后一个子窗口后主窗口仍存活（`applicationShouldTerminateAfterLastWindowClosed=false` 语义在 Windows 等价行为） |  |  |

## 9. Windows 紧凑窗口响应式布局专项

说明：此部分应使用包含响应式改造的最新 Windows Release 产物。若当前安装包仍为 v1.2.2、未包含本地响应式提交，则记录 `BLOCKED`，不要把旧产物结果当作响应式改造结果。

本轮预期产物（2026-09-01 起）：由 `release.yml` workflow_dispatch 基于 dev 最新提交构建的 `flutter_forge-setup-x64.exe`。交付时须记录：

```text
run_id、head_sha（= dev 远端 HEAD）、setup.exe SHA256、构建时间
```

产物必须包含以下已提交源码才算有效基线：

```text
5ef5a81  fix(ui): repair compact layouts for issue 18
92bb625  fix(multiwindow): add lifecycle diagnostics
（本轮窗口时序修复提交：hiddenAtLaunch=false + mac_window.dart 后端协议）
```

用 `gh run view <run_id> --json headSha` 核对 headSha 与远端 HEAD 一致；SHA256 与 artifact 下载值一致。

推荐视口：

```text
窄窗口：约 360dp 等效内容宽度
临界窗口：600dp 内容宽度附近
宽窗口：1024dp 或最大化窗口
```

| ID | 操作 | 预期结果 | 结果 | 证据/备注 |
|---|---|---|---|---|
| R1 | 启动包含响应式改造的最新 Windows 产物 | 记录产物版本和 SHA256 |  |  |
| R2 | 打开 `debounce_throttle` 模块 | 页面完整渲染，无黄色/黑色 overflow 条 |  |  |
| R3 | 将窗口调整到窄宽度 | 三个策略按钮可见、可操作或自然换行 |  |  |
| R4 | 检查三组计数 | 普通/防抖/节流三组计数不重叠、不裁剪 |  |  |
| R5 | 打开滚动场景 | 三种位置指标可见，列表可滚动 |  |  |
| R6 | 检查窄屏事件可视化 | 内容可通过模块内滚动到达，不发生页面崩溃 |  |  |
| R7 | 调整到 600dp 附近 | 临界宽度不出现布局抖动或溢出 |  |  |
| R8 | 最大化窗口 | 保持清晰的宽屏三路对比布局 |  |  |
| R9 | 重复打开其他已改造模块 | 仅对已包含在当前产物中的模块进行验证；未包含模块标记 BLOCKED |  |  |
| R10 | 检查整体应用导航 | 本轮模块内容布局变化未改变分类导航和窗口行为 |  |  |
| R11 | 打开 `adsorption_line` 模块并将窗口调窄到 360dp | 工具栏按钮自动换行（Wrap），无水平溢出、无 RenderFlex overflow |  |  |
| R12 | 打开 `microtask` / `isolate_basic` 模块并将窗口调窄到 360dp | 单列布局或模块内滚动可达，无 RenderFlex overflow |  |  |
| R13 | 在 360dp 下打开 `debounce_throttle` 三个策略按钮 | 按钮可见、可操作或自然换行，无溢出 |  |  |

## 10. 崩溃与黑屏处置

如果出现崩溃、黑屏或窗口永久无响应：

1. 记录最后一个成功操作和精确复现步骤。
2. 截取应用窗口和 Windows Event Viewer 事件详情。
3. 记录以下字段：
   - Faulting application name
   - Faulting module name
   - Exception code
   - Fault offset
   - WER bucket
   - 进程路径
4. 不重复执行可能造成数据破坏的操作。
5. 将该项标记为 `FAIL`，不要改写成 `BLOCKED`。
6. 不在本验收清单中修改源码；另行创建 FIX 任务。

重点异常：

```text
0xc0000005
0xc000041d
Invalid engine handle
Failed to send message to Flutter engine
```

## 11. 结果汇总

| 分组 | PASS | FAIL | BLOCKED | 备注 |
|---|---:|---:|---:|---|
| 前置 P1-P8 |  |  |  |  |
| 安装 W1-W6 |  |  |  |  |
| 导航 N1-N8 |  |  |  |  |
| 视频 V1-V6 |  |  |  |  |
| 多窗口 M1-M17 |  |  |  |  |
| 响应式 R1-R13 |  |  |  |  |
| 总计 |  |  |  |  |

### 结论规则

```text
PASS：该项已在目标 Windows 真机上执行并有证据
FAIL：真实执行发现错误、崩溃、黑屏、溢出或行为不符合预期
BLOCKED：缺少目标产物、平台、工具或权限，无法执行；必须写明原因
```

推荐总体结论格式：

```text
Windows 核心功能：PASS / FAIL / BLOCKED
Windows 多窗口稳定性：PASS / FAIL / BLOCKED
Windows 响应式布局：PASS / FAIL / BLOCKED / NOT_IN_ARTIFACT
Windows USB：DEFERRED（Android-only）
Android：DEFERRED
无障碍第二阶段：DEFERRED
```

## 12. 交付回填

- 报告文件：
- 截图目录：
- 日志目录：
- 安装路径：
- Event Viewer 导出：
- 失败项复现说明：
- Windows USB 延期确认：是 / 否
- 多窗口专项是否完成：是 / 否
- 响应式产物是否包含最新代码：是 / 否 / 无法确认
- 执行者签名：

## 13. 安全边界

本清单执行过程中：

```text
不得修改源码
不得修改 Release 产物
不得修改 CI 或门禁脚本
不得修改 Windows USB 平台边界
不得执行 git push
不得创建 tag 或 Release
```

任何远端推送动作必须获得用户后续单独、明确的批准。
