# Windows 1.2.11 解包 EXE 冒烟阻塞处理

来源：用户提供的 Windows 10 22H2 测试摘要。截图出现 `window capture timed out` / `FrameArrived timed out`，原生按钮点击出现 `coordinate input geometry is unavailable`，最新控件索引点击出现 `not available in cached app state`；启动日志出现 desktop_host configure 的 MissingPluginException，但首页控件树可读、进程正常响应。

本轮修改基于 HEAD `4a9f157`，为本地未提交工作区修正；不是新包验收。未取得该轮工具的实现、原始日志、截图或可操作的 Windows 会话，不能确定截图、缓存失效或通道警告的最终根因。

## 仓库内修正

- Windows 主引擎在其他插件注册及 SetChildContent 前注册桌面宿主通道；传入真实顶层 HWND，避免未挂载视图时 GA_ROOT 指向 Flutter 子视图。分类引擎回调同样先注册宿主，再注册其他插件。
- DesktopWindowHost 先安装方法处理器，再配置窗口框架，缩小插件注册、SetParent、MoveWindow 或框架更新重入消息循环时通道尚未就绪的窗口。现有 Dart 三次有界重试和显式失败重试保留。
- 增加 `[desktop_host] registered hwnd=...` 与 `first configure received hwnd=...` 日志，用于分别核对主窗口和分类窗口的注册与首个请求。日志收到请求不代表全屏、按钮或材质已验收。
- 仓库 UIA 工具在聚焦后即时查找按钮，移除查找与点击之间的再次聚焦，避免在两者之间触发额外焦点树更新；不重试已经发出的点击，以免重复导航。
- 截图后端抛出异常时归类 BLOCKED 并保留原因，避免将捕获工具失败写成产品 FAIL。空白画面检查仍保留，不能靠降低断言获得 PASS。

前两类原始报错不是该脚本生成的错误字符串。以上 UIA 调整不代表外部自动化接口已修复；它提供独立的复核路径，仍需实际 Windows 桌面验证。

## 后续实际执行

在包含本轮修改的新 Windows 构建上，记录源码 SHA、包哈希、系统版本和会话类型。使用可见且未锁定的交互桌面；先人工确认窗口实际有画面。

```powershell
py -m pip install -r tool/windows_acceptance_requirements.txt
py tool/windows_ui_acceptance.py --exe 'C:/path/to/flutter_forge.exe' --output C:/temp/forge-caption-new --cases caption_controls --iterations 1
py tool/windows_ui_acceptance.py --exe 'C:/path/to/flutter_forge.exe' --output C:/temp/forge-lifecycle-new --cases main_with_child reopen reuse --iterations 1
```

输出目录必须不存在。第一条专项为主/分类窗口各保存还原前、最大化、还原后的截图，并用实际窗口状态判断最大化/还原；图标是否可辨仍需人工审核。第二条覆盖部分窗口生命周期和教学交互，不等同 B01–B07 完整验收；另按 TEST_CHECKLIST.md 补搜索返回、主题偏好、窄窗口和弹窗等人工步骤。

若截图或物理输入仍不可用，保持 BLOCKED；保留外部工具版本、完整错误、时间与目标 HWND/PID，并用人工画面及操作结果区分工具阻塞和应用异常。不要把键盘替代或 UIA Invoke 成功作为原生按钮物理点击通过。

若目标是 MSIX，必须另在具备该次测试证书信任的环境安装包，并从开始菜单执行 A04/A05；解包 EXE、源码宿主测试不能替代。历史云端 PASS、本轮 Windows BLOCKED 和本轮工具 fixture 结果分开保留。

## 本地验证

- Windows UIA 工具自测 15 项通过，含截图异常归类和焦点/查询/点击顺序测试；不启动 Windows 应用。
- 当前 macOS 调用 caption_controls 专项返回 BLOCKED，结果 `/private/tmp/forge-windows-startup-host-check-1030/result.json`。
- 完整质量门禁首轮受到用户配置写入和本地服务端口的沙箱权限阻断；获得所需权限后重跑通过。依赖解析曾因本机镜像设置自动改写锁文件并更新三个间接依赖，已恢复原锁文件，以官方源执行 `pub get --enforce-lockfile`，再完成最终门禁（退出 0）。最终日志 `/private/tmp/forge-windows-startup-quality-1030-final.log`；生成物、格式、bare analyze、workspace/tool 全量测试和模块测试存在性全部通过，锁文件无变更。
- 本机不能编译或运行 Windows runner，本轮原生 C++ 修改仍需 Windows 构建与主/分类窗口实际操作回归。三项问题暂不标为已关闭。
