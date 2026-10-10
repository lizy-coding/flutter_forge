import 'dart:async';

import 'package:flutter_battery/flutter_battery.dart';
import 'package:flutter_battery/src/native_battery_monitoring.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'periodic repeats unchanged values; changes emits only distinct values',
    () async {
      final source = StreamController<Map<String, dynamic>>.broadcast();
      final hub = BatteryObservationCoordinator(
        source: source.stream,
        configure: (_) async {},
      );
      final sampled = await hub.open(
        BatterySamplingOptions(levelIntervalMs: 100),
      );
      final watched = await hub.open(BatteryChangeOptions());
      final samples = <Map<String, dynamic>>[];
      final changes = <Map<String, dynamic>>[];
      final a = sampled.events.listen(samples.add);
      final b = watched.events.listen(changes.add);
      void emit(int level, int stamp) => source.add({
        'type': 'BATTERY_LEVEL',
        'sample': 'level',
        'availability': 'available',
        'level': level,
        'timestamp': stamp,
      });
      emit(80, 1);
      await Future<void>.delayed(const Duration(milliseconds: 120));
      emit(80, 2);
      await Future<void>.delayed(Duration.zero);
      expect(samples, hasLength(2));
      expect(changes, hasLength(1));
      expect(samples.first['delivery'], 'initial');
      expect(samples.last['delivery'], 'sample');
      emit(79, 3);
      await Future<void>.delayed(const Duration(milliseconds: 120));
      expect(changes, hasLength(2));
      expect(changes.last['delivery'], 'change');
      await watched.close();
      emit(79, 4);
      await Future<void>.delayed(const Duration(milliseconds: 120));
      expect(changes, hasLength(2));
      expect(samples, hasLength(4));
      await sampled.close();
      await a.cancel();
      await b.cancel();
      await source.close();
    },
  );
  test(
    'level changes ignore power-only changes; info changes include power',
    () async {
      final source = StreamController<Map<String, dynamic>>.broadcast();
      final hub = BatteryObservationCoordinator(
        source: source.stream,
        configure: (_) async {},
      );
      final level = await hub.open(BatteryChangeOptions());
      final info = await hub.open(
        BatteryChangeOptions(samples: {BatterySample.info}),
      );
      final levels = <Map<String, dynamic>>[];
      final infos = <Map<String, dynamic>>[];
      final a = level.events.listen(levels.add);
      final b = info.events.listen(infos.add);
      for (final power in ['battery', 'external']) {
        for (final type in ['level', 'info']) {
          source.add({
            'type': type == 'level' ? 'BATTERY_LEVEL' : 'BATTERY_INFO',
            'sample': type,
            'availability': 'available',
            'level': 80,
            'powerSource': power,
          });
        }
        await Future<void>.delayed(Duration.zero);
      }
      expect(levels, hasLength(1));
      expect(infos, hasLength(2));
      await level.close();
      await info.close();
      await a.cancel();
      await b.cancel();
      await source.close();
    },
  );
  test(
    'health changes do not masquerade as level or legacy-policy changes',
    () async {
      final source = StreamController<Map<String, dynamic>>.broadcast();
      final hub = BatteryObservationCoordinator(
        source: source.stream,
        configure: (_) async {},
      );
      final owner = await hub.open(
        BatteryChangeOptions(samples: {BatterySample.health}),
      );
      final events = <Map<String, dynamic>>[];
      final subscription = owner.events.listen(events.add);
      for (final level in [80, 79]) {
        source.add({
          'type': 'BATTERY_HEALTH',
          'availability': 'available',
          'level': level,
          'state': 'GOOD',
          'recommendations': ['$level is a legacy recommendation'],
        });
        await Future<void>.delayed(Duration.zero);
      }
      expect(events, hasLength(1));
      source.add({
        'type': 'BATTERY_HEALTH',
        'availability': 'available',
        'level': 79,
        'state': 'DEGRADED',
      });
      await Future<void>.delayed(Duration.zero);
      expect(events, hasLength(2));
      await owner.close();
      await subscription.cancel();
      await source.close();
    },
  );
  test('timestamp and map order are not logical changes', () async {
    final source = StreamController<Map<String, dynamic>>.broadcast();
    final hub = BatteryObservationCoordinator(
      source: source.stream,
      configure: (_) async {},
    );
    final owner = await hub.open(
      BatteryChangeOptions(samples: {BatterySample.info}),
    );
    final values = <Map<String, dynamic>>[];
    final subscription = owner.events.listen(values.add);
    source.add({
      'type': 'BATTERY_INFO',
      'level': 80,
      'timestamp': 1,
      'capacity': {'remaining': 10, 'unit': 'unspecified'},
    });
    await Future<void>.delayed(Duration.zero);
    source.add({
      'timestamp': 2,
      'capacity': {'unit': 'unspecified', 'remaining': 10},
      'level': 80,
      'type': 'BATTERY_INFO',
    });
    await Future<void>.delayed(Duration.zero);
    expect(values, hasLength(1));
    await owner.close();
    await subscription.cancel();
    await source.close();
  });
}
