# Windows RC 1.2.11 · 新一轮验收

状态：测试候选，不是正式商店提交包。正式 Partner Center 尚未注册，本轮保持 `Forest.FlutterForge.LocalTest` / `CN=Forest Flutter Forge Local Test`，以便从旧测试包覆盖升级。

## 候选包进入验收的条件

- 源码门禁通过，实际安装包报告记录 Flutter 3.47.8 / Dart 3.13.7 或当前固定修复基线。
- app_version 为 1.2.11+6，MSIX Version 为 1.2.11.0；比早上的同身份 1.2.10.0 更高。
- MakePri 与 MakeAppx 实际成功，包内有 resources.pri、新版图标与完整版隐私入口。
- unsigned 原包、signed 测试包、公开 CER 的哈希、指纹及源码 SHA 可核对；不分发私钥。
- 同一提交的 `windows-host-smoke.json` 为 PASS，至少运行一项真实宿主测试。它是云端 Windows Server 源码宿主集成，不能当作 MSIX 安装、开始菜单或物理 Windows 11 验收。

若上述构建或 smoke 失败，本次不作为通过候选；诊断 artifact 供修复，不触发正式发布。

## 本轮优先级与操作

1. **保留旧版本升级前状态。** 在安装旧 LocalTest 1.2.10.0 的原测试用户下，记录 PackageFullName、主题偏好、最近访问及截图；正常关闭全部测试窗口。旧包不存在则先记录“升级场景缺旧包”，不要把干净安装算升级。
2. **校验并覆盖升级。** 按同包 TEST_CHECKLIST.md 的 A 段核对新报告和 CER；该次证书每 run 不同，所有者确认后精确信任。回到原普通用户执行 Add-AppxPackage 新签名包，核对 1.2.11.0、相同 PackageFamilyName 和预期偏好保留。
3. **确认新增内容。** 从开始菜单进入首页，查看新玻璃图标；在“关于”展开完整版隐私说明，在模型连接弹窗查看发送前说明，不需要输入真实令牌。
4. **WIN-01 独立复核。** 只从开始菜单完成关闭/重开，使用 recheck-tools 的 manual-start-menu 模式，10 轮。每轮打开分类专注窗口，再关闭主窗口，记录时间、PID 与事件；不要混用 AppsFolder/直接 EXE 兜底。
5. **WIN-02 独立复核。** 主窗口和分类窗口分别物理点击最大化/还原；审核截图中按钮是否可辨。再人工补最小化、Snap、F11、Alt+F4，对照原清单 C04，不能由最大化专项推定其他子项通过。
6. **真机扩展与干净环境。** 按原清单补文件选择/取消、WebView2 及写入路径、断网/恢复、DPI、系统主题与读屏；干净系统、最低声明 OS 及外设功能只按实际环境记录。
7. **卸载与清理。** 完成状态采集后，只移除本次测试身份包及本次新增且不再使用的证书，保留正式应用和原有用户文件。

## 同包工具（无需 Flutter SDK）

```powershell
# 解压目录，Python 依赖仅用于 UIA 复核；手工清单不要求 Python
py -m pip install -r ./recheck-tools/windows_acceptance_requirements.txt
py ./recheck-tools/windows_ui_acceptance_test.py
$pkg = Get-AppxPackage -Name Forest.FlutterForge.LocalTest
if (-not $pkg -or $pkg.Version -ne [version]'1.2.11.0') { throw '未安装本轮 RC' }
$exe = Join-Path $pkg.InstallLocation flutter_forge.exe
py ./recheck-tools/windows_ui_acceptance.py --exe $exe --output ./restart-results --launch-mode manual-start-menu --cases main_with_child --iterations 10
# 上一套所有窗口退出后，再执行标题栏专项
py ./recheck-tools/windows_ui_acceptance.py --exe $exe --output ./caption-results --cases caption_controls --iterations 1
```

输出目录必须为新目录。手工启动观察每次等待确认有上限；缺控制台、旧进程、无法识别 PID 均为 BLOCKED。它记录测试者确认的开始菜单来源，不是机器证明点击。
AppModel/TWinUI 读取失败、禁用或空事件不能代替成功/失败判定；标准输出未附加、视觉 PENDING 等限制须原样保留。

## 结果回传与退出条件

填写 TEST_CHECKLIST.md，回传对应输出目录、画面及每项实际结果。报告必须带构建 run URL、源码 SHA、新旧版本及包哈希，去除凭据。
只有本轮新包的升级/启动/退出、核心交互及 WIN-01/02 复核确切完成后，才据实评估测试 RC 是否通过；未执行项保持 NOT_RUN，环境缺失保持 BLOCKED。
WACK XML、正式身份、实际商店素材、实时 AI 声明与审核反馈流程仍为正式提交前单独完成项，不因本轮 RC 构建成功自动通过。
