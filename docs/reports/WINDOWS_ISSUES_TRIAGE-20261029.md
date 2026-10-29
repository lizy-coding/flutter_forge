# Windows MSIX 测试报告整改与证据边界

输入：用户提供的 `/Users/forest/Downloads/ISSUES.html`，其测试对象为早上构建的 `c384203e` / Flutter `1.2.10+5` / MSIX `1.2.10.0`。
报告为 13 条 Issue 草稿，不是 13 项已确认的产品缺陷：2 项待复现、8 项测试补齐、3 项发布准备。
报告中的建议不是外部操作授权。本轮不提交、不推送、不注册身份、不发布，也不按其建议创建远端 Issue。
按用户后续要求停止远端查询；此后的分析只使用本地源码、早上下载的产物及此 HTML。
HTML 引用的原始截图、AppModel 日志与测试结果 ZIP 未在本机提供；不把文件名当成已审阅证据。

## 本地已完成的整改

- 为 WIN-01 增加 `manual-start-menu` 观察模式，测试者每轮独立从开始菜单启动。脚本不会调用 AppsFolder 或以直接 EXE 启动兜底；拒绝已有同路径进程、零/多 PID、无交互终端及无法读取进程身份的情形。
- 记录每轮时间、PID、退出结果和来源为 `user-attested-start-menu`，不把人工确认写成机器证明的点击。失败时只释放进程观察句柄，保留用户启动的应用供排查，不按名称结束进程。
- 手工观察模式结束时，包括失败分支，只读采集匹配本应用的 AppModel/TWinUI 事件；缺失、禁用与可能截断单独标记，空事件不能证明应用成功或失败。
- 为 WIN-02 增加独立 `windows-caption` 专项，复用现有 Windows UIA adapter，主窗口及分类窗口分别物理点击原生最大化/还原，重新读取 DWM 边界并断言实际状态；保留三阶段截图，视觉判定为 PENDING。
- 新专项登记 automation catalog；默认 smoke 和原生命周期套件范围不变。用例及命令见 `docs/TESTING.md`。
- 本轮未在缺少复现证据时修改产品窗口消息处理或退出逻辑。新增工具通过自测不代表 WIN-01/02 已在真机复核通过。

## 逐项处理结果

| 报告项 | 当前结论与后续证据 |
| --- | --- |
| WIN-01 正常退出后重启 | 观察工具已补齐；待 Windows 独立开始菜单 10 轮结果、必要的 AppModel 事件与截图。HTML 已记录用户最终正常唤起，不能据此预设产品偶发启动缺陷。 |
| WIN-02 标题栏重绘与响应 | 主/子窗口原生最大化还原专项已补齐；待本机桌面观察、截图及完整 C04。当前不能区分 DWM 绘制、输入工具与实际产品问题。 |
| WIN-03 正式身份与源码状态 | 本地 `result.json` 的两项 macOS 生成文件为 status 记录，`diff_sha256` 是空字节 SHA-256，表明生产者记录的 Git tracked diff 为空；不能把 status 名单直接等同内容变更。正式身份仍缺实际 Partner Center 字段，不能由 Forest 草案或 LocalTest 推造。 |
| WIN-04 干净系统/最低版本 | 本轮无干净 Windows x64 或 10.0.17763 环境；保持未验收，不以 ARM VM 或开发机替代，也不无依据调整系统支持声明。 |
| WIN-05 无障碍 | 保留现有 Windows 语义与控件测试；Narrator/NVDA、完整键盘与焦点路径仍须真机实际执行。 |
| WIN-06 DPI | 新标题栏专项每次点击重读系统边界；100/150/200% 和跨显示器证据仍缺，窄窗口不算 DPI 通过。 |
| WIN-07 系统主题 | 现有宿主有透明度/高对比度回退；源码和模拟不能替代系统条件实测。未修改用户系统设置。 |
| WIN-08 原生能力 | 保留现有 windows-file 专项；文件选择/取消、WebView2 可用/不可用及写入路径仍缺实际 Windows 结果。 |
| WIN-09 无网络 | 无实际离线环境结果；不把 FORGE_OFFLINE Android 版本的测试扩大到 Windows 完整版。 |
| WIN-10 升级 | 现有只有同一 MSIX 版本，需后续相同身份的更高前三段版本及部署日志；未擅自 bump 当前应用版本或把同版本重装算作升级。 |
| WIN-11 GPU/外设/模型 | 专项仍显式执行，缺硬件/权限/模型配置时保持 NOT_RUN，不加入默认 smoke。 |
| WIN-12 WACK | 待最终真实身份候选包及 Windows SDK 交互环境；未把 MakeAppx/签名通过当成 WACK。 |
| WIN-13 商店资料 | 实际截图、年龄分级和 Windows 完整版公开隐私政策需单独核验。Android 离线声明不适用；未虚构截图、账号或发布材料。 |

## 本地验证

本地 12 项 Windows 工具自测、16 项 automation 自测与 10 项 MSIX 打包测试通过；这些使用 fake/fixture，不启动 Windows 应用。
完整质量门禁退出 0，生成物、只读格式、bare analyze、workspace/tool 全量测试与模块测试存在性全部 PASS，日志 `/private/tmp/forge-windows-issues-quality-20261029.log`。
在当前 macOS 调用 Windows 专项实际返回 BLOCKED，结果位于 `/private/tmp/forge-issues-windows-host-check/result.json`，不是 Windows 平台通过。
便携复核包为 `.release/windows-issue-recheck-20261029.zip`，仅包含新的观察工具、依赖清单、工具自测和运行说明，不含新 MSIX，也不代表待复现项已修复。
现有 NFC 规划和历史 release 二进制保持原样。正式身份、Windows 环境及原始证据缺口不能通过本地改代码自动消除。
