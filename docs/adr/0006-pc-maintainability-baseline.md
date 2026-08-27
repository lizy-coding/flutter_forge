# ADR 0006: PC 可维护性封板与 Android 兼容轨道

状态：accepted。Flutter Forge 以 macOS/Windows 为当前可维护性封板主线；Android 作为非阻塞兼容轨道并行推进。移动端始终使用应用内单窗口导航，桌面大屏才允许分类窗口；新业务模块不得拥有多窗口职责，必须经过 Agent Hub、模块契约和测试准入。

原因：PC 多窗口和平台能力存在独立 Engine、原生插件与生命周期成本，先稳定边界可以避免新增模块扩散平台债务；Android 的硬件和 host 能力则按独立任务逐步验证。
