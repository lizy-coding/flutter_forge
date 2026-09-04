# Android 端整体完整性评估与自测清单

日期：2026-09-03
目标设备：API 35 AOSP ATD，`emulator-5554`
屏幕：320x640dp，密度 160
应用包：`com.flutterforge.preview`

## 结论

当前 Android host、APK 构建、安装启动、单窗口导航、平台插件映射、移动端布局和 USB 原生通道具备运行基础；模拟器验收项已通过，真机能力项仍为 **PENDING**。

已修复：`/usb-detector` 和 `/status-management` 在 320dp 下的横向布局问题，并通过 API 35 emulator 集成复验。

## 自测清单

| 编号 | 场景 | 结果 | 证据/备注 |
| --- | --- | --- | --- |
| A01 | Android host 目录、Manifest、MainActivity | PASS | `apps/flutter_forge/android`；`singleTop`；`adjustResize` |
| A02 | Debug APK 构建 | PASS | `flutter build apk --debug` |
| A03 | APK 安装 | PASS | `adb install -r` 返回 `Success` |
| A04 | Activity 启动与首帧 | PASS | `Displayed`、`Fully drawn` |
| A05 | 进程存活与崩溃日志 | PASS | `pidof com.flutterforge.preview`；无 `FATAL EXCEPTION` |
| A06 | Android 单窗口导航策略 | PASS | `NavigationPolicy` 测试；单 Activity 前台任务 |
| A07 | 首页 320x640 渲染 | PASS | 已采集 emulator 截图；首页列表可见 |
| A08 | Android 文件选择器映射 | PASS | `file_picker_bridge` Android 测试 |
| A09 | Android USB MethodChannel | PASS | USB service 定向测试；APK 构建通过 |
| A10 | Android USB 无权限/可选字段回退 | PASS（代码级） | 原生端隐藏序列号并保留设备枚举 |
| A11 | 20 个可用模块逐个打开返回 | PASS | API 35 emulator，全部模块通过 |
| A12 | USB/状态管理页面 320dp 无溢出 | PASS | 修复 `usb-detector` 与 `status-management` 后通过 |
| A13 | 弹窗/列表嵌套路由 | PASS | API 35 emulator 独立及完整集成测试通过 |
| A14 | 键盘避让 | PENDING | 尚无输入型 Android 真实交互证据 |
| A15 | USB 真机权限弹窗与物理设备 | PENDING | emulator 无物理 USB 设备，需真机 |

## 已执行命令

```bash
flutter test test/modules/platform/usb_detector/usb_detector_test.dart \
  test/modules/platform/usb_detector/usb_detection_service_test.dart \
  test/modules/state/status_management/status_management_test.dart
flutter analyze
flutter build apk --debug
flutter test integration_test/app_test.dart -d emulator-5554
```

定向测试、静态分析、APK 构建和完整 Android 集成测试均通过。

## 下一步

1. 在 emulator 上补充首页滚动、返回链路和屏幕截图证据。
2. 增加键盘弹出时的真实 Android 交互验收。
3. 使用真实 Android 设备完成 USB 权限请求/拒绝/重新插拔验证。
