# 在另一台 Windows 设备开始自测

适用于从 **Windows Store candidate** 成功 run 下载并完整解压的 LocalTest artifact。无需 Flutter、Git、Visual Studio 或 Windows SDK。不要只复制一个 MSIX 或单独拿脚本。

这套自测不上传数据，不安装/卸载应用，不导入证书，不更改执行策略。结果文件留在本机。测试采用当前包实际版本和 EXE hash，同版本的旧包也会被识别；重新打包不自动成为升级测试。

## 1. 下载并确认来源

记录 Actions run URL、源码 SHA 和 artifact 名称。解压到新的用户可写目录，确保存在：

- 两份 MSIX、公开 CER、`result.json`、`local-test-signature.json`、`windows-host-smoke.json`。
- `candidate-origin.json`、本说明、`TEST_CHECKLIST.md`、`RC_TEST_PLAN.md`。
- `Start-SelfTest.ps1` 和完整 `recheck-tools/`。

`candidate-origin.json` 将 run URL/attempt 与源码 SHA 绑定。历史包没有该文件时报告明确不记录 run URL；不要猜测或补写历史构建来源。

## 2. 选择手工或辅助路径

**手工路径：不需要 Python。** 普通用户优先按文末 EXE 安装轨道验证；只有显式测试 MSIX 时才按 `TEST_CHECKLIST.md` 的 A01 核对哈希/证书，再由设备所有者确认测试证书信任和安装，完成 A04/A05、B01–B07。填写结果、保存截图与日志。此路径可以直接开始，不因没有 Python 被阻止。

**辅助路径：需要 Python 3.9+，建议与构建端一致使用 Python 3.12。** 在普通用户的 PowerShell 中进入解压目录：

```powershell
py -3 --version
# check 只用标准库，不要求 UIA 依赖，不会安装应用或信任证书
py -3 .\recheck-tools\windows_self_test.py check --bundle . --output "$env:USERPROFILE\Documents\ForgeSelfTests\preflight-01"
```

首次预检若因证书未信任、包未安装或旧 EXE hash 不匹配返回 `BLOCKED`，这是明确的准备缺口。按 A01–A02 处理并保留旧版本状态，再用新的输出目录重查；不要通过关闭签名校验解决。签名内容完整性、证书信任和安装是三个不同判断。

不具备本机证书信任权限时由测试机所有者按清单处理；脚本不会代为导入证书。同版本包重装、卸载或重置涉及现有数据，先与所有者确认；不得当成更高版本升级通过。

## 3. 运行一轮辅助自测

安装 UIA 依赖需要联网；若无法安装，保留手工路径，不自动下载额外工具或外设依赖：

```powershell
py -3 -m venv .selftest-venv
.\.selftest-venv\Scripts\python.exe -m pip install -r .\recheck-tools\windows_acceptance_requirements.txt
.\.selftest-venv\Scripts\python.exe .\recheck-tools\windows_ui_acceptance_test.py
.\.selftest-venv\Scripts\python.exe .\recheck-tools\windows_self_test_test.py
# 下例仅用于实际物理 x64；虚拟机改 vm-x64，Windows ARM x64 仿真改 arm64-emulation
.\.selftest-venv\Scripts\python.exe .\recheck-tools\windows_self_test.py run --bundle . --device-kind physical-x64 --output "$env:USERPROFILE\Documents\ForgeSelfTests\run-01"
```

也可用 `./Start-SelfTest.ps1 -Mode run -DeviceKind physical-x64 -Output <新目录>`。若本机执行策略不允许运行 PS1，使用上面的 Python 命令，不更改或绕过执行策略。

默认自动定位**当前用户按 EXE 安装的 Flutter Forge**；MSIX 测试显式传 `--target installed`，校验实际 EXE hash。运行四个场景，每个只执行一次、各启动一次应用：

1. `observation`：同一首页连续截图 3 次，再通过最新查询到的控件进入分类专注窗口和教学内容。
2. `caption_controls`：主窗口与分类窗口的原生最大化/还原、截图与状态检查；视觉仍需人工审核。
3. `main_with_child`：保留分类窗口关闭主窗口，确认进程退出。
4. `reopen`：关闭分类窗口、重新打开、操作教学内容并退出。

初始截图、输入或窗口聚焦失败时停止并记录 `BLOCKED`；实际状态断言失败为 `FAIL`，不以跳过或 Invoke 替代物理点击。原外部自动化接口的缓存问题仍需其自身复核，独立 UIA 路径成功不代表那些接口已修复。整个辅助执行有 600 秒上限；超时后若仍有本次测试应用，请正常关闭并保留证据。

观察开始菜单路径时，在 run 命令额外加 `--manual-start-menu`。每个场景都需测试者独立从开始菜单启动后按提示确认，最多等 180 秒；不要混用直接 EXE/AppsFolder。此选项需交互终端，仍是测试者确认的来源，不是机器证明开始菜单点击。

