# Microsoft Store 分发准备

产品展示名草案为 **Flutter Forge by Forest**，发布者展示名草案为 **Forest**。
名称需在 Partner Center 预留后确认；本目录不伪造微软分配的包身份。
现有 Inno Setup EXE 分发继续保留，MSIX 是独立商店路径，不修改现有 CI、门禁或 Agent Hub 冻结发布 manifest。

## 身份与版本

从 https://storedeveloper.microsoft.com/ 免费注册，创建 **MSIX or PWA app**，预留产品名称。
在产品标识页面复制 Package/Identity/Name、Package/Identity/Publisher、Package/Properties/PublisherDisplayName，
分别填入 `identity.example.json` 的前三个字段，另存到仓库外的 `identity.json`。
`publisher_display_name` 最终必须与账号登记值一致，不能仅按草案填写。
`display_name` 必须匹配已预留名称。

`--local-test` 使用独立的 `Forest.FlutterForge.LocalTest` 身份，文件名包含 `local-test`，不可上架。
正式配置中的空身份、占位字段或本地测试身份会被拒绝。
版本读取 app 的 `pubspec.yaml`：例如 `1.2.10+5` 映射为 MSIX `1.2.10.0`，
第四段保留给商店；再次提交更新需要提高前三段，不能只增加 Flutter build number。

## 本机预览

以下命令在仓库根目录运行，Windows 使用 `python`，macOS 可使用 `python3`。

```powershell
python -m pip install -r tool/windows_store_requirements.txt
python tool/windows_store_test.py
python tool/windows_store.py preview --local-test --output .release/windows-store-preview
```

输出 manifest、从 Windows 现有 ICO 生成的 PNG 和 `result.json`。
预览不包含 Windows 二进制，不生成可安装包，不代表 Windows 构建或安装通过。
输出目录必须是新目录，工具不删除、覆盖已有产物。

## 推荐：GitHub 构建，本地只验收

独立工作流 `.github/workflows/windows-store.yml` 在 GitHub `windows-2022` x64 runner 上构建，
先复用现有完整 quality workflow，并 checkout 该门禁输出的同一源码 SHA。
本地 Windows 虚拟机只需要下载、解压和安装产物，不需要 Flutter、Git、Python 或 Visual Studio。
本轮新增工作流只产出本地测试身份包；正式商店身份取得后仍需单独配置并重新构建。
下载后按同包提供的 [跨设备测试清单](TEST_CHECKLIST.md) 执行，填写环境、源码 SHA、版本、哈希及各项实际结果。

触发方式：相关打包源文件进入 `dev` 的 push 会自动运行；工作流进入默认分支后，也可以手动执行
`gh workflow run windows-store.yml --ref dev`。新增 workflow 尚未进入默认分支时，不能依赖手动按钮立即可用。
提交、推送仍按仓库规则单独授权，Actions 不能构建只存在于本地的未提交改动。
首次候选包应明确所需业务源码范围，不能把大量已有脏树全部默认提交。

在成功 run 的 Artifacts 中下载 `flutter-forge-msix-local-test-<sha>`，包含：

- 原始 unsigned MSIX 与 `result.json`（源码、版本和 payload/包哈希）。
- 单独的 `*-signed.msix`，使用该次临时 runner 新生成的 30 天测试证书。
- `Forest-FlutterForge-LocalTest.cer`（仅公开证书）及 `local-test-signature.json`（签名包和证书哈希、指纹、到期时间）。
- `TEST_CHECKLIST.md` 与本 README，无需在测试机准备源码即可按清单验收。

私钥不可导出，绝不上传 PFX；结束时删除 runner 内的临时私钥。
该证书不具有公开可信签名身份，不是商店签名；每次 run 的证书不同。
Artifacts 保留 14 天，不创建 GitHub Release，不自动上传或发布 Microsoft Store。

也可以在本机通过 CLI 下载成功 run 的 artifact（替换 run ID 和 SHA，目标目录使用新目录）：

```bash
gh run list --workflow windows-store.yml --branch dev
gh run download <run-id> --name flutter-forge-msix-local-test-<sha> --dir .release/msix-download-<run-id>
```

本地先比较下载文件的 SHA-256 与报告，再核对证书 Subject/Thumbprint/到期时间。
如本地尚未信任该次公开测试证书，在测试虚拟机中确认后将其安装到本地计算机的 Trusted People，
然后安装 signed MSIX；不用安装构建工具，也不用关闭系统签名校验。
这一步会改变客户机证书信任，需要明确确认；不能由下载动作自动触发。
完成安装、开始菜单启动和卸载后，按本次精确指纹清理测试信任。
测试证书不会用于正式商店包，正式包由商店在审核发布流程中重新签名。

## Windows 构建

如果不用 GitHub runner，手工构建主机需要 Flutter、Git、Visual Studio C++ 桌面工具链、Windows SDK 的 MakeAppx 和 Python/Pillow。
从当前编译器对应的 Visual Studio `VC/Redist/MSVC/<version>/x64/Microsoft.VC*.CRT` 选取 retail runtime 目录，
通过参数提供；不得使用 Debug CRT、ARM64 CRT 或从未知网站下载单个 DLL。
工具将零散 DLL 作为 app-local runtime 打包，因此不依赖用户预先安装 VC++ runtime。
运行库再分发应遵循对应 Visual Studio 许可。

