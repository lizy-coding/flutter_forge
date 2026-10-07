import '../src/battery_channel_contract.dart';

enum BatteryHealthState {
  good,
  overheat,
  dead,
  overVoltage,
  failure,
  cold,
  unknown,
}

class BatteryHealth {
  final BatteryHealthState state;
  final String statusLabel;
  final bool isGood;
  final double temperature;
  final double voltage;
  final int level;
  final bool isCharging;
  final String riskLevel;
  final List<String> recommendations;
  final int timestamp;

  BatteryHealth({
    required this.state,
    required this.statusLabel,
    required this.isGood,
    required this.temperature,
    required this.voltage,
    required this.level,
    required this.isCharging,
    required this.riskLevel,
    required this.recommendations,
    required this.timestamp,
  });

  factory BatteryHealth.fromMap(Map<String, dynamic> map) {
    final level =
        map[BatteryPayloadKeys.level] as int? ??
        map[BatteryPayloadKeys.batteryLevel] as int? ??
        -1;
    return BatteryHealth(
      state: _parseHealthState(map[BatteryPayloadKeys.state] as String?),
      statusLabel: map[BatteryPayloadKeys.statusLabel] as String? ?? '未知',
      isGood: map[BatteryPayloadKeys.isGood] as bool? ?? false,
      temperature:
          (map[BatteryPayloadKeys.temperature] as num?)?.toDouble() ?? 0.0,
      voltage: (map[BatteryPayloadKeys.voltage] as num?)?.toDouble() ?? 0.0,
      level: level,
      isCharging: map[BatteryPayloadKeys.isCharging] as bool? ?? false,
      riskLevel: map[BatteryPayloadKeys.riskLevel] as String? ?? 'UNKNOWN',
      recommendations:
          (map[BatteryPayloadKeys.recommendations] as List?)
              ?.map((item) => item.toString())
              .toList() ??
          const <String>[],
      timestamp:
          map[BatteryPayloadKeys.timestamp] as int? ??
          DateTime.now().millisecondsSinceEpoch,
    );
  }

  static BatteryHealthState _parseHealthState(String? value) {
    switch (value) {
      case 'GOOD':
        return BatteryHealthState.good;
      case 'OVERHEAT':
        return BatteryHealthState.overheat;
      case 'DEAD':
        return BatteryHealthState.dead;
      case 'OVER_VOLTAGE':
        return BatteryHealthState.overVoltage;
      case 'FAILURE':
        return BatteryHealthState.failure;
      case 'COLD':
        return BatteryHealthState.cold;
      default:
        return BatteryHealthState.unknown;
    }
  }

  @override
  String toString() =>
      'BatteryHealth(state: $state, risk: $riskLevel, temp: ${temperature.toStringAsFixed(1)}°C)';
}
