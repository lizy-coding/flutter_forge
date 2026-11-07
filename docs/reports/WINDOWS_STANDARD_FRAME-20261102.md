# Windows 标准标题栏兼容路径实施记录

用户批准以系统标准标题栏作为 Windows 默认方案，决策见 ADR 0021。本轮基于 `e424d11` 的未提交工作区；保留先前 Windows 工具整改与未跟踪 release 产物，未提交、推送或发布。

## 已修改

- Windows DesktopWindowHost 对主引擎和分类引擎使用相同标准窗口样式；不再处理 WM_NCCALCSIZE/WM_NCHITTEST，不再扩展 DWM 到 Flutter 客户区或裁剪 Flutter 视图。系统负责标题、边框、拖动、按钮与 Snap。
- 原生宿主仅保留应用窗口命令、主题取色、状态通知与全屏恢复等职责。Windows 关闭 Mica，向 Flutter 报告 materialActive=false；用户已有主题偏好不改写。
- Flutter Windows 顶部为 48dp 内容区工具栏，保留主页、返回、快速打开、侧栏、主题和全屏入口；两侧仅有普通 6dp 留白。其空白区不拖窗、不双击最大化。macOS 继续使用现有沉浸式标题栏与按钮留白。
- 全屏仍通过按钮/F11 切换，保留原生最大化语义与原有窗口位置恢复逻辑；主窗口关闭退出、分类窗口独立关闭的生命周期代码保持原有路径。
- 更新 ADR、指南、词汇与生成源，重新生成项目和应用契约、实施计划。Windows 原生构建和主机验收仍记录 pending。

## 本地验证

- 固定 Flutter 3.47.8 下 33 项定向测试通过：desktop_workbench、platform_interaction、desktop_window_configuration、category_window_lifecycle。平台 Widget 模拟不能替代原生边框验收。
- 新增/调整验证：Windows 工具栏没有原生按钮留白、不发送拖窗/双击命令、材质配置关闭、导航状态与全屏入口可用；覆盖主窗口及分类窗口。macOS 原有交互断言继续执行。
- 完整质量门禁退出 0，生成物、格式、bare analyze、workspace/tool 全量测试和模块测试存在性全部通过；日志：`/private/tmp/forge-system-frame-quality.log`。
- 初次定向命令因相对 PATH 使用了全局 SDK，出现 native asset Kernel hash 不匹配；已改为项目固定 SDK 的绝对路径，定向测试通过，没有修改全局 SDK。
- DTD 发现没有运行中的调试实例，热重载工具返回无可用 App；不将该结果记录为运行验收。

## 新 Windows 二进制的定点验收

本轮包含原生 C++ 修改，必须重建新 EXE，更新工具配合旧 1.2.14 EXE不能验证本轮方案。记录源码状态、EXE 哈希、Windows build、DPI 和会话类型。

1. 主窗口和分类窗口均显示系统标准标题栏，Flutter 工具栏完整位于客户区内，右侧没有原生按钮预留大空白；文字、搜索、全屏入口可点击。
2. 分别物理操作最小化、最大化、还原、关闭与系统标题栏拖动/双击；对照窗口实际状态并留图。继续使用原 caption 专项，不放宽 IsZoomed 断言。
3. 验证 Windows Snap、125% 与100% DPI，缩窄/恢复窗口，检查客户区不被标题栏遮挡或裁剪；其他 DPI 与跨显示器另按实际设备记录。
4. 从普通态、最大化态分别 F11 进入/退出全屏，确认恢复位置、原最大化状态、焦点及原生标题栏；全屏按钮行为一致。
5. 执行主页、搜索、模块、返回及分类窗口关闭/重开/复用，确认主窗口关闭时没有残留窗口或进程。
6. 检查明暗/实色外观和高对比度可读性；Windows 不以 Mica 外观作为通过条件。安装、升级、开始菜单、MSIX 与 WACK 仍单独验收。

上述结果未取得前，本轮只表示兼容方案已实现，不能宣称原生还原问题已真机解决。
