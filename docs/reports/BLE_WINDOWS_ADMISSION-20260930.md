# Windows BLE 入口接入 — 2026-09-30

## 接入范围

依据 ADR 0011 的统一规则，从生成源 `tool/generate_agent_indexes.js` 的 BLE 排除集合移除 Windows；继续排除 iOS、Web。模块目录与稳定路径 `/bluetooth-ble` 统一由 module_registry 判定，不增加页面自行决定入口可见性的分支。

Windows 使用现有 `universal_ble` 适配器和共享 BleSession：状态与权限查询、限时扫描、系统 GATT 设备查询、连接、服务发现、按属性读取或订阅、断开及页面资源释放。Windows 生成的插件注册和 CMake 插件列表已有 universal_ble。

Android 专用音频 Profile 查询及系统设置 MethodChannel 不在 Windows 上调用。Windows 的系统设备查询仅代表插件返回的 BLE/GATT 设备，不等同于完整系统蓝牙连接列表。

插件说明要求 Bluetooth 4.0 及以上适配器；如以后采用带应用身份的 Windows 打包方式，应单独核对 bluetooth/radios capabilities。本次不修改安装器或发布门禁。

## 证据边界

| 项目 | 状态 | 说明 |
| --- | --- | --- |
| 模块目录与稳定路由接入 | 已配置 | 生成源开放 Windows；模块学习状态与平台验收独立 |
| Windows 插件注册 | 已配置 | 现有 Flutter 生成文件已注册 universal_ble |
| 跨平台代码与 Fake 客户端测试 | 自动化验证 | 验证准入集合及共享页面行为，不作为 Windows 主机证据 |
| Windows Debug/Release 构建 | PENDING | 当前为 macOS 主机，未执行 Windows 构建 |
| Windows 真实适配器与状态 | PENDING | 未在 Windows 主机运行 |
| Windows 扫描、连接、服务发现、读取 | PENDING | 未取得实际外设闭环 |
| Windows 通知接收与主动/意外断开 | PENDING | 未取得实际外设操作证据 |
| Windows 安装器与系统连接查询 | PENDING | 未完成当前源码安装和设备列表核对 |

本次只完成接入配置与跨平台自动化验证，不标记 Windows 平台 PASS。

当前 macOS 工作区执行 `bash tool/quality_gate.sh`，六阶段均完成，BLE 自动化共 12 项。门禁通过临时 Git 索引检查当前候选源码，原暂存状态保持不变；这些结果不构成 Windows 主机运行证据。

## 后续主机验收

1. 在 Windows 主机对同一提交构建 Debug 和 Release，记录版本及适配器信息。
2. 安装运行后，从目录及 `/bluetooth-ble` 进入页面，检查关闭、不支持及权限异常状态。
3. 对真实 BLE 外设完成扫描、连接、发现服务、读取及通知接收，保存 UI 和原始值证据。
4. 验证系统 BLE 设备列表、主动断开、外设断电和离开页面后的资源释放。
