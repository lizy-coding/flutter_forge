import 'package:flutter/material.dart';
import 'package:flutter_battery/flutter_battery.dart';
import 'package:flutter_forge_app/modules/platform/battery_monitor/module_entry.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('native battery query, events and module reentry', (
    tester,
  ) async {
    final battery = FlutterBattery();
    final caps = await battery.getPlatformCapabilities();
    expect(caps.isSupported(BatteryFeature.batteryInfo), isTrue);
    expect(caps.isSupported(BatteryFeature.batteryLevelStream), isTrue);
    final info = await battery.getBatteryInfo();
    expect(info.level, inInclusiveRange(-1, 100));
    final levelObservation = await battery.observe(
      options: BatteryObservationOptions(levelIntervalMs: 100),
    );
    final healthObservation = await battery.observe(
      options: BatteryObservationOptions(
        samples: {BatterySample.health},
        healthIntervalMs: 100,
      ),
    );
    final event = await levelObservation.events.first.timeout(
      const Duration(seconds: 8),
    );
    expect(event[BatteryPayloadKeys.type], isNotNull);
    expect(
      event[BatteryPayloadKeys.level],
      event[BatteryPayloadKeys.batteryLevel],
    );
    await levelObservation.close();
    final healthEvent = await healthObservation.events.first.timeout(
      const Duration(seconds: 8),
    );
    expect(
      healthEvent[BatteryPayloadKeys.type],
      anyOf(
        BatteryEventTypes.batteryHealth,
        BatteryEventTypes.batteryUnavailable,
      ),
    );
    await healthObservation.close();
    debugPrint(
      'BATTERY_NATIVE_EVIDENCE level=${info.level} charging=${info.isCharging} event=$event capabilities=${caps.supportedFeatures}',
    );
    for (var i = 0; i < 2; i++) {
      await tester.pumpWidget(
        MaterialApp(home: BatteryMonitorEntry(battery: battery)),
      );
      await tester.pumpAndSettle();
      expect(find.text('电池状态与事件监听'), findsOneWidget);
      await tester.tap(find.text('刷新电池状态'));
      await tester.pumpAndSettle();
      expect(find.textContaining('读取失败：'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    }
  });
}
