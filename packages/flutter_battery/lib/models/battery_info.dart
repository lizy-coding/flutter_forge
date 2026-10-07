import '../src/battery_channel_contract.dart';

enum BatteryState { NORMAL, LOW, CRITICAL, CHARGING, FULL, UNKNOWN }

class BatteryInfo {
  final int level;
  final bool isCharging;
  final double temperature;
  final double voltage;
  final BatteryState state;
  final int timestamp;

  BatteryInfo({
    required this.level,
    required this.isCharging,
    required this.temperature,
    required this.voltage,
    required this.state,
    required this.timestamp,
  });

  factory BatteryInfo.fromMap(Map<String, dynamic> map) {
    final level =
        map[BatteryPayloadKeys.level] as int? ??
        map[BatteryPayloadKeys.batteryLevel] as int? ??
        -1;
    return BatteryInfo(
      level: level,
      isCharging: map[BatteryPayloadKeys.isCharging] as bool? ?? false,
      temperature:
          (map[BatteryPayloadKeys.temperature] as num?)?.toDouble() ?? 0.0,
      voltage: (map[BatteryPayloadKeys.voltage] as num?)?.toDouble() ?? 0.0,
      state: _parseState(map[BatteryPayloadKeys.state] as String?),
      timestamp:
          map[BatteryPayloadKeys.timestamp] as int? ??
          DateTime.now().millisecondsSinceEpoch,
    );
  }

  static BatteryState _parseState(String? stateStr) {
    if (stateStr == null) return BatteryState.UNKNOWN;

    try {
      return BatteryState.values.firstWhere(
        (e) => e.toString() == 'BatteryState.$stateStr',
        orElse: () => BatteryState.UNKNOWN,
      );
    } catch (_) {
      return BatteryState.UNKNOWN;
    }
  }

  @override
  String toString() =>
      'BatteryInfo(level: $level%, isCharging: $isCharging, '
      'temperature: ${temperature.toStringAsFixed(1)}°C, '
      'voltage: ${voltage.toStringAsFixed(2)}V, state: $state)';
}
