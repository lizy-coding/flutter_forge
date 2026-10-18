import 'package:flutter/material.dart';
import 'package:flutter_battery/flutter_battery.dart';
import 'package:flutter_forge_app/modules/platform/battery_monitor/module_entry.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('typed native reads and independent observations', (
    tester,
  ) async {
    final battery = FlutterBattery();
    final caps = await battery.capabilities();
    expect(caps.status, BatteryStatus.available);
    expect(caps.value!.supports(BatterySample.info), isTrue);
    final read = await battery.read();
    expect(
      read.status,
      anyOf(
        BatteryStatus.available,
        BatteryStatus.noBattery,
        BatteryStatus.unknown,
      ),
    );
    final changed = await battery.watchChanges(
      options: BatteryChangeOptions(samples: {BatterySample.level}),
    );
    expect(changed.status, BatteryStatus.available);
    final changeEvents = <BatteryOutcome<BatterySnapshot>>[];
    final changeSubscription = changed.value!.events.listen((event) {
      if (event.status != BatteryStatus.pending) changeEvents.add(event);
    });
    final levelOpened = await battery.sample(
      options: BatterySamplingOptions(levelIntervalMs: 100),
    );
    final healthOpened = await battery.sample(
      options: BatterySamplingOptions(
        samples: {BatterySample.health},
        healthIntervalMs: 100,
      ),
    );
    expect(levelOpened.status, BatteryStatus.available);
    expect(healthOpened.status, BatteryStatus.available);
    final level = await levelOpened.value!.events
        .firstWhere((event) => event.status != BatteryStatus.pending)
        .timeout(const Duration(seconds: 8));
    expect(
      level.status,
      anyOf(
        BatteryStatus.available,
        BatteryStatus.noBattery,
        BatteryStatus.unknown,
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 350));
    expect(changeEvents, isNotEmpty);
    expect(changeEvents.first.delivery, BatteryEventDelivery.initial);
    expect(
      changeEvents
          .skip(1)
          .every((event) => event.delivery == BatteryEventDelivery.change),
      isTrue,
    );
    expect((await levelOpened.value!.close()).status, BatteryStatus.closed);
    expect(changed.value!.state, BatteryObservationState.active);
    expect((await changed.value!.close()).status, BatteryStatus.closed);
    await changeSubscription.cancel();
    final health = await healthOpened.value!.events
        .firstWhere((event) => event.status != BatteryStatus.pending)
        .timeout(const Duration(seconds: 8));
    expect(
      health.status,
      anyOf(
        BatteryStatus.available,
        BatteryStatus.noBattery,
        BatteryStatus.unknown,
      ),
    );
    expect((await healthOpened.value!.close()).status, BatteryStatus.closed);
    debugPrint(
      'PHASE1_NATIVE read=${read.status.name} level=${read.value?.level} power=${read.value?.powerSource.name} charging=${read.value?.isCharging} charged=${read.value?.isCharged} chargeState=${read.value?.chargeState.name} health=${health.status.name}',
    );
    for (var i = 0; i < 2; i++) {
      await tester.pumpWidget(
        MaterialApp(home: BatteryMonitorEntry(battery: battery)),
      );
      await tester.pumpAndSettle();
      expect(find.text('电池状态与事件监听'), findsOneWidget);
      await tester.tap(find.text('刷新电池状态'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('定期采样'));
      await tester.tap(find.text('定期采样'));
      await tester.pumpAndSettle();
      expect(find.text('采样间隔'), findsOneWidget);
      await tester.ensureVisible(find.text('停止监听'));
      await tester.tap(find.text('停止监听'));
      await tester.pumpAndSettle();
      expect(find.text('会话：已停止'), findsOneWidget);
      await tester.tap(find.text('开始监听'));
      await tester.pumpAndSettle();
      expect(find.text('会话：监听中'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    }
  });
}
