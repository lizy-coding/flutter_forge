# Flutter Forge macOS 真机自测清单

用途：在 macOS 真机上对 Flutter Forge Release 产物执行发布回归、多窗口稳定性验证，以及响应式布局改造后的桌面紧凑窗口验收。

本清单只记录真实执行结果。任何无法执行的项目必须标记 `BLOCKED` 并填写原因，不得根据历史报告或预期结果填写 `PASS`。

## 1. 验收范围

### 本轮必须验证

- macOS Release 产物启动
- 主目录和模块导航
- 在线视频联网播放
- 在线视频断网错误态
- 视频断网连续重试 10 次
- 三个不同分类窗口同时打开
- 分类窗口首帧与无黑屏
- 子窗口文件选择器
- 分类窗口关闭、重开和同分类复用
- 应用控制台 / Console 日志
- macOS 紧凑窗口下的模块布局
- `debounce_throttle` 响应式改造的桌面回归

### 明确延期或不在本轮范围

- Windows USB 原生适配：`usb_detector` 继续 Android-only
- HID / Serial / WinUSB 设备通信
- Android host、Android 真机或模拟器
- 无障碍第二阶段：VoiceOver、读屏、对比度、键盘焦点专项
- 修改源码、修改 Release 产物、修改 CI 或 Release 配置
- `git push`、tag、Release、merge

## 2. 测试基线记录

| 项目 | 记录 |
|---|---|
| 测试执行人 |  |
| 测试日期 |  |
| macOS 版本 |  |
| Mac 型号 |  |
| CPU 架构 | arm64 / x86_64 |
| CPU |  |
| 内存 |  |
| Flutter 版本（如可用） |  |
| 应用版本 |  |
| 应用来源 | GitHub Release / Actions artifact / 本地构建 |
| 产物文件名 | `Flutter Forge.app` 或 `flutter_forge-macos-x64.zip` |
| 产物 SHA256 |  |
| 应用路径 |  |
| 应用进程名/PID |  |
| 测试报告目录 | `macos_acceptance/evidence/<date>/` |
| 总体结论 | PASS / FAIL / BLOCKED |

建议命令：

```bash
shasum -a 256 <path-to-artifact>
sw_vers
uname -m
```

## 3. 证据约定

每个 `PASS` 至少记录操作结果；下列专项必须附截图或日志：

- 三窗口首帧：每个窗口一张截图
- 子窗口文件选择器：打开、取消或选择返回截图
- 关闭重开：关闭前、关闭后、重开后截图
- 视频断网和重试：页面状态截图 + 应用日志
- 紧凑窗口布局：默认窗口、窄窗口、600dp 附近和宽窗口截图
- 崩溃或黑屏：Console / 终端日志、故障模块、异常信息

建议目录：

```text
macos_acceptance/
└── evidence/
    └── YYYY-MM-DD/
        ├── screenshots/
        ├── logs/
        └── notes.md
```

不要把 `.app`、zip、完整日志、`.crash` 文件或临时构建目录提交到仓库；只保留必要的小型证据文件或外部证据路径。

## 4. 前置检查

| ID | 检查项 | 预期 | 结果 | 证据/备注 |
|---|---|---|---|---|
| P1 | Release 产物存在 | 找到指定 `.app` 或 macOS zip |  |  |
| P2 | SHA256 已记录 | 与交付来源记录一致或已说明差异 |  |  |
| P3 | macOS 架构已记录 | arm64 或 x86_64 明确 |  |  |
| P4 | 磁盘空间足够 | 解压和运行无空间错误 |  |  |
| P5 | 测试目录已创建 | 截图和日志有明确路径 |  |  |
| P6 | Flutter 可用性 | 可用则记录版本；不可用只阻塞需要 Flutter CLI 的项目 |  |  |
| P7 | 网络初始状态 | 记录联网/断网测试前状态 |  |  |
| P8 | 既有应用进程已关闭 | 避免旧版本进程干扰 |  |  |
| P9 | 应用来源确认 | 确认不是旧 build 目录或旧安装版本 |  |  |

## 5. 启动与基础运行

