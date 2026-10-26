# flutter_biometric

Forge workspace 内部认证插件，来源与许可证现状见 [UPSTREAM.md](UPSTREAM.md)。Android 宿主使用 FlutterFragmentActivity；macOS 使用 LocalAuthentication。平台入口由 Forge 注册表决定。

`queryCapabilities()` 不抛出；缺少适配、查询失败或超时返回 none。`strongAvailable` / `weakAvailable` 表示强度可认证性，不指定传感器。Android 的 fingerprintAvailable/faceAvailable 仅为硬件线索，sensorEnrollmentKnown=false，不构造逐类 enrolledTypes；macOS 可在查询后报告 Touch ID 类型。

```dart
final biometric = FlutterBiometric();
final caps = await biometric.queryCapabilities();
if (caps.strongAvailable) {
  final result = await biometric.authenticate(
    const BiometricAuthRequest(reason: '验证身份'),
  );
  // result.value?.method: biometric / deviceCredential / unknown
}
await biometric.close();
```

一次实例拥有一个认证操作；重复请求返回 authentication_in_progress。操作 ID 随请求传到原生，cancel/close 仅取消该实例持有的 ID；close 幂等，关闭后的新操作返回 owner_closed。正常认证不套用电池采样定时器或任意认证超时；退出 session 主动取消，原生操作持有者结束唯一结果并停止 BiometricPrompt/LAContext，迟到回调不会覆盖下一次操作。能力查询等待上限10秒，取消传输等待上限5秒。

成功与方式可知性分离：macOS strongWithCredential 使用原有 deviceOwnerAuthentication 策略，成功时方式为 unknown；不推断用户实际采用密码还是 Touch ID。Android 使用 androidx 命名常量映射。API29及以下仍拒绝 strongWithCredential 组合（combination_unsupported），没有改变允许或回退策略。

技术迁移：usedDeviceCredential 现在是 bool?（unknown 返回 null），调用方应优先 switch method；fromMap 接受 Object? 并严格校验状态、原因和成功方式。旧 bool 响应仍可解码，但缺失或错误类型不能当作生物识别成功。

Dart 回归：`flutter test --no-pub`。原生 JUnit：在宿主 android 目录运行 `./gradlew :flutter_biometric:testDebugUnitTest`。macOS 无提示 fake 原生回归源码为 `test/native/main.swift`，执行方式见本轮实施报告。真实认证与每引擎窗口验收另行记录。
