# Flutter Battery — 0.1.0-dev.1

第一阶段支持 Android/macOS 的类型化电池读取与独立观察。目前为未发布的破坏性重构版本；策略、状态矩阵和后续发布验收见 [PHASE1_API](docs/PHASE1_API.md)。

```dart
import 'package:flutter_battery/flutter_battery.dart';

final battery = FlutterBattery();
final capabilities = await battery.capabilities();
final reading = await battery.read(sample: BatterySample.info);
if (reading.isAvailable) {
  print(reading.value!.level); // 真实 0% 保留。
  print(reading.value!.temperatureCelsius); // 未知字段是 null。
} else {
  print('${reading.status}: ${reading.reason!.code}');
}
final opened = await battery.observe(
  options: BatteryObservationOptions(samples: {BatterySample.level, BatterySample.health}),
);
if (opened.isAvailable) {
  final observation = opened.value!;
  final subscription = observation.events.listen((result) {
    // result.sample 区分类型；status 区分成功、无电池、未知与运行失败。
  });
  final closed = await observation.close(); // 幂等，检查 status。
  await subscription.cancel();
}
```

核心操作为 `capabilities()`、`read()`、`sample()` 与 `watchChanges()`；`observe()` 仅保留为兼容路由。观察对象提供 `events`、`current`、`state` 和 `close()`。同一原生传输合并采样需求，每个会话独立控制类型、间隔与去重，关闭不影响其他消费者。间隔范围为 100..3600000 ms。

所有运行结果区分 pending、available、noBattery、unknown、unsupported、permissionDenied、unavailable、invalidData、timedOut、failed、closed。无效调用参数抛出 ArgumentError；原生运行失败不泄漏原始异常。available 才有值，可选字段保持空；不支持与原生不可达不同，健康未知与没有电池不同。操作默认上限 5 秒，可配置为不超过 60 秒；关闭后不回填数据。订阅暂停只暂停该订阅交付，采样需求由会话 close 释放。

通知、BLE、peer 与 widgets 为独立入口，不属于第一阶段发布承诺。宿主负责可选权限声明与申请。`legacy_flutter_battery.dart` 中的 LegacyFlutterBattery 保留旧演示迁移用途，不属于第一阶段稳定 API；旧全面示例位于 `example/lib/legacy_main.dart`，主要示例已改为核心状态展示。

Forge 使用仓库内 `packages/flutter_battery` 依赖。同步脚本默认只检查，发现 Forge 管理文件的本地变更即停止，避免覆盖修复：

```sh
python3 scripts/sync_forge_dependency.py --forge-root /path/to/flutter_forge
python3 scripts/sync_forge_dependency.py --forge-root /path/to/flutter_forge --apply
```

测试、原生构建、设备运行与发布验收分别记录；仓库快照不代表发布版本。未完成 Android 真机、真实无电池宿主、完整生命周期与最低工具链验收前，不声明已达到对外发布状态。

供电来源与充电行为分开表示：`powerSource` 为 external/battery/unknown，`chargeState` 为 charging/full/notCharging/discharging/unknown。接入 AC 但因充电限制等原因未充电时，isCharging=false、powerSource=external、chargeState=notCharging；不能显示为使用电池。电量未变时，供电或充电状态变化仍会交付，限频窗口内保留最后一个样本。

容量诊断通过 `reading.value?.capacity` 获取，包含当前/满充/设计容量、循环次数、单位与来源。字段缺失保持空。单位为 unspecified 或 percent 时不计算满充相对设计容量百分比，避免混合量纲。当前可用性与后续平台扩展边界见 [USABILITY_AND_EXTENSION](docs/USABILITY_AND_EXTENSION.md)。

### 定期采样与系统变化通知

```dart
final sampler = await battery.sample(
  options: BatterySamplingOptions(samples: {BatterySample.level}, levelIntervalMs: 1000),
);
final watcher = await battery.watchChanges(
  options: BatteryChangeOptions(samples: {BatterySample.level}),
);
```

单个订阅的选项类型互斥；两类订阅可以同时存在并分别 close。采样按间隔重复交付未变数值；变化通知由 macOS IOPS 通知 / Android 电池广播驱动，不创建采样定时器。`delivery` 标记 initial 基线、sample 定期样本、change 真实变化。电量变化仅比较百分比与可用性；需要供电/充电变化时选择 info；health 只比较健康条件与可用性，不因电量或旧建议文案变化推送。时间戳和字典顺序不是变化。系统事件可能合并变化，不保证捕获每个硬件中间态。

`observe()` 与 `BatteryObservationOptions()` 保留为采样兼容入口；新代码使用上述两种明确 API。旧 `debounceLevel` 已移除，不能通过采样去重布尔值模拟变化通知。
