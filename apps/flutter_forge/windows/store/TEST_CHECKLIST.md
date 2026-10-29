# Windows MSIX 跨设备测试清单

本清单随 GitHub Actions 安装包一起提供。先填写本次包的实际版本与源码 SHA；默认所有项目为 **NOT_RUN**。
本地测试包名为 **Flutter Forge by Forest (Local Test)**，身份为 `Forest.FlutterForge.LocalTest`，不是正式商店包。
本轮 RC 为 Flutter `1.2.11+6` / MSIX `1.2.11.0`，第四段为商店保留；以本次 `result.json` 为准。覆盖升级对象为早上的同身份 `1.2.10.0`，不能用同版本重装代替升级。

## 记录环境与产物

| 字段 | 测试者填写 |
| --- | --- |
| GitHub Actions run URL / artifact 名称 | |
| result.json：source.head / app_version / package_version | |
| local-test-signature.json：sha256 / certificate_thumbprint | |
| 测试日期、测试者、Windows 版本与 OS build | |
| 物理 x64 / Windows ARM x64 仿真 / 虚拟机及软件版本 | |
| CPU / GPU / 显示缩放 / 测试账号是否普通用户 | |
| 日志、截图与故障记录目录 | |

从成功 run 的 Artifacts 下载完整压缩包到**新目录**并解压。没有 Flutter、Python、Git 或 Visual Studio 也可执行 A/B 基本清单。
不要把测试私钥或模型 token 放入报告；本次只分发公开 CER，不应出现 PFX。

## A. 包完整性与安装（虚拟机先完成）

在解压目录打开普通 PowerShell，先执行以下只读检查。任何一项抛错都应停止安装，记录 FAIL。

```powershell
$ErrorActionPreference = 'Stop'
$build = Get-Content ./result.json -Raw | ConvertFrom-Json
$sign = Get-Content ./local-test-signature.json -Raw | ConvertFrom-Json
if ($build.package_build -ne 'PASS' -or $build.identity_kind -ne 'local-test') { throw '不是成功构建的测试包' }
if ($build.source.head -ne $sign.source_sha) { throw '源码 SHA 不一致' }
if ((Get-FileHash -LiteralPath $build.package.path -Algorithm SHA256).Hash.ToLowerInvariant() -ne $build.package.sha256) { throw '原包哈希不一致' }
if ((Get-FileHash -LiteralPath $sign.package -Algorithm SHA256).Hash.ToLowerInvariant() -ne $sign.sha256) { throw '签名包哈希不一致' }
if ((Get-FileHash -LiteralPath $sign.certificate -Algorithm SHA256).Hash.ToLowerInvariant() -ne $sign.certificate_sha256) { throw '证书哈希不一致' }
$cert = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new((Resolve-Path -LiteralPath $sign.certificate).Path)
if ($cert.Thumbprint -ne $sign.certificate_thumbprint -or $cert.Subject -ne $sign.certificate_subject) { throw '证书身份不一致' }
if ($cert.NotAfter -le (Get-Date)) { throw '测试证书已过期，请获取新包' }
$cert | Format-List Subject,Thumbprint,NotAfter
Get-AppxPackage -Name Forest.FlutterForge.LocalTest | Select-Object Name,Version,PackageFullName
```

只有确认 artifact 来源和以上指纹之后，才在测试机执行证书信任。该操作新增计算机证书信任，需要管理员权限与测试机所有者确认。
不要导入 Trusted Root，不关闭签名检查或 Defender。已有旧测试包时，先记录其版本和数据；不要未经确认覆盖或卸载旧包。

```powershell
# 管理员 PowerShell；仅导入已核对的本次公开 CER
Import-Certificate -FilePath ./Forest-FlutterForge-LocalTest.cer -CertStoreLocation Cert:\LocalMachine\TrustedPeople
```

回到**原测试用户**的普通 PowerShell，安装签名包并核对身份：

```powershell
$ErrorActionPreference = 'Stop'
$sign = Get-Content ./local-test-signature.json -Raw | ConvertFrom-Json
Add-AppxPackage -Path (Resolve-Path -LiteralPath $sign.package).Path
$pkg = Get-AppxPackage -Name Forest.FlutterForge.LocalTest
if (-not $pkg) { throw '安装后找不到测试包' }
$pkg | Select-Object Name,Version,PackageFullName,PackageFamilyName,InstallLocation
```

| ID | 操作与预期 | 结果 / 证据 |
| --- | --- | --- |
| A01 | 哈希、源码 SHA、签名证书指纹匹配；记录证书到期时间 | NOT_RUN |
| A02 | 安装成功，版本等于 result.json；无需另装 VC++ runtime | NOT_RUN |
| A03 | 开始菜单出现测试应用，图标与名称可识别；不覆盖已有正式 EXE/商店应用 | NOT_RUN |
| A04 | 从开始菜单首次启动；出现可读首页，无白屏、黑屏、系统依赖错误或崩溃 | NOT_RUN |
| A05 | 正常关闭后再次从开始菜单启动；不需要开发工具或管理员权限 | NOT_RUN |

若安装失败，保存 PowerShell 提供的 HRESULT / ActivityId；可执行 `Get-AppPackageLog -ActivityID <该次ID>` 导出部署日志。

