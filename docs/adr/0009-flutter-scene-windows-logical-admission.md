# Flutter Scene Windows 逻辑准入

状态：accepted。Flutter Scene 3D 从本决策起在目录与路由层同时准入 macOS 和 Windows，因为 Windows Runner 已按固定依赖要求启用 Flutter GPU，且模块逻辑不依赖 macOS 专属 API；这一准入只表示 Windows 可以进入模块，不表示 Windows 构建、GPU 首帧、高 DPI 输入或安装器验收已经通过。

## Consequences

- ADR 0008 中的 Windows 目录限制由本决策取代；Android、iOS 与 Web 的限制不变。
- Windows 主机证据继续由 flutter_scene_3d_windows_admission 独立任务管理，未完成前不得标记 Windows 平台 PASS。
