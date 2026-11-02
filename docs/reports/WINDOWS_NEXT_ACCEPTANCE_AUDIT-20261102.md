# Windows 下一轮验收准备审查

本地基线 HEAD 为 `51fbab7`。按用户最新要求，仅本地修改和验证；本审查不授权提交、推送或触发远端任务。历史成功或当前构建不代表原问题关闭。

## 要求与当前证据

| 要求 | 当前证据 | 结论及下一步 |
| --- | --- | --- |
| 普通用户 EXE 交付 | Inno lowest、用户目录；51fbab7 使用已验证 payload 和 app-local CRT，独立 installer hash/runtime_files | 配置已实现；安装器生成及非提权真实安装、升级、卸载、重装仍需验证 |
| 自测不依赖 MSIX 信任 | user-exe 默认、HKCU 固定 AppId、版本/EXE/CRT hash；本地工具 25 项 fixture 通过 | 本地实现通过定向验证；Windows 注册表和实际安装必须实测 |
| 无管理员自测 | 本地 venv；user-exe 记录当前令牌，提权运行 BLOCKED | 当前令牌不是账户全部权限的证明；标准账户仍需记录环境 |
| FF-AUTO-02 分类定位 | 精确或有界重复标签，歧义阻塞；UIA fixture 与先前 Windows adapter 步骤通过 | 原设备 main_with_child/reopen/reuse 的实际 UIA 执行待复核 |
| FF-AUTO-03 批处理启动 | bat/cmd 专用派发，关闭 AutoRun/延迟扩展；Windows adapter 中真实临时 CMD 回归通过 | WinError 193 路径已增加回归；真实安装 SDK 后的原 source smoke 仍按实际测试事件记录；引号/百分号等参数明确不支持，不称通用批处理兼容 |
| FF-WIN-01 标题栏 | caption-clicks.jsonl 记录 DPI、坐标、命中和状态；41ae772 Windows 构建成功 | 根因及 125% 还原/最小化故障尚未解决；必须取得原环境的同次点击证据，不能用日志采集代替修复 |
| 焦点/F11 | 41ae772 激活且未最小化才转交焦点，Windows 编译通过 | 原失败焦点条件的实际 F11 往返仍待确认 |
| 中文输入 | 组合期间阻止应用导航/关闭；桌面工作台 17 项测试通过；41ae772 云端通过 | Windows 真实 IME 和外部 Unicode 注入分别实测，不互相代替 |
| 完整验收报告 | 未提交 v2：安装4项、B01–B07、最小化、F11、IME、100%/125%必须填证据；工具执行/导出 hash | 自动检查只证明所执行范围；人工缺项不能整体 PASS；不可改 target 跳过安装项 |
| 可转交证据 | 本地补充包 KIT_MANIFEST、执行/导出工具 hash、源报告副本、专用结果 ZIP | 补充包不含应用、不上传；使用前核对与候选 metadata 的兼容要求 |
| 远端候选 | 41ae772 run 41410146319 已成功；51fbab7 run 41411538546 构建、Windows 工具回归及宿主 smoke 已成功 | 51fbab7 包已下载核验来源、EXE/MSIX/证书哈希、app-local DLL 与 smoke 实际执行 1 项；本地 v2 工具尚未进入远端包 |

