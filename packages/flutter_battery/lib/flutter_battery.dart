import 'package:flutter/foundation.dart';

import 'battery_monitoring.dart';
import 'flutter_battery_platform_interface.dart';
import 'src/battery_channel_contract.dart';
import 'src/platform_capabilities.dart';
import 'models/battery_info.dart';
import 'models/battery_health.dart';
import 'models/battery_config.dart';
export 'battery_widgets.dart';
export 'battery_monitoring.dart';
export 'battery_notifications.dart';
export 'peer_battery_service.dart';
export 'models/battery_info.dart';
export 'models/battery_health.dart';
export 'models/battery_config.dart';
export 'src/battery_channel_contract.dart';
export 'src/platform_capabilities.dart';

class FlutterBattery {
  Future<BatteryObservation> observe({BatteryObservationOptions? options}) =>
      FlutterBatteryPlatform.instance.observeBattery(
        options ?? BatteryObservationOptions(),
      );

  void clearBatteryCallbacks() =>
      FlutterBatteryPlatform.instance.clearBatteryCallbacks();

  /// 获取平台版本
  Future<String?> getPlatformVersion() {
    return FlutterBatteryPlatform.instance.getPlatformVersion();
  }

  Future<BatteryPlatformCapabilities> getPlatformCapabilities() {
    return FlutterBatteryPlatform.instance.getPlatformCapabilities();
  }

  Future<bool> isFeatureSupported(BatteryFeature feature) async {
    final capabilities = await getPlatformCapabilities();
    return capabilities.isSupported(feature);
  }

  /// 获取电池电量百分比
  Future<int?> getBatteryLevel() {
    return FlutterBatteryPlatform.instance.getBatteryLevel();
  }

  /// 获取电池完整信息
  Future<BatteryInfo> getBatteryInfo() async {
    final infoMap = await FlutterBatteryPlatform.instance.getBatteryInfo();
    return BatteryInfo.fromMap(infoMap);
  }

  /// 获取电池健康信息
  Future<BatteryHealth> getBatteryHealth() async {
    final healthMap = await FlutterBatteryPlatform.instance.getBatteryHealth();
    return BatteryHealth.fromMap(healthMap);
  }

  /// 获取电池优化建议
  Future<List<String>> getBatteryOptimizationTips() {
    return FlutterBatteryPlatform.instance.getBatteryOptimizationTips();
  }

  /// 获取电池信息流（原始数据）
  Stream<Map<String, dynamic>> get batteryStream {
    return FlutterBatteryPlatform.instance.batteryStream;
  }

  @visibleForTesting
  static int normalizeLevel(Map<String, dynamic> event) {
    if (event[BatteryPayloadKeys.type] ==
        BatteryEventTypes.batteryUnavailable) {
      return -1;
    }
    for (final key in [
      BatteryPayloadKeys.level,
      BatteryPayloadKeys.batteryLevel,
    ]) {
      final value = event[key];
      if (value is int && value >= 0 && value <= 100) return value;
    }
    return -1;
  }

  Stream<BatteryInfo> get batteryInfoStream {
    return FlutterBatteryPlatform.instance
        .batteryEvents(BatteryObservationOptions(samples: {BatterySample.info}))
        .where((event) {
          final type = event[BatteryPayloadKeys.type];
          return type == null || type == BatteryEventTypes.batteryInfo;
        })
        .map((event) {
          if (event[BatteryPayloadKeys.type] == BatteryEventTypes.batteryInfo) {
            return BatteryInfo.fromMap(event);
          }
          final level = FlutterBattery.normalizeLevel(event);
          final timestamp =
              event[BatteryPayloadKeys.timestamp] as int? ??
              DateTime.now().millisecondsSinceEpoch;
          return BatteryInfo(
            level: level,
            isCharging: event[BatteryPayloadKeys.isCharging] as bool? ?? false,
            temperature:
                (event[BatteryPayloadKeys.temperature] as num?)?.toDouble() ??
                0.0,
            voltage:
                (event[BatteryPayloadKeys.voltage] as num?)?.toDouble() ?? 0.0,
            state: level < 0
                ? BatteryState.UNKNOWN
                : level <= 20
                ? BatteryState.LOW
                : BatteryState.NORMAL,
            timestamp: timestamp,
          );
        });
  }

