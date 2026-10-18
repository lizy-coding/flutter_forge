import 'package:flutter_battery/flutter_battery.dart';
import 'package:flutter_battery/battery_result.dart' show decodeBatterySample;
import 'package:flutter_test/flutter_test.dart';

void main() {
  BatteryOutcome<BatterySnapshot> decode(Map<String, dynamic> capacity) =>
      decodeBatterySample({
        'availability': 'available',
        'level': 80,
        'capacity': capacity,
      }, BatterySample.info);
  test('raw macOS values do not invent units or a design percentage', () {
    final result = decode({
      'remaining': 3729,
      'fullCharge': 4690,
      'design': 4629,
      'cycleCount': 7,
      'unit': 'unspecified',
      'source': 'AppleSmartBattery registry',
    });
    expect(result.status, BatteryStatus.available);
    expect(result.value!.capacity!.fullChargeRelativeToDesignPercent, isNull);
    expect(result.value!.capacity!.cycleCount, 7);
  });
  test('known units derive capacity ratio without clamping real readings', () {
    final result = decode({
      'fullCharge': 5050,
      'design': 5000,
      'remaining': 0,
      'cycleCount': 0,
      'unit': 'milliampHours',
      'source': 'verified adapter',
    });
    expect(result.value!.capacity!.fullChargeRelativeToDesignPercent, 101);
    expect(result.value!.capacity!.remaining, 0);
    expect(result.value!.capacity!.cycleCount, 0);
  });
  test(
    'partial Android charge counter does not invent full or design capacity',
    () {
      final result = decode({
        'remaining': 2000,
        'unit': 'milliampHours',
        'source': 'BatteryManager charge counter',
      });
      expect(result.value!.capacity!.fullCharge, isNull);
      expect(result.value!.capacity!.design, isNull);
    },
  );
  for (final field in ['fullCharge', 'design', 'cycleCount', 'remaining']) {
    test('invalid $field is explicit invalidData', () {
      expect(
        decode({field: -1, 'unit': 'percent', 'source': 'adapter'}).status,
        BatteryStatus.invalidData,
      );
    });
  }
  test('absent diagnostics preserve unknown rather than zero', () {
    final result = decodeBatterySample({
      'availability': 'available',
      'level': 80,
    }, BatterySample.info);
    expect(result.value!.capacity, isNull);
  });
  test('percent values are not mixed with physical design quantities', () {
    expect(
      decode({
        'fullCharge': 100,
        'design': 100,
        'unit': 'percent',
        'source': 'IOPS',
      }).value!.capacity!.fullChargeRelativeToDesignPercent,
      isNull,
    );
  });
}