来源：[Issue #36 与两设备交接](https://github.com/lizy-coding/flutter_forge/issues/36#issuecomment-6571479491)、[41ae772 Windows run](https://github.com/lizy-coding/flutter_forge/actions/runs/41410146319)、[51fbab7 Windows run](https://github.com/lizy-coding/flutter_forge/actions/runs/41411538546)。Windows 10 与 Windows 11/RDP 的观测范围分别保留，解包 EXE 不算安装/开始菜单通过。

## 当前本地验证

`/private/tmp/forge-local-acceptance-v2-tools/result.json`：manager/UIA/self-test 专项 PASS；最新自测 25 项见 `/private/tmp/forge-local-final-selftest.log`。v2 基础完整门禁 `/private/tmp/forge-local-v2-quality.log` 通过；后续最小化必填与工具指纹增补后另执行最终门禁，未以先前结果宣称整个最终工作区已验证。

## 下一轮实际执行

1. 核对指定候选源码、包 hash、实际 EXE/运行库与原始报告，不混用同版本不同产物。
2. 普通用户执行 EXE 安装闭环与默认 user-exe 自测；需要时使用本地补充工具，但应用来源与工具 hash 分别记录。
3. 原失败 Windows 11 125%/活动 RDP 环境优先复核主/分类窗口还原、最小化；回传 caption-clicks.jsonl、窗口状态、画面和完整错误。
4. Win10 截图/窗口发现、外部 CU-04 索引错误单独复核；不能用另一设备、UIA 或坐标绕行结果关闭原接口问题。
5. 核对 F11 焦点、中文 IME、B01–B07、DPI 和安装4项。缺环境或旧包保持 BLOCKED/NOT_RUN，不通过改模板得到 PASS。

当前完整目标未达成：Windows 实际安装及原失败交互证据仍缺；新的本地修改也未提交。只有许可后的交付和实际证据齐全，才能逐项评估关闭；当前不能认定阶段一至三全部完成。


## 已下载产物核验补充

run 41411538546 的候选 artifact 为 13126557119；来源 51fbab79cf144aa4ad1c68db85eaf630b872d1f5，应用 1.2.13+8 / MSIX 1.2.13.0。用户 EXE 文件为 FlutterForge-1.2.13-windows-x64-user-setup.exe，SHA256 `820b0740dbc91ba55e508a39fe578327b0af6cd3ebcd573421182a62c6804f84`，未签名。三个 app-local VC DLL hash 与签名 MSIX 的对应文件一致。原候选包含 START_HERE、PS1、来源 JSON 与 recheck-tools。以上为下载/构建证据，不是实际安装、升级、卸载或交互通过。

本地 v2 最终完整门禁 `/private/tmp/forge-local-acceptance-audit-quality.log` 五阶段通过；25 项 self-test fixture 通过。`/private/tmp/forge-local-selftest-v2-kit.zip` 工具 hash 与当前工作区一致，包含未提交修改；未上传。下一步需要 Windows 原失败环境的真实点击、状态和安装闭环证据，不能在 macOS 通过继续增加 fixture 认定这些项目解决。

## 用户后续明确的本地通用 Dart/Flutter 工作方式

用户确认当前没有 Windows 会话或新现场结果，要求“这里按照 dart 开发通用”。因此继续以共享应用层、逻辑键盘事件、输入法组合状态、导航与自适应布局的本地验证推进；原生安装/按钮行为仍按原范围待验收，不将其冒充 Flutter Widget 结果，也不再把取得 Windows 会话作为本地通用改动前置。用户未重新授权提交、推送或触发构建。

本地复现并修正：

- 主键盘与小键盘 Enter 的结果打开行为一致，并共同受组合输入保护。当前 SDK 的旧 Windows raw-event 模拟映射不支持 Numpad Enter，测试通过其支持的 Linux 编码驱动同一 Flutter 逻辑键事件；桌面变体仅模拟外壳/主题，不能称 Windows 原生键盘验收。
- 快速打开原固定 64 高度的结果行在两倍字体下分类文字超出行边界。结果行高度按文字缩放增长，键盘滚动偏移复用该高度；回归断言标题/分类不重叠且不超出行边界。
- F11 原绑定在页面外壳，快速打开的 Navigator 弹窗聚焦时不能发出窗口命令。现统一在每窗口 DesktopWindowHost 处理，普通页面/弹窗/关闭弹窗后各只派发一次；非桌面不绑定。该项是 Flutter 命令派发验证，不证明系统实际全屏。

桌面工作台、结果行可读性、窗口配置合计 26 项定向测试通过，日志 `/private/tmp/forge-generic-window-shortcuts.log`。前一批通用键盘/大字体完整门禁已通过（`/private/tmp/forge-generic-dart-quality.log`）；F11 宿主层调整后另执行完整门禁，按最新日志判断最终状态。

F11 长按测试进一步复现重复事件导致两次窗口切换命令；宿主快捷键增加 includeRepeats=false，仅一次按下触发一次，后续独立按下仍可触发。普通页面/弹窗/返回后和输入布局等 26 项回归通过（`/private/tmp/forge-f11-repeat-green.log`）。前一批宿主调整完整门禁通过，长按修正后冻结改动并另执行最终门禁，等待最终日志后再记录结论。

## Cupertino 图标资源缺口

本地 Web Release 曾提示缺少 packages/cupertino_icons/CupertinoIcons，FontManifest 仅包含 MaterialIcons/Roboto，应用未声明 cupertino_icons。按当前 Flutter SDK CupertinoIcons 文档补充资源依赖 ^1.0.9；[官方 1.0.9 说明](https://pub.dev/packages/cupertino_icons/versions/1.0.9)与[变更记录](https://pub.dev/packages/cupertino_icons/changelog)用于核对兼容范围，没有迁移 2.x API。pub get 仅新增 cupertino_icons 1.0.9；生成契约 74 项无漂移，69 项文档校验通过。

新本地 Web 构建 `/private/tmp/forge-cupertino-web-build.log` 成功，原缺失字体提示消失。FontManifest 现引用 packages/cupertino_icons/assets/CupertinoIcons.ttf，文件实际存在且为 1472 字节；这是实际打包证据，不宣称所有平台/页面的图标视觉已验收。依赖变化后完整门禁另执行，最终日志 `/private/tmp/forge-cupertino-final-quality.log`。


最终准入审查发现当前本地源仍与已构建的 1.2.13 使用同一版本；为避免同身份同版本不同内容的安装冲突，本地候选版本提高为 1.2.14+9 / MSIX 1.2.14.0，清单同步。已下载核验的 51fbab7 仍为历史 1.2.13 候选，不改写其报告或版本。新版本尚未构建或分发 Windows 安装包；仅本地更新并重验。

## 当前本地准入结论（1.2.14+9）

递增版本后的完整门禁 `/private/tmp/forge-local-114-quality.log` 五阶段通过，工具专项 `/private/tmp/forge-local-114-toolchecks/result.json` PASS，打包工具单测通过；MSIX 版本映射 1.2.14.0 严格大于已有 1.2.13.0。新本地 Web Release `/private/tmp/forge-local-114-web.log` 成功，Cupertino 字体已包含且无原缺失提示。补丁包含全部本次本地改动，反向 dry-check 和逐文件指纹用于核对工作区一致性。

本地通用 Dart/Flutter 代码准入检查通过，可供审阅并在获准后生成下一轮候选。没有创建 1.2.14 Windows 安装包，未提交、未推送、未部署。原生 Windows 按钮、真实输入法、非提权安装升级卸载和商店验收仍按原矩阵待验收；本结论不将这些项目标为 PASS，也不关闭原 issue。