  Stream<BatteryHealth> get batteryHealthStream {
    return FlutterBatteryPlatform.instance
        .batteryEvents(
          BatteryObservationOptions(samples: {BatterySample.health}),
        )
        .where(
          (event) =>
              event[BatteryPayloadKeys.type] == BatteryEventTypes.batteryHealth,
        )
        .map(
          (event) => BatteryHealth.fromMap(Map<String, dynamic>.from(event)),
        );
  }

  /// 配置所有电池相关回调
  ///
  /// 一次性设置所有回调，减少多次调用接口
  /// [onLowBattery] 低电量回调
  /// [onBatteryLevelChange] 电池电量变化回调
  /// [onBatteryInfoChange] 电池信息变化回调
  void configureBatteryCallbacks({
    Function(int batteryLevel)? onLowBattery,
    Function(int batteryLevel)? onBatteryLevelChange,
    Function(BatteryInfo info)? onBatteryInfoChange,
    Function(BatteryHealth health)? onBatteryHealthChange,
  }) {
    FlutterBatteryPlatform.instance.configureBatteryCallbacks(
      onLowBattery: onLowBattery,
      onBatteryLevelChange: onBatteryLevelChange,
      onBatteryInfoChange: onBatteryInfoChange != null
          ? (infoMap) => onBatteryInfoChange(BatteryInfo.fromMap(infoMap))
          : null,
      onBatteryHealthChange: onBatteryHealthChange != null
          ? (healthMap) =>
                onBatteryHealthChange(BatteryHealth.fromMap(healthMap))
          : null,
    );
  }

  /// 设置电池电量推送间隔和防抖动
  @Deprecated('请使用configureBatteryMonitor方法代替')
  Future<bool?> setPushInterval({
    required int intervalMs,
    bool enableDebounce = true,
  }) {
    return FlutterBatteryPlatform.instance.setPushInterval(
      intervalMs: intervalMs,
      enableDebounce: enableDebounce,
    );
  }

  /// 设置电池电量变化监听
  @Deprecated('请使用configureBatteryCallbacks方法代替')
  void setBatteryLevelChangeListener(
    Function(int batteryLevel) onBatteryLevelChanged,
  ) {
    FlutterBatteryPlatform.instance.setBatteryLevelChangeCallback(
      onBatteryLevelChanged,
    );
  }

  /// 设置电池信息变化监听
  @Deprecated('请使用configureBatteryCallbacks方法代替')
  void setBatteryInfoChangeListener(
    Function(BatteryInfo info) onBatteryInfoChanged,
  ) {
    FlutterBatteryPlatform.instance.setBatteryInfoChangeCallback((
      Map<String, dynamic> infoMap,
    ) {
      final info = BatteryInfo.fromMap(infoMap);
      onBatteryInfoChanged(info);
    });
  }

  /// 配置电池监听
  ///
  /// 一次性配置电池监听选项，减少多次调用接口
  /// [config] 监听配置，包含监听类型、间隔等
  /// 返回一个包含各项配置是否成功的Map
  Future<Map<String, bool>> configureBatteryMonitor(
    BatteryMonitorConfig config,
  ) async {
    return FlutterBatteryPlatform.instance.configureBatteryMonitor(
      monitorBatteryLevel: config.monitorBatteryLevel,
      monitorBatteryInfo: config.monitorBatteryInfo,
      monitorBatteryHealth: config.monitorBatteryHealth,
      intervalMs: config.intervalMs,
      batteryInfoIntervalMs: config.batteryInfoIntervalMs,
      batteryHealthIntervalMs: config.batteryHealthIntervalMs,
      enableDebounce: config.enableDebounce,
    );
  }

  /// 开始监听电池电量变化（建议使用configureBatteryMonitor替代）
  @Deprecated('请使用configureBatteryMonitor方法代替')
  Future<bool?> startBatteryLevelListening() {
    return FlutterBatteryPlatform.instance.startBatteryLevelListening();
  }

  /// 停止监听电池电量变化（建议使用configureBatteryMonitor替代）
  @Deprecated('请使用configureBatteryMonitor方法代替')
  Future<bool?> stopBatteryLevelListening() {
    return FlutterBatteryPlatform.instance.stopBatteryLevelListening();
  }

  /// 开始监听电池信息变化（建议使用configureBatteryMonitor替代）
  @Deprecated('请使用configureBatteryMonitor方法代替')
  Future<bool?> startBatteryInfoListening({int intervalMs = 5000}) {
    return FlutterBatteryPlatform.instance.startBatteryInfoListening(
      intervalMs: intervalMs,
    );
  }