```powershell
# 本地流程验证包；替换运行库路径，选择新输出目录
python tool/windows_store.py package --local-test --vc-runtime-dir 'C:/path/to/x64/Microsoft.VC143.CRT' --output .release/windows-store-vm

# 注册并取得正式身份之后，构建商店候选包
python tool/windows_store.py package --identity-config 'C:/path/to/identity.json' --vc-runtime-dir 'C:/path/to/x64/Microsoft.VC143.CRT' --output .release/windows-store-candidate
```

每次实际打包都执行 `flutter build windows --release`，核对 EXE/DLL 的 PE x64 架构、`data/app.so` 的 x64 AOT ELF 头与必要 Release 文件，
排除 PDB/LIB/EXP 私有符号，复制完整 Flutter data/plugins/native assets，使用 MakeAppx 的正常验证打包（不使用 `/nv`）。
报告记录源码 HEAD、脏树路径、tracked diff 摘要、payload 文件哈希与包 SHA-256；
dirty tree 产物只是工作区候选，不能当作 HEAD 发布验收，也不能代替冻结发布来源。
`MaxVersionTested` 是打包声明，不构成该系统的实测证据。

## 虚拟机基本流程

本轮范围：MSIX 构建 → 本地测试签名 → 安装 → 开始菜单启动 → 首页和一个确定性模块 → 正常关闭 → 卸载。
Windows 11 ARM 中运行 x64 包需明确标为仿真环境，不能代替 x64 真机、GPU 或外设验收。

本地安装必须有客户机信任的测试代码签名证书；先确认虚拟机已有测试证书及其 Subject，
与 manifest Publisher 精确一致后才签名。工具不创建或信任证书、不修改 Developer Mode、不安装或卸载应用。
若客户机没有测试信任，需要单独完成该设置；不可关闭系统签名校验。
对输出 MSIX **复制一份**本地签名，保留原始 unsigned 候选及哈希。

```powershell
# Windows SDK Developer PowerShell；替换路径与现有代码签名证书 thumbprint
Copy-Item '<unsigned-local-test.msix>' '<signed-local-test.msix>'
signtool sign /fd SHA256 /sha1 '<thumbprint>' '<signed-local-test.msix>'
signtool verify /pa /v '<signed-local-test.msix>'
Add-AppxPackage -Path '<signed-local-test.msix>'
Get-AppxPackage -Name Forest.FlutterForge.LocalTest | Select-Object Name,Version,PackageFamilyName,InstallLocation
```

从开始菜单启动 **Flutter Forge by Forest (Local Test)**，确认首页可读、搜索并进入“三棵树”教学模块、返回、关闭、再次启动。
核对包只读安装目录下没有失败的写入；检查偏好保存、WebView2 用户数据目录及可用性。
`webview_windows`、BLE、网络、本地模型等原生或外部能力仍需各自的后续验证。
关闭测试应用后，用 `Remove-AppxPackage -Package <刚查询的精确 PackageFullName>` 仅卸载本次测试包，
再次 `Get-AppxPackage -Name Forest.FlutterForge.LocalTest` 确认无结果。不要通配卸载正式应用。

## 真机冒烟与上架前待办

下一步复用 `test/support/automation/` 与 `tool/automation.py` 完善真机冒烟：

- 安装包身份、版本、开始菜单激活、首次启动、关闭、重启、升级和卸载。
- 搜索 → 分类 → 确定性模块 → 返回；键盘焦点与快捷键。
- 主窗口和显式分类专注窗口的关闭、重开与退出边界。
- 标准用户、DPI/缩放、系统明暗/高对比度；Windows 10 的最低版本与 Windows 11 分别记录。
- 原生文件选择、WebView2 可写目录、依赖缺失时反馈；GPU/BLE 等保持专项，不放进默认 smoke。

先运行既有 `python tool/automation.py run --platform windows --output <new-dir>` 获得宿主核心交互证据。
它通过 Flutter 启动源码构建，**不能代替已安装 MSIX 的开始菜单激活验证**；后续增加安装包专项时统一登记 catalog。

真机安装包测试通过后，运行 WACK（交互桌面会话，保存 XML 并检查实际各项结果）：

```powershell
appcert.exe reset
appcert.exe test -appxpackagepath '<signed-candidate.msix>' -reportoutputpath 'C:/path/to/wack.xml'
```

不能仅凭 MakeAppx 成功、WACK 进程退出码或全部跳过就宣称商店审核通过。
提交前另需准备：商店真实截图、简体中文描述、分类/年龄分级、支持联系方式、
与 Windows 实际网络/模型/设备行为相符的公开隐私政策、`runFullTrust` 用途说明。
Android 离线版隐私声明不能直接复用给完整 Windows 版。
本地测试身份包不上传；注册后使用正式身份重新构建并验证。
GitHub Release 仍遵循 Agent Hub；商店提交和公开发布分别留待授权执行。

## 官方依据

- [免费账号入口](https://learn.microsoft.com/en-us/windows/apps/publish/partner-center/open-a-developer-account)
- [手工生成 MSIX manifest 与组件](https://learn.microsoft.com/en-us/windows/msix/desktop/desktop-to-uwp-manual-conversion)
- [MakeAppx](https://learn.microsoft.com/en-us/windows/uwp/packaging/create-app-package-with-makeappx-tool)
- [商店包身份、版本与签名要求](https://learn.microsoft.com/en-us/windows/apps/publish/publish-your-app/msix/app-package-requirements)
- [WACK](https://learn.microsoft.com/en-us/windows/uwp/debug-test-perf/windows-app-certification-kit)