| ID | 操作 | 预期结果 | 结果 | 证据/备注 |
|---|---|---|---|---|
| S1 | 双击或命令行启动 Release `.app` | 应用正常启动，无异常退出 |  |  |
| S2 | 检查首屏 | 主窗口出现并完成首帧渲染 |  |  |
| S3 | 检查窗口标题 | 显示 Flutter Forge 或预期应用标题 |  |  |
| S4 | 关闭并重新启动应用 | 可正常再次启动 |  |  |
| S5 | 观察 Console/终端启动日志 | 无启动期致命异常 |  |  |
| S6 | 检查 macOS 应用包 | 主可执行文件和 Flutter framework 存在 |  |  |

启动必须执行两次，并分别回填原始日志，不得合并或仅记录错误摘要：

| 启动轮次 | 产物 SHA256 | PID | 原始日志路径 | 结果 | 证据/备注 |
|---|---|---|---|---|---|
| startup-1 |  |  |  | PASS / FAIL / BLOCKED / NOT_IN_ARTIFACT |  |
| startup-2 |  |  |  | PASS / FAIL / BLOCKED / NOT_IN_ARTIFACT |  |

### 5.1 启动日志专项判定

每次启动至少保存一份原始 Console/终端日志，并将以下两类信息分开记录：

```text
正常环境噪声：例如 merged UI/platform thread 的实验性提示
阻塞性异常：Invalid engine handle、Failed to send message to Flutter engine
```

如果启动日志出现以下任一条，S5 不得判定为 PASS，M13/M14 必须同步执行：

```text
Invalid engine handle
Failed to send message to Flutter engine
```

不要因为应用进程仍存活、主窗口可见或没有 `.crash` 文件，就忽略引擎句柄错误。这类错误可能发生在多窗口生命周期或插件消息发送路径，必须通过三窗口、关闭重开和子窗口插件调用复现或排除。

## 6. 主目录与导航

| ID | 操作 | 预期结果 | 结果 | 证据/备注 |
|---|---|---|---|---|
| N1 | 查看主目录 | 分类、模块标题、副标题、难度和状态可见 |  |  |
| N2 | 浏览全部 macOS 可用模块 | 可用模块可点击进入 |  |  |
| N3 | 查看 USB 模块 | macOS 显示 Android-only 不可用态，不启动 USB 功能 |  |  |
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
| V6 | 检查 Console/终端日志 | 无新增崩溃、未处理异常或资源释放错误 |  |  |

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
| M13 | 检查 Console/终端日志 | 无 `Invalid engine handle` |  |  |
| M14 | 检查 Console/终端日志 | 无 `Failed to send message to Flutter engine` |  |  |
| M15 | 检查 macOS 崩溃报告 | 无 Flutter Forge 相关崩溃报告 |  |  |

### 8.1 多窗口错误的代码维护判定

如果 M13 或 M14 失败，先记录：

1. 错误首次出现的时间和进程 PID。
2. 错误发生前最后一个窗口操作。
3. 是否存在已关闭窗口、重开窗口或子窗口文件选择器操作。
4. `WindowController.getAll()` 可见窗口与应用侧窗口注册表是否一致。
5. Console 原始日志和对应截图。

判定规则：

```text
仅有实验性 merged UI/platform thread 提示：记录为环境/运行模式信息，不单独判 FAIL
出现 Invalid engine handle：代码维护候选，M13 = FAIL
出现 Failed to send message to Flutter engine：代码维护候选，M14 = FAIL
无崩溃报告但引擎错误存在：仍按 FAIL 处理，不改判 PASS
```

本清单不能直接修改源码。确认失败后，应单独创建多窗口生命周期/子 Engine 插件注册修复任务，并在修复后重新执行 M1-M15。

分阶段保存原始日志，避免把启动广播与关闭/重开竞态混为同一问题：

| 阶段 | 起止操作 | 原始日志路径 | 结果 | 证据/备注 |
|---|---|---|---|---|
| stage-startup | 启动前至主窗口首帧 |  | PASS / FAIL / BLOCKED / NOT_IN_ARTIFACT |  |
| stage-three-windows | 打开第一、第二、第三个分类窗口 |  | PASS / FAIL / BLOCKED / NOT_IN_ARTIFACT | 每个窗口分别记录打开时间和截图 |
| stage-close-reopen | 同类复用、关闭、重开三轮 |  | PASS / FAIL / BLOCKED / NOT_IN_ARTIFACT | 每轮分别记录窗口 ID/PID 与截图 |
| stage-child-file-picker | 子窗口打开、取消或选择文件 |  | PASS / FAIL / BLOCKED / NOT_IN_ARTIFACT | 记录插件调用结果 |