解包 EXE 仅作独立功能复核时，可显式加 `--target unpacked --exe 'C:\path\flutter_forge.exe'`，仍核对该候选的 EXE hash；不计安装和开始菜单验收。本轮默认不要扩大全模块、压力循环、真实模型、GPU 或外设范围。

## 4. 补齐人工项目并回传

输出包括 `result.json`、`REPORT.html`、`manual-results.json`、原始报告副本、native 截图/日志，以及同级的 `<输出目录名>-report.zip`。

- 自动检查通过后，整体仍为 `NEEDS_MANUAL_REVIEW`。
- 在 `manual-results.json` 填 A04/A05、B01–B07、C04 视觉和 configure 日志观察；保持原 ID，每项为 PASS/FAIL/BLOCKED/NOT_RUN。PASS/FAIL 必须有实际操作说明和位于本次输出目录中的证据文件相对路径。
- configure 日志的 `NOT_OBSERVED` 只说明已采集日志中未看到警告；`NOT_CAPTURED` 表示未采集。日志缺失不能写成警告消除，注册/请求日志出现也不代表全屏和标题栏已验收。保留真实状态及解释。
- 解包模式不能填写 A04/A05 的安装包开始菜单 PASS。升级、卸载、Windows 11 材质、DPI、读屏、断网、外设、真实模型和 WACK 按原清单另行验证，不因本轮整体 PASS 自动通过。

```powershell
# 仅重新汇总同一结果目录，不重跑、不安装、不上传
py -3 .\recheck-tools\windows_self_test.py report --output "$env:USERPROFILE\Documents\ForgeSelfTests\run-01"
```

退出码：`check/run` 的 0 仅表示预检或所选自动项成功，完整结果看 JSON/HTML；1=失败/输入错误，2=阻塞。`report` 的 0 表示自动项与要求的人工项均有通过记录，仍不代表商店验收。

分享前检查日志、文件路径及截图，不填真实模型令牌或个人敏感内容。回传 ZIP、run URL 和实际设备类型即可；工具不自动收集其他目录或发送报告。每次 check/run 必须用新目录，report 可刷新同一结果包。

## 普通用户 EXE 安装轨道（本轮优先）

同包若包含 `user-installer.json` 与 `*-user-setup.exe`，优先用标准用户账户验证这个按用户安装候选。它是独立 EXE 路径，不要求先导入 LocalTest MSIX 证书。当前候选未签名，系统提示或组织策略可能阻止安装；据实记录，不关闭安全检查。

```powershell
$info = Get-Content ./user-installer.json -Raw | ConvertFrom-Json
if ((Get-FileHash -LiteralPath $info.file -Algorithm SHA256).Hash.ToLowerInvariant() -ne $info.sha256) { throw 'EXE hash mismatch' }
$info | Format-List source_sha,version,install_scope,signing
```

在无管理员凭据的标准用户账户运行该 EXE，记录是否触发提权、实际安装目录、开始菜单、首次启动/重启、偏好写入、升级和卸载结果。正常目标是安装到用户目录。先记录已有 EXE/MSIX 与偏好，未经确认不卸载旧基线；EXE 与 MSIX 的数据迁移不可推定。

`windows_self_test.py` 当前默认验证 MSIX 安装身份；不要用其 MSIX 身份检查判定 EXE 安装失败。EXE 的辅助复核显式选择 `--target user-exe`，从当前用户的 Inno Setup 安装记录定位程序并校验 EXE hash，不依赖 MSIX 证书。安装、升级和卸载动作仍由测试者按本节记录。签名、安装、升级、卸载及交互各自报告，构建成功不自动转换为标准用户 PASS。


```powershell
# 已按用户安装 EXE 后，以普通用户运行。不要将管理员终端结果算作标准用户通过。
py -3 .\recheck-tools\windows_self_test.py check --bundle . --target user-exe --output "$env:USERPROFILE\Documents\ForgeSelfTests\exe-preflight-01"
.\.selftest-venv\Scripts\python.exe .\recheck-tools\windows_self_test.py run --bundle . --target user-exe --device-kind physical-x64 --output "$env:USERPROFILE\Documents\ForgeSelfTests\exe-run-01"
```

PS1 包装器默认 `-Target user-exe`；MSIX 安装测试显式选择 `-Target installed`。两个路径均核对实际 EXE，测试版号相同但二进制不同会阻塞。EXE 路径仍记录未签名状态，哈希检查不等于签名可信或系统策略允许安装。

辅助依赖只安装到本次解压目录的 `.selftest-venv`，不需要管理员或激活脚本。PS1 自动优先使用该环境；如果未创建，则使用系统 Python。两种入口默认都是 user-exe。

EXE 候选从验证过的暂存目录打包，包含应用本地 VC++ 运行库。user-installer.json 记录三个关键运行库哈希；user-exe 预检同时核对安装后的这些文件，缺少或不匹配时阻塞。此检查不要求安装全局 VC++ redistributable，也不证明干净设备实测已通过。
