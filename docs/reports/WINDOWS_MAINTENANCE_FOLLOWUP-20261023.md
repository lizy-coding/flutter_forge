# Windows 真机维护问题后续修复与运行入口

基线：`b501f210f275a5a40197e3be2fd38b5d808a782b`。2026-10-23。
本次修改不包含当前工作区正在开发的 GenUI、网络诊断及工作流模块。

## 真机输入证据

用户提供的 Windows 10 专业版 19045 x64 / Flutter 3.47.2 检查清单报告：
Release 在临时 CL=/utf-8 下构建成功，关闭 40/40 次、退出码均为 0，
ProcDump first-chance C0000005 转储、Application Error 1000 和残留进程均为 0。
这作为用户报告的关闭路径回归证据；本环境未读取 D 盘原始日志，不扩大成所有 UI／多窗口通过。

## 处理状态

| 项目 | 本次实现 | 验收边界 |
|---|---|---|
| P1-1 材质断言 | native 增加 systemBackdropSupported；Win10 实色可通过，Win11 初始化失败也允许实色；macOS 保持原断言 | 单元测试覆盖，Windows 实际重跑待完成 |
| P1-2 真实输入 | 独立 Python UIA 驱动，用真实鼠标点击原生 caption、真实 Alt+F4，不投递关闭消息替代 | 每场景默认 10 次；激活／UIA 不可用返回 BLOCKED |
| P1-3 多窗口 | 复用、原生关闭重开、子窗口 Alt+F4、主带子退出及三分类快速请求；截图、交互状态与 HWND 库存 | HWND 不是 Dart UUID；三分类快速请求不宣称同时调用三个 Dart Future；截图仍需人工检查 |
| P2-1 编码 | 仅 universal_ble_plugin 的 MSVC 编译增加 /utf-8，保留 /WX，不设置全局 CL | 936 代码页构建待 Windows 执行 |
| P2-2 私有符号 | runner、desktop_multi_window_plugin、usb_network_bridge 的 Release 生成 /Zi + /DEBUG:FULL，保持优化；私有 PDB 单独输出 | 收集器校验 PE RSDS 与 PDB GUID/age、记录哈希、源码状态及工具链；实际 PDB/CDB 验证待完成 |
| P2-3 first-chance | 同一真实输入驱动可附加 ProcDump，仅过滤 C0000005，确认监控已启动、无转储、监控正常结束 | 从主窗口显示后开始监控，覆盖后续输入／关闭，不声称覆盖最早期启动 |
| P2-4 新版本 | 验证目录记录 SHA 和二进制身份，不冒充新的发布版本 | UI、最终安装包验收完成后再决定版本并经 Agent Hub 发布 |

## Windows 本地运行

以下命令在此次修改所在源码根目录执行。使用独立测试构建、交互式已解锁的桌面。
脚本只管理自己启动的进程；运行时不要操作同一测试桌面的其他窗口。
不要把 RDP 无法激活或 UIA 控件缺失当作 PASS，也不要更换为后台消息投递来绕过。

```powershell
flutter pub get --enforce-lockfile
Push-Location apps/flutter_forge
# 在代码页 936、没有人为 CL=/utf-8 的环境中执行。
flutter build windows --release
flutter test --no-pub integration_test/desktop_material_acceptance_test.dart -d windows
Pop-Location

py -m pip install -r tool/windows_acceptance_requirements.txt
py tool/windows_ui_acceptance.py `
  --exe apps/flutter_forge/build/windows/x64/runner/Release/flutter_forge.exe `
  --output D:/forge-validation/ui-20261023 --iterations 10
```

输出目录必须尚不存在，防止覆盖旧结果。默认七组场景，每组十次。
快速定位时可添加 `--cases caption alt_f4_main`；缩减次数只能算诊断，不能算完整验收。
`result.json` 的 PASS 仅表示列出的输入场景、正常退出与限定观察区间事件检查通过；
截图人工复核、未采集到的 engine 内部销毁和未捕获应用日志仍保持各自状态。
驱动不会自动证明所有 Flutter 页面均正常，也不包含硬件、网络服务及所有教学模块验收。

### ProcDump 过滤回归

自行从 Microsoft 获取 ProcDump，并先人工运行一次接受其许可；脚本不自动接受 EULA。
然后使用新的输出目录：

```powershell
py tool/windows_ui_acceptance.py `
  --exe apps/flutter_forge/build/windows/x64/runner/Release/flutter_forge.exe `
  --output D:/forge-validation/procdump-20261023 --iterations 10 `
  --procdump C:/Sysinternals/procdump64.exe
```

附加参数为 `-e 1 -f C0000005 -ma -n 1 <owned-pid> <case-output>`。
不能确认监控准备完成时返回 BLOCKED；转储出现或 ProcDump 非零退出视为失败。
事件查询权限失败不会当成“无事件”。转储可能含进程内存，不自动上传，保留在受限位置。

### 收集匹配的私有符号

```powershell
py tool/windows_symbol_bundle.py `
  --build apps/flutter_forge/build/windows/x64 `
  --output D:/forge-validation/private-symbols-20261023
```

输出包含三组自研 PE/PDB 和 manifest.json。PDB 位于构建的 `private-symbols/Release`，
不加入安装规则；工具拒绝 GUID/age 不匹配的符号。应将该目录作为私有构建证据保存。
使用最终安装包前，还要确认安装 runner 哈希与 manifest 中 runner 一致，
并在 CDB/WinDbg 上确认真实函数名和源码行解析。不要把匹配 GUID/age 等同于源码行实测。

## CI／发布接入边界

本轮未修改任何现有工作流、门禁脚本或版本号，也未发布安装包。
可评审的后续接入位置：Windows Release 构建之后、安装打包之前运行符号收集器，
再单独上传 private-symbols 目录作为受限 artifact；安装目录继续排除 PDB。
真实输入任务应在已解锁的交互式自托管 Windows 会话执行，不能假设普通服务会话可用。

将 GUID/age 校验及交互验收升级为必需发布步骤会改变门禁；根 AGENTS.md 规定：
“禁止修改 `.github/workflows/ci.yml`、`tool/quality_gate.sh` 或其他门禁脚本语义，
除非任务显式授权 `packaging_change` 并要求人工验收。”
因此本次先提供独立入口，CI 必需门禁接入等待对应授权，新版本发布等待本轮 Windows UI 验收。

## 本机验证

- PASS：隔离快照完整质量门禁，478 项 Dart／Flutter 测试、26 项 Node 工具测试及脚手架检查。
- PASS：7 项 Python 符号解析与输入场景编排测试；包含匹配／不匹配 GUID-age、子窗口 Alt+F4、原生关闭重开，以及避免重复关闭主窗口。
- PASS：macOS 独立宿主集成测试 1 项，完整执行材质、教学实色、搜索返回、主题和全屏往返。
- PENDING：Windows MSVC 构建、UIA／真实输入与 ProcDump、实际 PDB 和 CDB 验证；PowerShell 事件查询脚本也需 Windows 执行。

Windows 工具的格式解析与场景编排采用合成／fake fixture 测试；不代替 Windows 真实运行。
完整门禁和 macOS 共享材质／搜索／全屏回归在隔离的基线副本中执行，
测试宿主仅修改名称和 bundle ID 以避免影响已有应用数据，不属于正式分发包验收。
