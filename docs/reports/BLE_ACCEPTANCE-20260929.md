# BLE 学习模块验收记录（2026-09-29）

## 边界

目标流程：扫描 → 连接 → 发现 GATT 服务 → 读取或订阅特征值 → 断开。首版不写入。每个平台单独验收；包的支持声明和构建成功不能代替真实外设闭环。

## 当前证据

| 项目 | 状态 | 证据 |
| --- | --- | --- |
| 模块契约与注册 | PASS | `bash tool/generate_harness_ai_analysis.sh`：`agent_docs_valid:45` |
| 模块行为与列表测试 | PASS | `flutter test test/modules/platform/bluetooth_ble/ble_session_test.dart`：5 项通过；全量测试通过 |
| Dart 静态分析 | PASS | `flutter analyze --no-pub`：`No issues found` |
| macOS 调试构建 | PASS | `flutter build macos --debug --no-pub` 构建 `Flutter Forge.app` |
| Android 调试构建 | PASS | `flutter build apk --debug --no-pub` 构建 `app-debug.apk` |
| macOS 蓝牙状态与扫描 | PASS | macOS 26.5、M5：调试版获系统蓝牙授权后，应用显示适配器已开启、权限已授予，并发现多个附近 BLE 广播 |
| iQOO TWS Air3 扫描识别 | PASS | 优化列表后从 114 台扫描结果中按名称筛出 `iQOO TWS Air3`，显示 RSSI -42 dBm |
| macOS iQOO TWS Air3 连接与 GATT 读取 | PENDING | 点击连接后 15 秒超时，未进入服务发现；系统已连接 BLE 设备查询返回 0 台 |
| 质量门禁 | PENDING | `bash tool/quality_gate.sh`：4/6 阶段通过；文档与 Dart 格式阶段以 `git diff --exit-code` 对比 HEAD，因本次未提交的新生成物与源文件差异返回失败；独立生成校验 `agent_docs_valid:45`、格式无改动 |
| Android 真机入口与权限 | PASS | V2338A、Android 16（API 36）：模块搜索可进入 BLE 页面；系统弹出“查找与连接附近的设备”权限，授权后页面显示“已授予” |
| Android 真机扫描 | PASS | 扫描结束记录 88 台附近设备，页面可按名称显示 iQOO TWS Air3；[截图](../../apps/flutter_forge/docs/screenshots/ble/android_scan.png) |
| Android 真机连接与服务发现 | PASS | 点击 iQOO TWS Air3 后页面事件记录“已连接”及“发现 12 项服务”；系统 `BluetoothGatt` 日志包含连接成功及服务发现完成 |
| Android 真机 GATT 读取与断开 | PASS | 在服务 `180a` 读取特征值 `2a23`，页面显示 `45 23 00 00 00 d6 05 00`；点击断开后页面记录“主动断开”且服务区回到未连接状态；[截图](../../apps/flutter_forge/docs/screenshots/ble/android_gatt_read_disconnect.png) |
| Android 通知订阅 | PENDING | 本次外设尚未完成可通知特征值的订阅及通知接收操作 |
| Windows 10 闭环 | PENDING | 本次未在 Windows 主机运行 |
| iOS 构建 | PENDING | 仓库当前没有 `apps/flutter_forge/ios` 宿主目录 |
| Web | DEFERRED | 首版不开放 Web，浏览器设备选择与服务授权需独立设计 |

生成注册表将 Android 与 macOS 的模块入口开放，继续排除 iOS、Web 和 Windows。入口开放只表示可进入教学页面并操作 BLE 流程；各平台的真实设备证据仍按步骤独立记录。macOS 的状态与扫描不能证明完整 GATT 闭环；Android 已验证上述 iQOO 外设的读取和主动断开，通知订阅仍待手工验证。

## 2026-09-30 接入更新

Windows 已按统一规则开放模块目录和 `/bluetooth-ble` 稳定路由；当前排除集合仅保留 iOS、Web。以上表格及说明记录 2026-09-29 的历史状态，Windows 构建与真实主机 BLE 验收仍为 PENDING，未标记平台 PASS。详见 [Windows 接入记录](BLE_WINDOWS_ADMISSION-20260930.md)。