  /// 停止监听电池信息变化（建议使用configureBatteryMonitor替代）
  @Deprecated('请使用configureBatteryMonitor方法代替')
  Future<bool?> stopBatteryInfoListening() {
    return FlutterBatteryPlatform.instance.stopBatteryInfoListening();
  }

  /// 配置电池低电量监控
  ///
  /// 一次性配置低电量监控，可启用或停用
  /// [config] 低电量监控配置
  /// 返回配置是否成功
  Future<bool?> configureBatteryMonitoring(BatteryLevelMonitorConfig config) {
    return FlutterBatteryPlatform.instance.configureBatteryMonitoring(
      enable: config.enable,
      threshold: config.threshold,
      title: config.title,
      message: config.message,
      intervalMinutes: config.intervalMinutes,
      useFlutterRendering: config.useFlutterRendering,
      onLowBattery: config.onLowBattery,
    );
  }

  /// 设置电池低电量阈值监控（建议使用configureBatteryMonitoring替代）
  @Deprecated('请使用configureBatteryMonitoring方法代替')
  Future<bool?> setBatteryLevelThreshold({
    required int threshold,
    required String title,
    required String message,
    int intervalMinutes = 15,
    bool useFlutterRendering = false,
    Function(int batteryLevel)? onLowBattery,
  }) {
    if (useFlutterRendering && onLowBattery != null) {
      FlutterBatteryPlatform.instance.setLowBatteryCallback(onLowBattery);
    }

    return FlutterBatteryPlatform.instance.setBatteryLevelThreshold(
      threshold: threshold,
      title: title,
      message: message,
      intervalMinutes: intervalMinutes,
      useFlutterRendering: useFlutterRendering,
      onLowBattery: onLowBattery,
    );
  }

  /// 停止电池电量监控（建议使用configureBatteryMonitoring替代）
  @Deprecated('请使用configureBatteryMonitoring方法代替')
  Future<bool?> stopBatteryMonitoring() {
    return FlutterBatteryPlatform.instance.stopBatteryMonitoring();
  }

  /// 发送通知
  ///
  /// 统一的通知发送方法，支持即时或延迟发送
  /// [title] 通知标题
  /// [message] 通知内容
  /// [delay] 延迟分钟数，0表示立即发送
  Future<bool?> sendNotification({
    required String title,
    required String message,
    int delay = 0,
  }) {
    return FlutterBatteryPlatform.instance.sendNotification(
      title: title,
      message: message,
      delay: delay,
    );
  }

  /// 调度一个延迟通知（建议使用sendNotification替代）
  @Deprecated('请使用sendNotification方法代替')
  Future<bool?> scheduleNotification({
    required String title,
    required String message,
    int delayMinutes = 1,
  }) {
    return FlutterBatteryPlatform.instance.scheduleNotification(
      title: title,
      message: message,
      delayMinutes: delayMinutes,
    );
  }

  /// 立即显示一个通知（建议使用sendNotification替代）
  @Deprecated('请使用sendNotification方法代替')
  Future<bool?> showNotification({
    required String title,
    required String message,
  }) {
    return FlutterBatteryPlatform.instance.showNotification(
      title: title,
      message: message,
    );
  }

  /// 一次性配置所有电池相关设置
  ///
  /// 高级API，整合了监控、回调和低电量设置
  /// [config] 完整的电池配置
  /// 返回配置结果，包含各项配置是否成功的信息
  Future<Map<String, dynamic>> configureBattery(
    BatteryConfiguration config,
  ) async {
    final result = <String, dynamic>{};

    // 1. 设置回调
    if (config.onBatteryLevelChange != null ||
        config.onBatteryInfoChange != null ||
        config.onBatteryHealthChange != null ||
        config.onLowBattery != null) {
      configureBatteryCallbacks(
        onBatteryLevelChange: config.onBatteryLevelChange,
        onBatteryInfoChange: config.onBatteryInfoChange,
        onBatteryHealthChange: config.onBatteryHealthChange,
        onLowBattery: config.onLowBattery,
      );

      result['callbacksConfigured'] = true;
    }

    // 2. 配置电池监听
    if (config.monitorConfig != null) {
      result['monitoringResults'] = await configureBatteryMonitor(
        config.monitorConfig!,
      );
    }

    // 3. 配置低电量监控
    if (config.lowBatteryConfig != null) {
      result['lowBatteryMonitoring'] = await configureBatteryMonitoring(
        config.lowBatteryConfig!,
      );
    }

    return result;
  }
}
