# Windows 关闭崩溃修复

日期：2026-10-21。基线 HEAD：`eb500f5`，分支：`dev`。本记录描述未提交工作区修改，不代表 v1.2.9 或后续安装包已通过验收。

后续三项 P1 的启动屏障、有序退出和配置恢复实现见 [多窗口 P1 修复记录](WINDOW_P1_LIFECYCLE_FIX-20261021.md)；下文保留最初关闭补丁的范围，Windows 原生验收仍单独待完成。

## 输入证据与范围

用户提供 v1.2.9 Windows x64 Release 关闭崩溃报告：主窗口正常显示后，标题栏关闭或 Alt+F4 稳定触发 `0xc0000005`，随后为 `0xc000041d`；故障位于 controller 销毁路径中的 `FlutterDesktopMessengerSetCallback`，读取地址为 `0x1e8`。

当前源码仍在 `DesktopWindowHost` 析构时调用 `SetMethodCallHandler(nullptr)`。该调用需要有效 engine，但 registrar 销毁插件时 engine backing 可能已经清空，与输入证据高度吻合。缺少发布二进制匹配的私有 PDB，不能声称已逐帧映射全部源码调用。

本次只处理宿主销毁时序及其回调重入风险。已有 Windows 材质、DWM 参数和区域裁剪改动原样保留；分类窗口启动黑屏、顶部栏视觉优化仍需后续专项定位。

后续用户补充：报告中的实测平台是 Windows 10；Windows 10 使用实色，Windows 11 做兼容。本轮据此增加窄范围版本保护：仅在系统 build ≥ 22621 时尝试公开的 system backdrop 接口，版本检测失败直接保持 `materialActive=false`，由现有 Flutter 表面逻辑回退实色。Windows 11 早期版本也回退实色；受支持版本仍需满足用户偏好、系统透明设置、高对比度与 DWM 调用成功条件。此调整不修改标题栏布局、DWM margins 或区域裁剪，不构成 Windows 11 材质验收。

## 修改

- `apps/flutter_forge/windows/runner/desktop_window_host.cpp`：析构函数不再注销 MethodChannel handler，也不调用其他 messenger API。handler 随所属 engine 销毁；本地 Flutter SDK 的 `MethodChannel` 析构函数为默认实现，不会自动注销 handler。若未来允许插件提前于 engine 独立卸载，必须另行增加 engine 存活期内的显式注销流程。
- 收到 `WM_DESTROY` / `WM_NCDESTROY` 时，先移除窗口 subclass，再委托原窗口过程；委托返回后不访问插件对象。正常析构仍保留原生 subclass 清理，覆盖 controller 被直接销毁的路径。
- 窗口状态消息委托可能重入销毁流程。使用独立存活标记检查委托期间插件是否已销毁，避免继续访问已释放对象并发送 windowState。
- 新增独立 `tool/windows_close_smoke.ps1`，交替发送 `WM_CLOSE` / `WM_SYSCOMMAND(SC_CLOSE)`，检查退出超时、退出码及观察区间内匹配可执行文件路径和 PID 的 Application Error 1000。只清理本脚本创建的进程，不按进程名批量终止应用。

未修改质量门禁、发布流程或生成源；模块、路由、依赖及平台声明未变化。

## 本地验证

`bash tool/quality_gate.sh`：PASS。

- 生成契约无漂移。
- Dart 格式无改动，bare `flutter analyze` 无 issue。
- workspace 全量测试、工具测试及模块测试存在性检查通过。
- `git diff --check`：PASS。

以上在 macOS 上执行，不编译 Windows C++，也不覆盖 Windows messenger teardown。当前主机无 Windows 运行环境及 PowerShell，新增脚本尚未执行，Windows 构建与原生运行结果为 PENDING。

## Windows 验收步骤

从 `apps/flutter_forge` 执行 `flutter build windows --release`，保存对应源码身份、Flutter 版本、产物哈希与匹配 PDB。再从仓库根目录执行：

```powershell
powershell -NoProfile -File .\tool\windows_close_smoke.ps1 `
  -Executable .\apps\flutter_forge\build\windows\x64\runner\Release\flutter_forge.exe `
  -Iterations 20
```

脚本发现 HWND 后留出启动等待时间；这不能证明首帧可见。PASS 仅表示消息关闭退出检查通过且限定观察区间没有匹配的 Application Error 1000，不代表所有 WER、晚到事件或 first-chance 异常均已排除。

必须额外在同一 Release 构建上人工检查：

1. 主窗口显示后，通过原生标题栏按钮、Alt+F4 分别关闭。
2. 分类窗口单独关闭、关闭后重开、重复打开复用。
3. 分类窗口仍存在时关闭主窗口，确认应用和附属窗口退出、无进程残留。
4. ProcDump first-chance 监控下重复上述路径，确认不再命中原来的 messenger 异常；核对 Windows Application/WER 日志。
5. 分别记录子窗口有无可见内容、可交互性及 `Invalid engine handle`。若仍黑屏，作为后续启动链路问题，不以本次退出检查 PASS 代替修复。

只有 Windows Release 构建、重复退出及多窗口操作完成后，才可将 Windows 关闭崩溃验收改为 PASS；在此之前不推进顶部栏优化。