## 9. macOS 紧凑窗口响应式布局专项

说明：此部分应使用包含响应式改造的最新 macOS Release 产物。若当前产物不包含最新响应式提交，响应式项目必须标记 `BLOCKED` 或 `NOT_IN_ARTIFACT`，不能把旧产物结果当作新响应式代码的验收结果。

推荐视口：

```text
窄窗口：约 360dp 等效内容宽度
临界窗口：600dp 内容宽度附近
宽窗口：1024dp 或最大化窗口
```

| ID | 操作 | 预期结果 | 结果 | 证据/备注 |
|---|---|---|---|---|
| R1 | 启动包含响应式改造的最新 macOS 产物 | 记录产物版本和 SHA256 |  |  |
| R2 | 打开 `debounce_throttle` 模块并调整到约 360dp | 页面完整渲染，无黄色/黑色 overflow 条；保存包含窗口宽度的首屏截图 |  |  |
| R3 | 在 360dp 下操作三个策略按钮 | 普通/防抖/节流按钮均可见、可点击或自然换行；保存点击后的计数截图 |  |  |
| R4 | 在 360dp 下检查三组计数 | 普通/防抖/节流三组计数不重叠、不裁剪，且点击后数值按预期更新 |  |  |
| R5 | 在 360dp 下打开滚动场景 | 三种位置指标可见，列表可滚动；保存滚动前后截图 |  |  |
| R6 | 在 360dp 下逐卡检查事件可视化 | 依次滚动到普通/防抖/节流三张卡片，每张卡片的左右边框与内容完整可见，右侧卡片无裁剪；保存逐卡或连续滚动证据 |  |  |
| R7 | 调整到 600dp 附近 | 临界宽度不出现布局抖动或溢出 |  |  |
| R8 | 最大化窗口 | 保持清晰的宽屏三路对比布局 |  |  |
| R9 | 检查模块内页面滚动 | 外层教学内容和内部演示滚动均可到达 |  |  |
| R10 | 检查整体应用导航 | 本轮模块内容布局变化未改变分类导航和窗口行为 |  |  |

### 9.1 响应式产物一致性检查

响应式验收前必须同时记录：

```text
当前应用产物的 bundle mtime
当前应用主可执行文件 SHA256
当前源码 HEAD
响应式提交的 commit 时间
```

如果 bundle mtime 早于响应式提交时间，R1-R10 和 H1-H10 必须标记 `NOT_IN_ARTIFACT`，不能将旧产物的界面结果归因到新代码。

如果主窗口可见但 Computer Use 或其他自动化点击没有生效：

```text
可将已真实观察到的首屏项目记为 PASS
未实际点击的项目记为 BLOCKED
不得根据页面静态可见性推断导航、视频、多窗口或响应式项目通过
```

R2-R6 必须使用包含当前响应式修复提交的新构建产物。widget test、旧产物截图或历史 PASS 只能作为辅助信息，不能单独提升 `macOS 响应式布局` 或 `MACOS_GATE`。若新产物身份无法确认，标记 `NOT_IN_ARTIFACT`；若 Computer Use 无法执行点击或滚动，未实际交互的项目标记 `BLOCKED`。

## 10. 其他高风险模块抽查

只对当前产物中已包含的响应式改造执行；未包含的模块标记 `BLOCKED`。

| ID | 模块 | 检查内容 | 结果 | 证据/备注 |
|---|---|---|---|---|
| H1 | `status_management` | 分类卡、badge、流程操作在窄窗口不溢出 |  |  |
| H2 | `gcode_visualizer` | 画布、编辑器、播放控制在窄窗口可达 |  |  |
| H3 | `adsorption_line` | 工具栏换行后画布坐标和拖拽仍正确 |  |  |
| H4 | `popup_widgets` | Dialog、BottomSheet、Overlay 在窄窗口可操作 |  |  |
| H5 | `online_video_player` | 播放控制条和 16:9 画面不溢出 |  |  |
| H6 | `tree_state` | 固定画布、FAB 和子页面无溢出 |  |  |
| H7 | `microtask` | 网格、按钮和代码区域无溢出 |  |  |
| H8 | `stream_subscription` | 广播控制和订阅列表无溢出 |  |  |
| H9 | `font_picker` | 长字体名、预览和控制项不重叠 |  |  |
| H10 | `dio_interceptor` | 登录表单、Dialog 和错误文本可滚动 |  |  |

