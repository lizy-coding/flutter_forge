# macOS 新窗口启动黑屏与原生异常

日期：2026-10-21。基础 HEAD `eb500f555b9ce930959d05dfbb09f820985b4c65`，`dev` 加未提交工作区。本记录补充此前鼠标验收，不是发布或跨平台验收。

## 本地日志结论

用户补充：黑屏一段时间后恢复，且曾发生崩溃。当前机器未找到 Flutter Forge 的独立 `.ips` 崩溃报告；统一日志中找到多次明确的 AppKit 原生异常。例如：

```text
2026-10-21 14:08:06.311 Flutter Forge[34374] An uncaught exception was raised
2026-10-21 14:08:06.311 Flutter Forge[34374] -[Flutter_Forge.AppDelegate applicationDidFinishLaunching:]: unrecognized selector
2026-10-21 14:08:06.313 Flutter Forge[34374] FAULT: NSInvalidArgumentException
2026-10-21 14:14:27.868 Flutter Forge[34374] -[Flutter_Forge.AppDelegate applicationDidBecomeActive:]: unrecognized selector
```

完整栈进入本项目 `AppDelegate.applicationDidFinishLaunching`／`applicationDidBecomeActive` 后，在对应 `super` 调用处抛出。当前 FlutterAppDelegate 没有实现这两个可选委托方法；移除非法 super 调用，保留本项目初始化、窗口激活及导航菜单逻辑，不修改 Flutter 的生命周期注册接口。可对照 [FlutterAppDelegate 实现](https://raw.githubusercontent.com/flutter/flutter/main/engine/src/flutter/shell/platform/darwin/macos/framework/Source/FlutterAppDelegate.mm)。本地异常栈是本次判定依据，链接不是当前 SDK 精确版本验收。

黑色启动表面方面，FlutterViewController 本机公开头文件明确说明其视图默认背景为黑色。原创建流程在注册插件／窗口宿主和窗口定义前显示窗口，且未设置启动背景。此路径与用户“等待后恢复”相符，但没有将黑屏全部持续时间归因于单一因素，未测量 Debug JIT 或 GPU 首帧耗时。

## 修改

- 创建子控制器时立即设置系统窗口背景色；应用宿主初始化也设置相同启动背景。
- 插件、每窗口宿主、窗口定义和通道就绪后，才对非隐藏窗口执行 `makeKeyAndOrderFront`。隐藏窗口不再先显示再隐藏。
- 原生宿主在收到 Dart `configure` 握手后才主动发送状态和导航命令，避免窗口创建通知早于引擎启动时出现 `Invalid engine handle`。配置前的状态可通过已有 `getState` 查询，未新增延时或轮询。
- 移除上述两个非法 super 生命周期调用。未修改教学模块、依赖版本或发布配置。

## 验收

- PASS：最终 Debug 完整构建、重启；真实坐标点击新建基础分类窗口，直接显示内容；关闭后重建成功，无系统菜单激活前置操作。
- PASS：Debug 进入教学模块；最终握手保护前后均执行新建／关闭／重建。最终 Debug PID `42198` 的控制台不再出现 `Invalid engine handle`。
- PASS：最终 Debug PID `42198` 的系统日志过滤 `unrecognized selector`、`uncaught exception`、`NSInvalidArgumentException`、`Invalid engine handle`，无匹配记录。
- PASS：最终 Release 构建（约 77.7 MB）；本机 PID `44302`。真实坐标点击新建分类窗口后，再点击模块进入“三棵树与生命周期”，不是仅有静态首帧。[Release 子窗口模块截图](../evidence/window_startup_fix_20261021/release_child_module.png)。
- PASS：同样过滤最终 Release PID `44302` 的上述四类系统错误，无匹配记录。
- PASS：最终工作区 `bash tool/quality_gate.sh`，生成物、格式、analyze、全 workspace／工具测试、30/30 模块测试存在性均通过；`git diff --check` 通过。

仍有边界：关闭 Debug 子窗口时可见 `Communicating on a dead channel` 提示，本轮未随之出现进程终止或页面失效；未证明用户历史崩溃全部来自上述异常。隐藏／重新激活流程的自动化操作未完成完整可见性验收，不标 PASS。Debug 新引擎初始化仍有耗时，本轮没有承诺零等待，也没有采集精确首帧指标。Windows／移动／Web 未在本轮重验。

当前运行的是最终 Release，Debug 和 Release 均已重建。未提交、未推送，保留原有工作区修改。

## 指纹（SHA-256）

- `AppDelegate.swift`：`c0d128edd70d775051a33b3a140f228c3a5d2d204beb6b1aae27b9111e102f97`
- `FlutterMultiWindowPlugin.swift`：`68e83bc7494ea1d9655aba941d1ee17990828e6f25e1445a3097e258e8beeabb`
- Release `Contents/MacOS/Flutter Forge`：`305fad637b04df8c7fdfc5b1cfd1e728f294f19bdbdff4c840522eef48783724`
