# Flutter Scene Android 只读准入

状态：accepted。Flutter Scene 3D 在 Android 首阶段只开放场景初始化和自动巡展，不开放手势、选择、聚焦或编辑能力；这样可以先隔离验证 Android Flutter GPU 渲染路径，再在后续任务中独立建设移动端操控。

## Consequences

- Android 进入模块后看到明确的只读说明，桌面平台继续保留完整交互。
- Android Flutter GPU、APK 构建和真实首帧仍需独立证据；目录准入不构成平台 PASS。
- 本阶段不新增 Android integration 自动化流程。
