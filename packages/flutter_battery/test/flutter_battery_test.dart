import 'dart:io';

import 'package:flutter_battery/flutter_battery_platform_interface.dart';
import 'package:flutter_battery/flutter_battery.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:flutter/widgets.dart';

class MockFlutterBatteryPlatform extends FlutterBatteryPlatform
    with MockPlatformInterfaceMixin {
  @override
  Stream<Map<String, dynamic>> batteryEvents(
    BatteryObservationOptions options,
  ) => batteryStream;

  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  Future<BatteryPlatformCapabilities> getPlatformCapabilities() => Future.value(
    const BatteryPlatformCapabilities(
      features: {
        BatteryFeature.batteryLevel: true,
        BatteryFeature.batteryInfo: true,
        BatteryFeature.batteryHealth: true,
        BatteryFeature.batteryLevelStream: true,
        BatteryFeature.batteryInfoStream: true,
        BatteryFeature.batteryHealthStream: true,
        BatteryFeature.lowBatteryMonitoring: true,
        BatteryFeature.nativeNotifications: true,
        BatteryFeature.scheduledNotifications: true,
        BatteryFeature.blePeerSync: true,
        BatteryFeature.iotExampleBridge: true,
      },
    ),
  );

  @override
  Future<bool?> scheduleNotification({
    required String title,
    required String message,
    int delayMinutes = 1,
  }) {
    return Future.value(true);
  }

  @override
  Future<bool?> showNotification({
    required String title,
    required String message,
  }) {
    return Future.value(true);
  }

  @override
  Future<int?> getBatteryLevel() {
    return Future.value(75);
  }

  @override
  Future<bool?> setBatteryLevelThreshold({
    required int threshold,
    required String title,
    required String message,
    int intervalMinutes = 15,
    bool useFlutterRendering = false,
    void Function(int)? onLowBattery,
  }) {
    return Future.value(true);
  }

  @override
  void setLowBatteryCallback(Function(int batteryLevel) callback) {}

  @override
  Future<bool?> stopBatteryMonitoring() {
    return Future.value(true);
  }

  @override
  void setBatteryLevelChangeCallback(Function(int batteryLevel) callback) {}

  @override
  Future<bool?> startBatteryLevelListening() {
    return Future.value(true);
  }

  @override
  Future<bool?> stopBatteryLevelListening() {
    return Future.value(true);
  }

  @override
  Stream<Map<String, dynamic>> get batteryStream {
    return Stream.fromIterable([
      {'batteryLevel': 75, 'timestamp': DateTime.now().millisecondsSinceEpoch},
      {
        'type': 'BATTERY_HEALTH',
        'state': 'GOOD',
        'statusLabel': '电池状态良好',
        'isGood': true,
        'temperature': 30.0,
        'voltage': 4.1,
        'level': 80,
        'isCharging': false,
        'riskLevel': 'LOW',
        'recommendations': ['测试建议'],
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
      {
        'type': 'BATTERY_INFO',
        'level': 65,
        'isCharging': true,
        'temperature': 28.0,
        'voltage': 4.0,
        'state': 'CHARGING',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    ]);
  }

  @override
  Future<bool?> setPushInterval({
    required int intervalMs,
    bool enableDebounce = true,
  }) {
    return Future.value(true);
  }

  @override
  Future<Map<String, dynamic>> getBatteryInfo() {
    return Future.value({
      'level': 75,
      'isCharging': false,
      'temperature': 30.5,
      'voltage': 4.2,
      'state': 'NORMAL',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  @override
  Future<Map<String, dynamic>> getBatteryHealth() {
    return Future.value({
      'state': 'GOOD',
      'statusLabel': '电池状态良好',
      'isGood': true,
      'temperature': 30.0,
      'voltage': 4.1,
      'level': 80,
      'isCharging': false,
      'riskLevel': 'LOW',
      'recommendations': ['保持良好的充电习惯'],
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  @override
  Future<List<String>> getBatteryOptimizationTips() {
    return Future.value(['关闭后台应用', '降低屏幕亮度', '启用电池优化模式']);
  }

  @override
  void setBatteryInfoChangeCallback(
    Function(Map<String, dynamic> batteryInfo) callback,
  ) {}

  @override
  void setBatteryHealthChangeCallback(
    Function(Map<String, dynamic> batteryHealth) callback,
  ) {}

  @override
  Future<bool?> startBatteryInfoListening({int intervalMs = 5000}) {
    return Future.value(true);
  }

  @override
  Future<bool?> stopBatteryInfoListening() {
    return Future.value(true);
  }

  @override
  Future<bool?> startBatteryHealthListening({int intervalMs = 10000}) {
    return Future.value(true);
  }

  @override
  Future<bool?> stopBatteryHealthListening() {
    return Future.value(true);
  }

  @override
  Future<bool?> sendNotification({
    required String title,
    required String message,
    int delay = 0,
  }) {
    return Future.value(true);
  }

  @override
  Future<Map<String, bool>> configureBatteryMonitor({
    bool monitorBatteryLevel = false,
    bool monitorBatteryInfo = false,
    bool monitorBatteryHealth = false,
    int intervalMs = 1000,
    int batteryInfoIntervalMs = 5000,
    int batteryHealthIntervalMs = 10000,
    bool enableDebounce = true,
  }) {
    return Future.value({
      'setPushInterval': true,
      'batteryLevelMonitor': true,
      'batteryInfoMonitor': true,
      'batteryHealthMonitor': monitorBatteryHealth,
    });
  }

  @override
  void configureBatteryCallbacks({
    Function(int batteryLevel)? onLowBattery,
    Function(int batteryLevel)? onBatteryLevelChange,
    Function(Map<String, dynamic> batteryInfo)? onBatteryInfoChange,
    Function(Map<String, dynamic> batteryHealth)? onBatteryHealthChange,
  }) {}

  @override
  Future<bool?> configureBatteryMonitoring({
    required bool enable,
    int threshold = 20,
    String title = "电池电量低",
    String message = "您的电池电量已经低于阈值，请及时充电",
    int intervalMinutes = 15,
    bool useFlutterRendering = false,
    Function(int)? onLowBattery,
  }) {
    return Future.value(true);
  }
}

class SendNotificationMock extends MockFlutterBatteryPlatform {
  bool showNotificationCalled = false;
  bool scheduleNotificationCalled = false;
  String? lastTitle;
  String? lastMessage;

  @override
  Future<bool?> showNotification({
    required String title,
    required String message,
  }) async {
    showNotificationCalled = true;
    lastTitle = title;
    lastMessage = message;
    return true;
  }

  @override
  Future<bool?> scheduleNotification({
    required String title,
    required String message,
    int delayMinutes = 1,
  }) async {
    scheduleNotificationCalled = true;
    lastTitle = title;
    lastMessage = message;
    return true;
  }

  @override
  Future<bool?> sendNotification({
    required String title,
    required String message,
    int delay = 0,
  }) async {
    if (delay <= 0) {
      return showNotification(title: title, message: message);
    } else {
      return scheduleNotification(
        title: title,
        message: message,
        delayMinutes: delay,
      );
    }
  }
}

class CallbackCaptureMock extends MockFlutterBatteryPlatform {
  Function(Map<String, dynamic>)? _capturedBatteryHealthCallback;
  Function(Map<String, dynamic>)? _capturedBatteryInfoCallback;

  @override
  void configureBatteryCallbacks({
    Function(int batteryLevel)? onLowBattery,
    Function(int batteryLevel)? onBatteryLevelChange,
    Function(Map<String, dynamic> batteryInfo)? onBatteryInfoChange,
    Function(Map<String, dynamic> batteryHealth)? onBatteryHealthChange,
  }) {
    if (onBatteryInfoChange != null) {
      setBatteryInfoChangeCallback(onBatteryInfoChange);
    }
    if (onBatteryHealthChange != null) {
      setBatteryHealthChangeCallback(onBatteryHealthChange);
    }
  }

  @override
  void setBatteryInfoChangeCallback(
    Function(Map<String, dynamic> batteryInfo) callback,
  ) {
    _capturedBatteryInfoCallback = callback;
  }

  @override
  void setBatteryHealthChangeCallback(
    Function(Map<String, dynamic> batteryHealth) callback,
  ) {
    _capturedBatteryHealthCallback = callback;
  }

  bool get hasInfoCallback => _capturedBatteryInfoCallback != null;
  bool get hasHealthCallback => _capturedBatteryHealthCallback != null;

  void invokeInfoCallback(Map<String, dynamic> data) {
    _capturedBatteryInfoCallback?.call(data);
  }

  void invokeHealthCallback(Map<String, dynamic> data) {
    _capturedBatteryHealthCallback?.call(data);
  }
}

class StreamMockFlutterBatteryPlatform extends MockFlutterBatteryPlatform {
  StreamMockFlutterBatteryPlatform(this._events);

  final List<Map<String, dynamic>> _events;

  @override
  Stream<Map<String, dynamic>> get batteryStream =>
      Stream.fromIterable(_events);
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final FlutterBatteryPlatform initialPlatform =
      FlutterBatteryPlatform.instance;

  setUp(() {
    final fakePlatform = MockFlutterBatteryPlatform();
    FlutterBatteryPlatform.instance = fakePlatform;
  });

  test('Default platform is FlutterBatteryPlatform', () {
    expect(initialPlatform, isInstanceOf<FlutterBatteryPlatform>());
  });

  test('getPlatformVersion returns from mock', () async {
    expect(await FlutterBatteryPlatform.instance.getPlatformVersion(), '42');
  });

  test('getBatteryLevel returns from mock', () async {
    expect(await FlutterBatteryPlatform.instance.getBatteryLevel(), 75);
  });

  test('getPlatformCapabilities returns capabilities', () async {
    final caps = await FlutterBatteryPlatform.instance
        .getPlatformCapabilities();
    expect(caps, isA<BatteryPlatformCapabilities>());
    expect(caps.isSupported(BatteryFeature.batteryLevel), true);
    expect(caps.isSupported(BatteryFeature.blePeerSync), true);
  });

  test('FlutterBattery.getPlatformCapabilities delegates correctly', () async {
    final plugin = FlutterBattery();
    final caps = await plugin.getPlatformCapabilities();
    expect(caps.isSupported(BatteryFeature.batteryLevel), true);
    expect(caps.isSupported(BatteryFeature.batteryInfo), true);
  });

  test('FlutterBattery.isFeatureSupported delegates correctly', () async {
    final plugin = FlutterBattery();
    expect(await plugin.isFeatureSupported(BatteryFeature.batteryLevel), true);
  });

  test('scheduleNotification returns true', () async {
    expect(
      await FlutterBatteryPlatform.instance.scheduleNotification(
        title: 'test',
        message: 'hello',
        delayMinutes: 5,
      ),
      true,
    );
  });

  test('showNotification returns true', () async {
    expect(
      await FlutterBatteryPlatform.instance.showNotification(
        title: 'test',
        message: 'world',
      ),
      true,
    );
  });

  test('setBatteryLevelThreshold returns true', () async {
    expect(
      await FlutterBatteryPlatform.instance.setBatteryLevelThreshold(
        threshold: 30,
        title: 'low',
        message: 'charging soon',
      ),
      true,
    );
  });

  test('stopBatteryMonitoring returns true', () async {
    expect(await FlutterBatteryPlatform.instance.stopBatteryMonitoring(), true);
  });

  test('sendNotification returns true', () async {
    expect(
      await FlutterBatteryPlatform.instance.sendNotification(
        title: 'test',
        message: 'notification',
        delay: 2,
      ),
      true,
    );
  });

  test('configureBatteryMonitor returns expected map', () async {
    final result = await FlutterBatteryPlatform.instance
        .configureBatteryMonitor(
          monitorBatteryLevel: true,
          monitorBatteryInfo: true,
          intervalMs: 2000,
          batteryInfoIntervalMs: 10000,
          enableDebounce: true,
        );
    expect(result, isA<Map<String, bool>>());
    expect(result['setPushInterval'], true);
    expect(result['batteryLevelMonitor'], true);
    expect(result['batteryInfoMonitor'], true);
  });

  test('configureBatteryMonitoring returns true', () async {
    expect(
      await FlutterBatteryPlatform.instance.configureBatteryMonitoring(
        enable: true,
        threshold: 15,
        title: '低电量提醒',
        message: '电池电量低于15%',
        intervalMinutes: 30,
      ),
      true,
    );
  });

  test('getBatteryInfo returns valid map', () async {
    final batteryInfo = await FlutterBatteryPlatform.instance.getBatteryInfo();
    expect(batteryInfo, isA<Map<String, dynamic>>());
    expect(batteryInfo['level'], 75);
    expect(batteryInfo['isCharging'], false);
    expect(batteryInfo['temperature'], 30.5);
    expect(batteryInfo['voltage'], 4.2);
    expect(batteryInfo['state'], 'NORMAL');
    expect(batteryInfo['timestamp'], isA<int>());
  });

  test('getBatteryHealth returns valid map', () async {
    final health = await FlutterBatteryPlatform.instance.getBatteryHealth();
    expect(health['state'], 'GOOD');
    expect(health['statusLabel'], isA<String>());
    expect(health['recommendations'], isA<List<String>>());
  });

  test('getBatteryOptimizationTips returns non-empty list', () async {
    final tips = await FlutterBatteryPlatform.instance
        .getBatteryOptimizationTips();
    expect(tips, isA<List<String>>());
    expect(tips, isNotEmpty);
    expect(tips.length, 3);
  });

  test('batteryStream emits valid data', () async {
    final batteryEvent =
        await FlutterBatteryPlatform.instance.batteryStream.first;
    expect(batteryEvent, isA<Map<String, dynamic>>());
    expect(batteryEvent['batteryLevel'], 75);
    expect(batteryEvent['timestamp'], isA<int>());
  });

  test('batteryHealthStream emits BatteryHealth', () async {
    final plugin = FlutterBattery();
    final health = await plugin.batteryHealthStream.first;
    expect(health.state, BatteryHealthState.good);
    expect(health.recommendations, isNotEmpty);
  });

  test('batteryInfoStream_accepts_level_key', () async {
    FlutterBatteryPlatform.instance = StreamMockFlutterBatteryPlatform([
      {
        BatteryPayloadKeys.type: BatteryEventTypes.batteryInfo,
        BatteryPayloadKeys.level: 64,
        BatteryPayloadKeys.isCharging: false,
        BatteryPayloadKeys.temperature: 29.0,
        BatteryPayloadKeys.voltage: 4.0,
        BatteryPayloadKeys.state: 'NORMAL',
        BatteryPayloadKeys.timestamp: 123,
      },
    ]);
    final plugin = FlutterBattery();
    final info = await plugin.batteryInfoStream.first;
    expect(info.level, 64);
  });

  test('batteryInfoStream_accepts_batteryLevel_key', () async {
    FlutterBatteryPlatform.instance = StreamMockFlutterBatteryPlatform([
      {
        BatteryPayloadKeys.type: BatteryEventTypes.batteryInfo,
        BatteryPayloadKeys.batteryLevel: 72,
        BatteryPayloadKeys.isCharging: true,
        BatteryPayloadKeys.temperature: 31.0,
        BatteryPayloadKeys.voltage: 4.2,
        BatteryPayloadKeys.state: 'CHARGING',
        BatteryPayloadKeys.timestamp: 456,
      },
    ]);
    final plugin = FlutterBattery();
    final info = await plugin.batteryInfoStream.first;
    expect(info.level, 72);
    expect(info.state, BatteryState.CHARGING);
  });

  test('batteryHealthStream_accepts_macos_payload', () async {
    FlutterBatteryPlatform.instance = StreamMockFlutterBatteryPlatform([
      {
        BatteryPayloadKeys.type: BatteryEventTypes.batteryHealth,
        BatteryPayloadKeys.state: 'GOOD',
        BatteryPayloadKeys.statusLabel: 'Good',
        BatteryPayloadKeys.isGood: true,
        BatteryPayloadKeys.riskLevel: 'LOW',
        BatteryPayloadKeys.recommendations: <String>['OK'],
        BatteryPayloadKeys.temperature: 30.0,
        BatteryPayloadKeys.voltage: 4.1,
        BatteryPayloadKeys.batteryLevel: 88,
        BatteryPayloadKeys.timestamp: 789,
      },
    ]);
    final plugin = FlutterBattery();
    final health = await plugin.batteryHealthStream.first;
    expect(health.state, BatteryHealthState.good);
    expect(health.level, 88);
  });

  test('method_channel_payload_constants_match_contract', () {
    final contract = File(
      'integration/channel/contracts/channel_contract.yaml',
    ).readAsStringSync();

    expect(contract, contains('name: ${BatteryChannelNames.methodChannel}'));
    expect(contract, contains('name: ${BatteryChannelNames.eventChannel}'));
    expect(contract, contains('name: ${BatteryChannelNames.peerMethods}'));
    expect(contract, contains('name: ${BatteryChannelNames.peerEvents}'));
    expect(contract, contains(BatteryEventTypes.batteryLevel));
    expect(contract, contains(BatteryEventTypes.batteryInfo));
    expect(contract, contains(BatteryEventTypes.batteryHealth));
    expect(contract, contains(BatteryEventTypes.batteryUnavailable));
    expect(contract, contains(BatteryEventTypes.batteryError));
    expect(contract, contains('- ${BatteryPayloadKeys.batteryLevel}'));
    expect(contract, contains('- ${BatteryPayloadKeys.level}'));
    expect(contract, contains('- ${BatteryPayloadKeys.timestamp}'));
  });

  test('configureBattery aggregates results', () async {
    final plugin = FlutterBattery();
    final result = await plugin.configureBattery(
      BatteryConfiguration(
        monitorConfig: BatteryMonitorConfig(
          monitorBatteryLevel: true,
          monitorBatteryInfo: true,
          monitorBatteryHealth: true,
        ),
        lowBatteryConfig: BatteryLevelMonitorConfig(enable: true),
        onBatteryLevelChange: (level) {},
        onBatteryInfoChange: (info) {},
        onBatteryHealthChange: (health) {},
        onLowBattery: (level) {},
      ),
    );
    expect(result['callbacksConfigured'], true);
    expect(result['monitoringResults'], isA<Map<String, bool>>());
    expect(result['lowBatteryMonitoring'], true);
  });

  test('sendNotification_with_delay_zero_calls_showNotification', () async {
    final mock = SendNotificationMock();
    FlutterBatteryPlatform.instance = mock;
    await FlutterBatteryPlatform.instance.sendNotification(
      title: 'test',
      message: 'immediate',
      delay: 0,
    );
    expect(mock.showNotificationCalled, true);
    expect(mock.scheduleNotificationCalled, false);
    expect(mock.lastTitle, 'test');
    expect(mock.lastMessage, 'immediate');
  });

  test(
    'sendNotification_with_delay_positive_calls_scheduleNotification',
    () async {
      final mock = SendNotificationMock();
      FlutterBatteryPlatform.instance = mock;
      await FlutterBatteryPlatform.instance.sendNotification(
        title: 'scheduled',
        message: 'later',
        delay: 5,
      );
      expect(mock.scheduleNotificationCalled, true);
      expect(mock.showNotificationCalled, false);
      expect(mock.lastTitle, 'scheduled');
      expect(mock.lastMessage, 'later');
    },
  );

  test('normalizeLevel_returns_level_key_when_present', () {
    expect(FlutterBattery.normalizeLevel({'level': 75}), 75);
  });

  test('normalizeLevel_returns_batteryLevel_key_when_no_level', () {
    expect(FlutterBattery.normalizeLevel({'batteryLevel': 60}), 60);
  });

  test('normalizeLevel_prefers_level_over_batteryLevel', () {
    expect(
      FlutterBattery.normalizeLevel({'level': 80, 'batteryLevel': 70}),
      80,
    );
  });

  test('normalizeLevel_returns_unknown_for_unavailable_type', () {
    expect(
      FlutterBattery.normalizeLevel({
        'type': 'BATTERY_UNAVAILABLE',
        'level': -1,
      }),
      -1,
    );
  });

  test('normalizeLevel_returns_unknown_when_no_valid_keys', () {
    expect(FlutterBattery.normalizeLevel({'timestamp': 123}), -1);
  });

  test('configureBatteryCallbacks_wires_typed_callbacks', () {
    final mock = CallbackCaptureMock();
    FlutterBatteryPlatform.instance = mock;
    final plugin = FlutterBattery();

    BatteryInfo? capturedInfo;
    BatteryHealth? capturedHealth;

    plugin.configureBatteryCallbacks(
      onBatteryInfoChange: (info) {
        capturedInfo = info;
      },
      onBatteryHealthChange: (health) {
        capturedHealth = health;
      },
    );

    expect(mock.hasInfoCallback, true);
    expect(mock.hasHealthCallback, true);

    mock.invokeInfoCallback({
      'level': 77,
      'batteryLevel': 77,
      'isCharging': true,
      'temperature': 28.0,
      'voltage': 4.0,
      'state': 'CHARGING',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    expect(capturedInfo, isNotNull);
    expect(capturedInfo!.level, 77);
    expect(capturedInfo!.isCharging, true);

    mock.invokeHealthCallback({
      'state': 'GOOD',
      'statusLabel': 'Good',
      'isGood': true,
      'level': 80,
      'batteryLevel': 80,
      'temperature': 30.0,
      'voltage': 4.1,
      'riskLevel': 'LOW',
      'recommendations': ['OK'],
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    expect(capturedHealth, isNotNull);
    expect(capturedHealth!.state, BatteryHealthState.good);
    expect(capturedHealth!.isGood, true);
  });
}