## B. 确定性核心交互（虚拟机先完成）

| ID | 操作与预期 | 结果 / 截图 |
| --- | --- | --- |
| B01 | 首页 → 分类 → “三棵树”教学模块 → 返回；模块正文和示例真实显示 | NOT_RUN |
| B02 | 搜索“三棵树”并进入模块；返回保留搜索词与目录位置；清除搜索后恢复目录 | NOT_RUN |
| B03 | 打开“弹窗”分类的教学页，打开和关闭一个弹窗/子页面；返回后仍可操作 | NOT_RUN |
| B04 | 切换明暗、实色主题；文字清楚，路由不重置；关闭重启后偏好按产品规则保留 | NOT_RUN |
| B05 | 调整为窄窗口再恢复；内容可阅读、按钮可点击，无阻断操作的溢出 | NOT_RUN |
| B06 | 显式打开一个分类专注窗口，关闭后重开一次；主窗口始终可用 | NOT_RUN |
| B07 | 保留分类窗口时关闭主窗口，全部本次窗口退出；再次启动无残留或启动超时 | NOT_RUN |

每项只执行一轮。GPU、外设、真实模型和全模块遍历不纳入虚拟机基本通过条件。
开始菜单激活和已安装包的实际页面交互必须执行，不能用直接启动构建目录 EXE 或 Widget 测试替代。

## C. 真机扩展冒烟（下一阶段）

| ID | 操作与预期 | 结果 / 证据 |
| --- | --- | --- |
| C01 | 物理 Windows x64 设备重跑 A/B，记录独立结果 | NOT_RUN |
| C02 | Tab / Shift+Tab 焦点可见；快速打开与 Esc；滑块方向键/Home/End、禁用状态；Narrator/NVDA 能朗读并调值 | NOT_RUN |
| C03 | 100%/150%/200% 缩放；移动到不同 DPI 显示器后窗口、点击位置和文字正常 | NOT_RUN |
| C04 | 原生最小化、最大化、还原、Snap；F11 为真实全屏；Alt+F4/关闭按钮退出；无窗口生命周期错误 | NOT_RUN |
| C05 | 系统明暗、关闭透明与高对比度：基础页材质按系统能力降级，教学内容可读 | NOT_RUN |
| C06 | 文件选择成功与取消；WebView2 正常或明确不可用反馈，用户数据写入可写目录 | NOT_RUN |
| C07 | 无网络时核心教学仍可访问；联网功能有合理错误反馈，无无限等待 | NOT_RUN |
| C08 | 第二个更高 MSIX 版本覆盖升级，保留期望的偏好；身份改变或相同版本不能冒充升级测试 | NOT_RUN |
| C09 | GPU/3D、BLE、视频和模型按需单独测试；记录硬件、权限与实际操作，未运行保留 NOT_RUN | NOT_RUN |

已配置开发工具的真机可复用现有入口：

```powershell
# 源码宿主集成，另写报告；它不测试 MSIX 开始菜单激活
python tool/automation.py run --platform windows --output C:/temp/forge-native-smoke
# 已安装 EXE 的 UIA 生命周期专项（需要 Python 和 windows_acceptance_requirements.txt）
python tool/automation.py run --platform windows --case windows-lifecycle --exe '<InstallLocation>/flutter_forge.exe' --output C:/temp/forge-msix-lifecycle
```

UIA 入口直接运行已安装 EXE，因此仍需独立完成 A04/A05。仅保留物理设备实际执行的结果，不把 Windows 主题模拟或 ARM 仿真写为物理 x64 PASS。
WACK 在具备 Windows SDK 的交互桌面上显式运行并保存 XML，按实际报告逐项判断；它不由本清单自动执行，也不等于商店审核。

## D. 清理与交付结果

先从 UI 正常关闭本次测试应用。在原测试用户的 PowerShell 中，只卸载本次精确测试包；测试机已有旧包时先核对版本。

```powershell
$ErrorActionPreference = 'Stop'
$pkg = Get-AppxPackage -Name Forest.FlutterForge.LocalTest
if ($pkg) { Remove-AppxPackage -Package $pkg.PackageFullName }
if (Get-AppxPackage -Name Forest.FlutterForge.LocalTest) { throw '卸载后仍存在测试包' }
```

测试机所有者确认后，在管理员 PowerShell 中仅移除**本次新导入**的证书；如果该指纹原已存在或仍有同次构建的测试包使用它，保留并说明。
先核对 `local-test-signature.json` 指纹，再执行 `Remove-Item -LiteralPath "Cert:\LocalMachine\TrustedPeople\<本次指纹>"`。
不要清空证书存储或按名称通配删除应用。

| ID | 操作与预期 | 结果 / 证据 |
| --- | --- | --- |
| D01 | 卸载成功，开始菜单入口消失；正式应用与用户其他文件不受影响 | NOT_RUN |
| D02 | 本次新增的测试证书按需清理并记录；测试数据残留按实际情况说明 | NOT_RUN |

回传填写后的本清单及截图/日志；失败项包含操作步骤、预期、实际、错误码和包 SHA-256。
判定：虚拟机基本流程需 A/B/D 实际执行且通过；缺证书/系统能力为 BLOCKED；未执行为 NOT_RUN；真机和 WACK 单独记录。
