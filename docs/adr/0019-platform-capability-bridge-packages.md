# ADR 0019: 平台能力桥接包规范

状态：accepted

USB、蓝牙、电池这类多端差异大的能力，早期实现路径不一：有的经 workspace 包（flutter_battery、usb_network_bridge），有的在模块内直接声明 MethodChannel 并由宿主 MainActivity 注册处理器（usb_detector 旧实现），异常被转成界面字符串。通道契约分散在模块、宿主与原生三层，无法离线测试，平台矩阵与实现脱节，宿主原生代码持续累积模块关注点。

平台差异能力（原生代码、FFI、MethodChannel、平台行为差异）统一经 `packages/` 下的桥接包接入，以 flutter_battery 为唯一模板，必备四件套：

1. 平台接口：`plugin_platform_interface` token 校验，静态 instance 可替换，模块不直接触碰 MethodChannel。
2. 运行时能力查询：`queryCapabilities()` 永不抛出，无适配器返回 none；模块按能力位降级展示，与静态平台矩阵互补（静态管入口，运行时管设备级差异）。
3. 类型化结果：`Outcome<T>` + 稳定原因码，只有 available 携带值；单条数据解析失败降级为 error 条目，不吞掉整批列表；禁止把异常 try/catch 转成界面字符串。
4. 测试闭环：通道契约测试（mock handler）+ fake 注入；原生侧以 FlutterPlugin 自注册通道，宿主 App 原生代码只保留应用壳关注点（窗口、生命周期）。

粒度与边界：

- 每个能力域一个接口（flutter_battery、usb_detector_bridge），不建跨能力全局中间层——本仓库的教学价值就在展示"接口 → 适配 → 降级"链路本身，全局门面会隐藏它并耦合所有硬件域。
- 模块 UI 只消费接口与结果类型；周期性策略（轮询、采样间隔）留在模块 session。
- 平台矩阵仍由 `tool/agent_indexes/availability.js` 能力规则推导（承 ADR 0013/0014）：新增平台支持 = 包内适配器 + 能力规则修改 + 重新生成，不触碰模块与宿主。
- workspace 内部包即插件化边界，不发布 pub.dev：vendored 与教学性质 + CI 无原生编译全覆盖，独立发布会放大"改了原生没人编译"的风险。

## 后果

- 通道契约、原生实现、能力声明同包演进，模块可完全离线测试。
- 复活 deferred 模块只需移除 entryRestriction：usb_detector 已按本模板完成迁移（usb_detector_bridge），限制移除后 Android 自动可用，届时再补真机验收。
- `flutter_forge/bluetooth_system` 系统设置与音频连接查询已移入 `packages/bluetooth_system_bridge`，通过 FlutterPlugin 自注册；BLE 扫描、连接和 GATT 仍由 universal_ble 适配，模块保留会话状态机。生物识别插件按锁定来源内部化到 `packages/flutter_biometric`，不修改外部仓库。
- 新增平台差异模块的评审口径：四件套齐备 + availability 能力规则 + 宿主原生代码零增长。
