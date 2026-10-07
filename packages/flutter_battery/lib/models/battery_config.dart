import 'battery_info.dart';
import 'battery_health.dart';

class BatteryMonitorConfig {
  final bool monitorBatteryLevel;
  final bool monitorBatteryInfo;
  final int intervalMs;
  final int batteryInfoIntervalMs;
  final bool monitorBatteryHealth;
  final int batteryHealthIntervalMs;
  final bool enableDebounce;

  BatteryMonitorConfig({
    this.monitorBatteryLevel = true,
    this.monitorBatteryInfo = false,
    this.intervalMs = 1000,
    this.batteryInfoIntervalMs = 5000,
    this.monitorBatteryHealth = false,
    this.batteryHealthIntervalMs = 10000,
    this.enableDebounce = true,
  });
}

class BatteryLevelMonitorConfig {
  final bool enable;
  final int threshold;
  final String title;
  final String message;
  final int intervalMinutes;
  final bool useFlutterRendering;
  final Function(int)? onLowBattery;

  BatteryLevelMonitorConfig({
    required this.enable,
    this.threshold = 20,
    this.title = "电池电量低",
    this.message = "您的电池电量已经低于阈值，请及时充电",
    this.intervalMinutes = 15,
    this.useFlutterRendering = false,
    this.onLowBattery,
  });
}

class BatteryConfiguration {
  final BatteryMonitorConfig? monitorConfig;
  final BatteryLevelMonitorConfig? lowBatteryConfig;
  final Function(int batteryLevel)? onBatteryLevelChange;
  final Function(BatteryInfo info)? onBatteryInfoChange;
  final Function(BatteryHealth health)? onBatteryHealthChange;
  final Function(int batteryLevel)? onLowBattery;

  BatteryConfiguration({
    this.monitorConfig,
    this.lowBatteryConfig,
    this.onBatteryLevelChange,
    this.onBatteryInfoChange,
    this.onBatteryHealthChange,
    this.onLowBattery,
  });
}
