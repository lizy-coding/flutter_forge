# bluetooth_system_bridge

仅拥有系统蓝牙设置入口与 Android 已连接音频 profile 查询，不包装 universal_ble 的扫描/连接/GATT。平台接口可注入并有 token 校验；能力查询不抛出，操作返回独立 BluetoothSystemOutcome，unsupported/unavailable/permissionDenied/invalidData 与空设备列表区分。

Android FlutterPlugin 自注册原有 flutter_forge/bluetooth_system 通道，Activity/engine 退出结束查询，4秒原生期限回收 profile proxy，迟到 ServiceListener 仍关闭其 proxy；并发查询返回 request_in_progress。Dart 传输6秒后报告 unresolved，不声称系统设置动作已回滚。macOS/Windows 设置入口继续经 url_launcher，音频查询保持 Android 范围。

列表逐条解析：畸形记录保留 error 条目，其他设备不丢失；Forge 会显示该记录的错误原因。缺适配与蓝牙关闭不是空列表。平台支持范围由既有 ble_central 规则决定，本次未新增平台。
