# Windows 候选包跨设备自测入口

起点 `0af428c`。本次增强随包交付，不修改 Dart/原生应用行为，不改变质量门禁、云端宿主 smoke 命令或通过标准；现有 `release/1.2.10/` 本地产物不纳入提交。

## 交付变化

- 同包新增 `START_HERE.md`、`Start-SelfTest.ps1`、`recheck-tools/windows_self_test.py` 与 fixture 测试。工作流仅增加相关触发路径、随包文件及 `candidate-origin.json` 的 run URL/attempt/source SHA，保留原构建、签名、宿主测试和发布权限。
- 标准库 check 核验两份 MSIX/CER、证书指纹与到期时间、包内 manifest/EXE、云端实际执行计数与源码关联；Windows 端另读 Authenticode、当前用户安装信息、实际 EXE hash 和交互桌面。发现同版本旧 EXE 仍阻塞；不导入证书、不安装/卸载、不修改执行策略、不下载或上传数据。
- run 自动定位已安装包，要求测试者声明物理/虚拟/ARM 仿真环境；已有同路径进程时要求正常关闭，不接管或杀死已有应用。默认 observation/caption_controls/main_with_child/reopen 各一次，600 秒总上限。
- observation 连续三次截同一首页，再通过新查询的 UIA 控件进入分类与教学；截图/物理输入缺失为 BLOCKED，不重复已经发出的点击或用 Invoke 代替。
- configure 日志单独记录 OBSERVED_NEEDS_REVIEW/NOT_OBSERVED/NOT_CAPTURED 和注册/首请求计数，不把警告直接解释为窗口损坏，也不因未采集日志而认定警告消失。
- 输出结果 JSON、HTML、人工结果模板、原始报告与 native 日志/截图，汇总为 ZIP。默认仍 NEEDS_MANUAL_REVIEW；人工 PASS/FAIL 必须附说明与本次目录内证据。A04/A05、B01–B07 等边界见更新清单，升级/卸载/WACK/外设等不由本轮通过推定。

## 实际验证范围

- Portable self-test fixture 测试 15 项通过；UIA 工具自测 18 项通过，均不声称真实 Windows 宿主验收。
- 用 run `41375880604` 的真实下载候选核对完整性通过；发现并修复 .NET 七位小数证书时间在 Python 3.9 的兼容问题，新增回归。因当前为 macOS，原生预检按设计返回 BLOCKED，未操作 Windows 桌面、证书或安装。
- 完整 `bash tool/quality_gate.sh` 五阶段通过：生成契约、Dart 格式、bare analyze、workspace/tool tests、模块测试存在性。沿用原锁文件和 pub.dev，无依赖变更。
- catalog 已登记 `windows-self-test`（安装包人工/辅助执行）与 `windows-self-test-tests`（fixture）。本地执行结果：`/private/tmp/forge-selftest-tools-final-20261102/result.json`；完整门禁：`/private/tmp/forge-selftest-quality-20261102.log`。
- 当前主机无 PowerShell，PS1 包装器、Windows Authenticode/安装发现、桌面预检及真实物理点击仍需另一台 Windows 设备按随包入口复核。fixture 结果不替代这些验证。

推送后新 run 才会附带本次工具；已存在的 artifact 不会因源码更新自动包含新入口。测试机所有者仍需独立确认测试证书信任和安装。新包版本不自动提高，不能把相同 MSIX 版本重装作为升级验收。

## 阶段一至三继续维护

- 分类 UIA 允许精确名称或限定的双重语义名称；多个候选明确阻塞。工具自测增加歧义和缺失覆盖。
- runner 针对 Windows .bat/.cmd 显式使用 CMD，关闭 AutoRun 与延迟扩展；其他命令保持直接启动。引号、百分号、换行等尚不支持的批处理参数明确阻塞，不静默展开。Windows 专项会实际执行临时 CMD，核对中文/空格/特殊字符参数和失败退出码；macOS 跳过该项，不声明 Windows 回归通过。
- 标题栏物理点击新增 caption-clicks.jsonl，记录 DPI、frame/caption 坐标空间、目标点、实际光标和 WM_NCHITTEST、最大化/最小化状态。仅为原失败定位补证据，尚未据此确认应用根因或修复按钮。
- 新候选版本为 1.2.12+7 / MSIX 1.2.12.0；Windows 候选流程另产出按用户 EXE 与 user-installer.json。EXE 未签名，标准用户安装、更新、卸载仍待实测。
- Windows 候选增加工具回归步骤，以实际 Windows CMD 测试阻止启动器假通过。未变更现有 quality_gate 或 cloud smoke 的命令及判定。

仍未达到整体下一轮验收准备完成：EXE 轨道自动身份发现、Windows 启动器真实回归、标题栏失败定位与阶段三统一交互的设备复核仍需完成。所有在途改动保留为工作区事实。


EXE 自测适配已实现 `--target user-exe`：验证同源码安装器与 cloud smoke、读取 HKCU 两种注册表视图的 Inno 安装记录、核对版本及实际 EXE hash；不读机器级安装记录或要求 MSIX 证书。PS1 默认选择此轨道。新增测试后 self-test fixture 共 18 项通过，Windows 注册表/实际安装仍待真实 Windows 执行。

最终门禁两次在并发执行的 network_security_test 中观察到 TLS 夹具返回 unknown，单独运行通过。夹具原先立即发送明文 HTTP 并销毁 socket，存在在 ClientHello 前关闭连接的时序风险。本轮改为等待客户端数据后返回 TLS fatal handshake_failure 告警并正常关闭；保留原 suspicious 与“不绕过校验”断言，不改产品实现或门禁命令。修正后的定向 6 项通过，完整门禁另行记录。

TLS 夹具修正后的完整门禁已通过，日志 `/private/tmp/forge-candidate-tls-fixed-quality.log`；工具专项 `/private/tmp/forge-candidate-tools-prepush/result.json` 为 PASS，包含 manager、UIA 与 self-test fixture。真实 Windows CMD 参数执行在本机为跳过，必须由新 Windows 候选工作流执行后再判定。
