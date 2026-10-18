import 'dart:async';

import 'package:flutter_battery/flutter_battery.dart';
import 'package:flutter_battery/battery_result.dart' show decodeBatterySample;
import 'package:flutter_battery/src/native_battery_monitoring.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final item in <String, (Map<String, dynamic>, BatteryChargeState)>{
    'AC attached but not charging': (
      {'powerSource': 'external', 'isCharging': false, 'isCharged': false},
      BatteryChargeState.notCharging,
    ),
    'AC charging': (
      {'powerSource': 'external', 'isCharging': true},
      BatteryChargeState.charging,
    ),
    'AC full': (
      {'powerSource': 'external', 'isCharging': false, 'isCharged': true},
      BatteryChargeState.full,
    ),
    'battery discharge': (
      {'powerSource': 'battery', 'isCharging': false},
      BatteryChargeState.discharging,
    ),
    'unknown source': ({'isCharging': false}, BatteryChargeState.unknown),
    'unknown charging': (
      {'powerSource': 'external'},
      BatteryChargeState.unknown,
    ),
  }.entries) {
    test(item.key, () {
      final result = decodeBatterySample({
        'availability': 'available',
        'level': 80,
        ...item.value.$1,
      }, BatterySample.info);
      expect(result.value!.chargeState, item.value.$2);
    });
  }
  test('same-level power changes survive debounce and throttling', () async {
    final source = StreamController<Map<String, dynamic>>.broadcast();
    final hub = BatteryObservationCoordinator(
      source: source.stream,
      configure: (_) async {},
    );
    final owner = await hub.open(
      BatteryObservationOptions(levelIntervalMs: 100),
    );
    final events = <Map<String, dynamic>>[];
    final subscription = owner.events.listen(events.add);
    source.add({
      'type': 'BATTERY_LEVEL',
      'level': 80,
      'powerSource': 'battery',
      'isCharging': false,
    });
    await Future<void>.delayed(Duration.zero);
    source.add({
      'type': 'BATTERY_LEVEL',
      'level': 80,
      'powerSource': 'external',
      'isCharging': false,
    });
    await Future<void>.delayed(const Duration(milliseconds: 130));
    expect(events, hasLength(2));
    expect(events.last['powerSource'], 'external');
    await owner.close();
    await subscription.cancel();
    await source.close();
  });
  test('closing cancels queued trailing samples', () async {
    final source = StreamController<Map<String, dynamic>>.broadcast();
    final hub = BatteryObservationCoordinator(
      source: source.stream,
      configure: (_) async {},
    );
    final owner = await hub.open(
      BatteryObservationOptions(levelIntervalMs: 100),
    );
    final events = <Map<String, dynamic>>[];
    final subscription = owner.events.listen(events.add);
    source.add({'type': 'BATTERY_LEVEL', 'level': 80});
    await Future<void>.delayed(Duration.zero);
    source.add({'type': 'BATTERY_LEVEL', 'level': 79});
    await Future<void>.delayed(Duration.zero);
    await owner.close();
    await Future<void>.delayed(const Duration(milliseconds: 130));
    expect(events, hasLength(1));
    await subscription.cancel();
    await source.close();
  });
}
