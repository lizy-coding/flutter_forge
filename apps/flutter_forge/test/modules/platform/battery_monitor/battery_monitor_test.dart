import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_battery/flutter_battery.dart';
import 'package:flutter_forge_app/modules/platform/battery_monitor/battery_session.dart';
import 'package:flutter_forge_app/modules/platform/battery_monitor/module_entry.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeBattery extends FlutterBattery {
  final events = StreamController<Map<String, dynamic>>.broadcast();
  late final coordinator = BatteryObservationCoordinator(
    source: events.stream,
    configure: (_) async {},
  );
  @override
  Future<BatteryObservation> observe({BatteryObservationOptions? options}) =>
      coordinator.open(options ?? BatteryObservationOptions());

  Completer<BatteryInfo>? pendingInfo;
  var fail = false;
  var reads = 0;

  @override
  Future<BatteryPlatformCapabilities> getPlatformCapabilities() async =>
      const BatteryPlatformCapabilities(
        features: {
          BatteryFeature.batteryInfo: true,
          BatteryFeature.batteryLevelStream: true,
        },
      );

  @override
  Future<BatteryInfo> getBatteryInfo() async {
    reads++;
    if (fail) throw StateError('read failed');
    if (pendingInfo != null) return pendingInfo!.future;
    return BatteryInfo(
      level: 52,
      isCharging: false,
      temperature: 0,
      voltage: 0,
      state: BatteryState.NORMAL,
      timestamp: 1,
    );
  }

  @override
  Stream<Map<String, dynamic>> get batteryStream => events.stream;
}

void main() {
  test('session releases events and ignores late async reads', () async {
    final battery = FakeBattery()..pendingInfo = Completer<BatteryInfo>();
    final session = BatterySession(battery);
    final initializing = session.initialize();
    await Future<void>.delayed(Duration.zero);
    expect(battery.events.hasListener, isTrue);
    session.dispose();
    await Future<void>.delayed(Duration.zero);
    expect(battery.events.hasListener, isFalse);
    battery.pendingInfo!.complete(
      BatteryInfo(
        level: 20,
        isCharging: false,
        temperature: 0,
        voltage: 0,
        state: BatteryState.LOW,
        timestamp: 1,
      ),
    );
    await initializing;
    expect(session.info, isNull);
    await battery.events.close();
  });

  test(
    'unavailable event is not a zero battery reading and errors recover',
    () async {
      final battery = FakeBattery();
      final session = BatterySession(battery);
      await session.initialize();
      battery.events.add({
        BatteryPayloadKeys.type: BatteryEventTypes.batteryUnavailable,
        BatteryPayloadKeys.level: -1,
      });
      await Future<void>.delayed(Duration.zero);
      expect(session.level, isNull);
      battery.fail = true;
      await session.refresh();
      expect(session.error, contains('读取失败'));
      battery.fail = false;
      await session.refresh();
      expect(session.error, isNull);
      expect(session.level, 52);
      session.dispose();
      await battery.events.close();
    },
  );

  testWidgets('compact page shows capabilities and refreshes real adapter', (
    tester,
  ) async {
    final battery = FakeBattery();
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(home: BatteryMonitorEntry(battery: battery)),
    );
    await tester.pumpAndSettle();
    expect(find.text('52%'), findsOneWidget);
    expect(find.text('原生通知：不支持'), findsOneWidget);
    await tester.tap(find.text('刷新电池状态'));
    await tester.pumpAndSettle();
    expect(battery.reads, 2);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    expect(battery.events.hasListener, isFalse);
    await battery.events.close();
  });
}