## 11. 崩溃与黑屏处置

如果出现崩溃、黑屏或窗口永久无响应：

1. 记录最后一个成功操作和精确复现步骤。
2. 截取应用窗口和 Console / 终端日志。
3. 检查 `~/Library/Logs/DiagnosticReports/` 中最新 Flutter Forge 相关报告。
4. 记录以下字段：
   - Process
   - Path
   - Identifier
   - macOS Version
   - Exception Type
   - Crashed Thread
   - 崩溃模块
5. 不重复执行可能造成数据破坏的操作。
6. 将该项标记为 `FAIL`，不要改写成 `BLOCKED`。
7. 不在本验收清单中修改源码；另行创建 FIX 任务。

### 11.1 本次 macOS 记录的后续维护触发条件

已知记录文件：

```text
macos_acceptance/evidence/2026-08-31/notes.md
```

该记录中的 `Invalid engine handle` 与 `Failed to send message to Flutter engine` 不是单纯的点击阻塞或旧产物问题：日志在两次启动中均出现，且错误指向 `mixin.one/desktop_multi_window` 通道。因此应保留为多窗口代码维护候选，不能仅通过补充自测清单关闭。

维护前置条件：

```text
1. 先用包含最新多窗口代码的 macOS Release 产物复现
2. 分别记录主窗口启动、三窗口打开、关闭重开三个阶段的日志
3. 确认错误是否只在旧窗口/失效 Engine 广播时出现
4. 若仍存在，创建独立 FIX 任务修复并补充 Dart/Swift 回归测试
5. 修复后重新执行 M1-M15，不能用无崩溃报告替代引擎错误检查
```

重点异常：

```text
Invalid engine handle
Failed to send message to Flutter engine
EXC_BAD_ACCESS
SIGABRT
```

## 12. 结果汇总

| 分组 | PASS | FAIL | BLOCKED | 备注 |
|---|---:|---:|---:|---|
| 前置 P1-P9 |  |  |  |  |
| 启动 S1-S6 |  |  |  |  |
| 导航 N1-N8 |  |  |  |  |
| 视频 V1-V6 |  |  |  |  |
| 多窗口 M1-M15 |  |  |  |  |
| 响应式 R1-R10 |  |  |  |  |
| 高风险模块 H1-H10 |  |  |  |  |
| 总计 |  |  |  |  |

### 结论规则

```text
PASS：该项已在目标 macOS 真机上执行并有证据
FAIL：真实执行发现错误、崩溃、黑屏、溢出或行为不符合预期
BLOCKED：缺少目标产物、平台、工具或权限，无法执行；必须写明原因
NOT_IN_ARTIFACT：当前产物不包含待验收的最新代码
```

推荐总体结论格式：

```text
macOS 核心功能：PASS / FAIL / BLOCKED
macOS 多窗口稳定性：PASS / FAIL / BLOCKED
macOS 响应式布局：PASS / FAIL / BLOCKED / NOT_IN_ARTIFACT
Windows USB：DEFERRED（Android-only）
Android：DEFERRED
无障碍第二阶段：DEFERRED
MACOS_GATE：PASS / HOLD
windows_ready：true / false
```

`MACOS_GATE` 只有在两次启动、三分类窗口、同类复用、关闭重开三轮、子窗口 file_picker 和全部分阶段原始日志均满足要求时才能填写 `PASS`。`windows_ready` 只有在 `MACOS_GATE=PASS` 后才能填写 `true`；任一 Engine 错误、真实交互 `BLOCKED` 或产物身份不明时必须保持 `MACOS_GATE=HOLD`、`windows_ready=false`。

## 13. 交付回填

- 报告文件：
- 截图目录：
- 日志目录：
- 应用路径：
- 崩溃报告目录：
- 失败项复现说明：
- Windows USB 延期确认：是 / 否
- 多窗口专项是否完成：是 / 否
- 响应式产物是否包含最新代码：是 / 否 / 无法确认
- 执行者签名：

## 14. 安全边界

本清单执行过程中：

```text
不得修改源码
不得修改 Release 产物
不得修改 CI 或门禁脚本
不得修改 Windows USB 平台边界
不得执行 git push
不得创建 tag 或 Release
不得把历史验收结果冒充当前产物结果
```

任何远端推送动作必须获得用户后续单独、明确的批准。
