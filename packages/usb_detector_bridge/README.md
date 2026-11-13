# usb_detector_bridge

Android USB 设备枚举桥接包：`usb_detector` 学习模块的平台适配层。

遵循 `flutter_battery` 的平台能力桥接模板（ADR 0019）：

- `UsbDetectorPlatform` 平台接口（`plugin_platform_interface` token 校验，测试可替换实例）。
- `MethodChannelUsbDetector` Android 适配器：非 Android 宿主与缺失原生插件都降级为类型化结果，不抛异常。
- `UsbDetectionOutcome<T>` 带原因码的结果类型，只有 `available` 携带值；单条设备解析失败降级为 error 条目，不吞掉整张列表。
- `queryCapabilities()` 能力探测永不抛出；无适配器时返回 `UsbDetectionCapabilities.none()`。
- 原生侧 `UsbDetectorBridgePlugin` 自注册 `usb_detector/usb` 通道，宿主 App 不再手动接线。

```dart
final bridge = UsbDetectorBridge();
final capabilities = await bridge.queryCapabilities();
if (capabilities.isSupported) {
  final outcome = await bridge.listDevices();
}
```

模块 UI 只消费接口与结果类型；平台矩阵由 `tool/agent_indexes/availability.js` 的能力规则推导。
