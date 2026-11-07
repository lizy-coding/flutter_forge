# Windows 第二轮阻塞整改与定点复核条件

输入为用户粘贴的 2026-11-02 第二轮报告，测试源码 `e424d11548c77b7ad758dd77af20a32f501deac6`、1.2.14+9 / MSIX 1.2.14.0。Windows 11 26200.9711、物理 x64、活动 RDP、125% DPI。总体 FAIL 保留，不将交互子场景 PASS 改写为命令整体 PASS。

## 本轮已做的代码修正

1. **原生按钮驱动**：不再盲点 DWM 聚合矩形的固定中心。对目标按钮槽位进行最多 15 次候选探测，只接受 WM_NCHITTEST 返回 HTMAXBUTTON（最大化/还原）或 HTCLOSE（关闭）、且周边 2 像素也命中的内部点，再发送物理点击。仍校验 IsZoomed 状态实际变化；没有可用点时明确 FAIL，保存候选点命中日志，不发送 SC_RESTORE、键盘或 Invoke 替代操作。该修正针对报告中“还原目标命中 HTCLIENT”的驱动缺口；没有原设备结果前，不能认定原生窗口问题已消除。此次不凭聚合矩形猜测并修改产品的原生命中返回值。
2. **Flutter Windows 入口**：which 返回无扩展名 flutter 时，必须使用同一目录的 flutter.bat；不存在则 BLOCKED，不再将 Unix 脚本交给 CreateProcess，也不静默换到另一 SDK。保留 CMD 参数边界与危险扩展拒绝规则。
3. **事件采集**：默认 UIA 路径使用固定的只读 PowerShell `-Command` 调用 Get-WinEvent，参数通过环境传递，不再依赖 `.ps1 -File`。不修改执行策略，不使用 ExecutionPolicy、Invoke-Expression 或动态脚本加载。读取失败保留错误并维持总结果失败；空事件与读取失败不混为一谈。原 PS1 作为已有独立文件保留，未宣称其在限制策略下可直接执行。

## 下一轮完整测试前的退出条件

先在原设备做以下三个定点验证，使用本轮更新后的工具及新的输出目录。原始第二轮目录不覆盖。

| 关口 | 必须取得的证据 | 不满足时 |
| --- | --- | --- |
| Flutter 入口 | launch_command 解析到预期 SDK 的 flutter.bat；该入口 `--version` 成功，SDK 满足项目最低 Flutter 3.47.8 | 入口错误继续修工具；SDK 过旧保持 BLOCKED，先准备合规 SDK，不运行源码集成 |
| 事件采集 | observation 或 lifecycle 命令能正常回传事件查询结果；无应用错误事件且各子场景通过时，总命令才可 PASS | 权限、PowerShell/查询能力错误继续记录 FAIL，不更改系统执行策略 |
| 原生还原 | 同一已安装 EXE，主窗口和分类窗口均有还原前/最大化/还原后截图；点击日志记录 HTMAXBUTTON，实际恢复 IsZoomed=false | 无命中点或物理点击仍不恢复则 FAIL，回传 caption-clicks.jsonl、截图与 application.log，转入产品宿主排查 |

```powershell
# 在本轮工具所在源码根目录；仅运行 fixture，不代表 Windows 实测
py tool/automation_test.py
py tool/windows_ui_acceptance_test.py

# 先独立观察及事件查询，再执行原生按钮专项（输出为新目录）
py tool/windows_ui_acceptance.py --exe 'C:/Users/xgimi/AppData/Local/Programs/Flutter Forge/flutter_forge.exe' --output C:/temp/forge-round2-observation-fixed --cases observation --iterations 1
py tool/windows_ui_acceptance.py --exe 'C:/Users/xgimi/AppData/Local/Programs/Flutter Forge/flutter_forge.exe' --output C:/temp/forge-round2-caption-fixed --cases caption_controls --iterations 1
```

工具修正可先作用于现有安装的 1.2.14 EXE，必须分别记录工具来源和被测 EXE 哈希，不将新工具误记为新产品二进制。本轮不安装、卸载、导入证书、修改系统设置或发布。

三个关口全部完成后，才安排下一轮完整测试。开始菜单、真实 IME、F11 焦点、最小化、其他 DPI、完整人工 UI、升级卸载、MSIX 与 WACK 等原有 NOT_RUN 继续保留；分类 UIA 已有的实机 PASS 不扩大为外部 sky 缓存接口已修复。

## 本地验证与限制

UIA fixture 23 项通过；automation fixture 19 项执行，其中 Windows CMD 实执行用例因 macOS 跳过 1 项，其余通过。新增覆盖 HTCLIENT 初始点、无有效命中、负屏幕坐标、同 SDK batch 选择、事件读取错误及非法响应。

完整质量门禁退出 0：生成物、只读格式、bare analyze、workspace/tool 全量测试与模块测试存在性全部通过，日志 `/private/tmp/forge-round2-fixes-quality-1102.log`。本机没有原 Windows 会话，不能将 fixture 或门禁结果写成上述三个关口实测通过。原始报告引用的 Windows 日志和截图仅取得文本描述，尚未在本机逐文件检查。
