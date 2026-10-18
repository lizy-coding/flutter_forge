import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_battery/flutter_battery.dart';
import 'package:flutter_battery/src/native_battery_monitoring.dart';
import 'package:flutter_forge_app/modules/platform/battery_monitor/battery_session.dart';
import 'package:flutter_forge_app/modules/platform/battery_monitor/module_entry.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeBattery extends FlutterBattery {
  // Ownership is released through a local alias or the owner teardown; covered by lifecycle tests.
  // ignore: close_sinks
  final source = StreamController<Map<String, dynamic>>.broadcast();
  late final hub = BatteryObservationCoordinator(
    source: source.stream,
    configure: (_) async {
      if (failConfigure) throw PlatformException(code: 'close_failed');
    },
  );
  Completer<BatteryOutcome<BatterySnapshot>>? pending;
  var fail = false;
  var failConfigure = false;
  var failOpen = false;
  var changesSupported = true;
  BatteryCapacityDetails? capacity;
  final openedOptions = <BatteryObservationOptions>[];
  Completer<void>? opening;

  var reads = 0;
  @override
  Future<BatteryOutcome<BatteryCapabilities>> capabilities() async =>
      BatteryOutcome.available(
        BatteryCapabilities(
          samples: {BatterySample.info},
          observableSamples: {BatterySample.level, BatterySample.info},
          observationSupported: true,
          changeObservationSupported: changesSupported,
        ),
      );
  @override
  Future<BatteryOutcome<BatterySnapshot>> read({
    BatterySample sample = BatterySample.info,
  }) async {
    reads++;
    if (pending != null) return await pending!.future;
    if (fail) {
      return BatteryOutcome.state(BatteryStatus.failed, 'read_failed', '读取失败');
    }
    return BatteryOutcome.available(
      BatterySnapshot(sample: sample, level: 52, capacity: capacity),
    );
  }

  @override
  Future<BatteryOutcome<BatteryObservation>> observe({
    BatteryObservationOptions? options,
  }) async {
    if (opening != null) await opening!.future;
    if (failOpen) {
      return BatteryOutcome.state(
        BatteryStatus.unavailable,
        'open_failed',
        '无法订阅',
      );
    }
    final selected = options ?? BatterySamplingOptions();
    openedOptions.add(selected);
    return BatteryOutcome.available(
      BatteryObservation.fromNative(
        await hub.open(selected),
        const Duration(seconds: 1),
      ),
    );
  }
}

void main() {
  test('late read does not update disposed session', () async {
    final battery = FakeBattery()..pending = Completer();
    final session = BatterySession(battery);
    final initializing = session.initialize();
    await Future<void>.delayed(Duration.zero);
    session.dispose();
    battery.pending!.complete(
      BatteryOutcome.available(
        BatterySnapshot(sample: BatterySample.info, level: 20),
      ),
    );
    await initializing;
    expect(session.info, isNull);
    expect(battery.source.hasListener, isFalse);
    await battery.source.close();
  });
  test(
    'typed no-battery event and failed read remain distinct and recover',
    () async {
      final battery = FakeBattery();
      final session = BatterySession(battery);
      await session.initialize();
      battery.source.add({
        'type': 'BATTERY_INFO',
        'sample': 'info',
        'availability': 'noBattery',
      });
      await Future<void>.delayed(Duration.zero);
      expect(session.level, isNull);
      expect(session.reading!.status, BatteryStatus.noBattery);
      battery.fail = true;
      await session.refresh();
      expect(session.reading!.status, BatteryStatus.failed);
      battery.fail = false;
      await session.refresh();
      expect(session.level, 52);
      session.dispose();
      await Future<void>.delayed(Duration.zero);
      expect(battery.source.hasListener, isFalse);
      await battery.source.close();
    },
  );
  test(
    'level updates preserve info metrics and show AC not charging',
    () async {
      final battery = FakeBattery();
      final session = BatterySession(battery);
      await session.initialize();
      await session.configure(
        selection: {BatterySample.info, BatterySample.level},
      );
      battery.source.add({
        'type': 'BATTERY_INFO',
        'sample': 'info',
        'availability': 'available',
        'level': 80,
        'powerSource': 'external',
        'isCharging': false,
        'isCharged': false,
        'temperature': 30.0,
      });
      await Future<void>.delayed(Duration.zero);
      expect(session.powerText, '接入电源，当前未充电');
      expect(session.info!.temperatureCelsius, 30.0);
      battery.source.add({
        'type': 'BATTERY_LEVEL',
        'sample': 'level',
        'availability': 'available',
        'level': 81,
        'powerSource': 'external',
        'isCharging': false,
        'isCharged': false,
      });
      await Future<void>.delayed(Duration.zero);
      expect(session.level, 81);
      expect(session.info!.temperatureCelsius, 30.0);
      expect(session.powerText, '接入电源，当前未充电');
      session.dispose();
      await Future<void>.delayed(Duration.zero);
      await battery.source.close();
    },
  );
  test(
    'default changes, mode replacement, interval and stop do not leak owners',
    () async {
      final battery = FakeBattery();
      final session = BatterySession(battery);
      await session.initialize();
      expect(battery.openedOptions.single.mode, BatteryDeliveryMode.changes);
      expect(battery.openedOptions.single.samples, {BatterySample.info});
      await session.configure(
        deliveryMode: BatteryDeliveryMode.sampling,
        interval: 5000,
        selection: {BatterySample.level},
      );
      expect(battery.openedOptions.last.intervalFor(BatterySample.level), 5000);
      expect(session.observing, isTrue);
      await session.stop();
      expect(session.closeResult!.status, BatteryStatus.closed);
      expect(battery.source.hasListener, isFalse);
      await session.refresh();
      expect(session.observing, isFalse);
      await session.start();
      expect(session.observing, isTrue);
      await session.stop();
      session.dispose();
      await battery.source.close();
    },
  );

  test('unsupported changes falls back to periodic sampling', () async {
    final battery = FakeBattery()..changesSupported = false;
    final session = BatterySession(battery);
    await session.initialize();
    expect(session.mode, BatteryDeliveryMode.sampling);
    await session.stop();
    session.dispose();
    await battery.source.close();
  });

  test('stream failure refresh reopens observation and clears error', () async {
    final battery = FakeBattery();
    final session = BatterySession(battery);
    await session.initialize();
    battery.source.addError(MissingPluginException('disconnected'));
    await Future<void>.delayed(Duration.zero);
    expect(session.observationState, BatteryObservationState.failed);
    expect(session.streamError, isNotNull);
    await session.refresh();
    expect(battery.openedOptions, hasLength(2));
    expect(session.streamError, isNull);
    expect(session.observationState, BatteryObservationState.active);
    await session.stop();
    session.dispose();
    await battery.source.close();
  });

  test(
    'failed open can retry; failed close is visible and prevents automatic replacement',
    () async {
      final battery = FakeBattery()..failOpen = true;
      final session = BatterySession(battery);
      await session.initialize();
      expect(session.observing, isFalse);
      expect(session.streamError, contains('open_failed'));
      battery.failOpen = false;
      await session.start();
      expect(session.streamError, isNull);
      battery.failConfigure = true;
      await session.configure(deliveryMode: BatteryDeliveryMode.sampling);
      expect(session.observing, isFalse);
      expect(session.closeResult!.status, BatteryStatus.failed);
      expect(session.streamError, contains('关闭异常'));
      expect(battery.openedOptions, hasLength(1));
      battery.failConfigure = false;
      await session.start();
      expect(session.streamError, isNull);
      await session.stop();
      session.dispose();
      await battery.source.close();
    },
  );

  test(
    'late open is closed on dispose and parallel start is ignored',
    () async {
      final battery = FakeBattery()..opening = Completer<void>();
      final session = BatterySession(battery);
      final initializing = session.initialize();
      await Future<void>.delayed(Duration.zero);
      await session.start();
      session.dispose();
      battery.opening!.complete();
      await initializing;
      expect(battery.openedOptions, hasLength(1));
      expect(battery.source.hasListener, isFalse);
      await battery.source.close();
    },
  );

  test(
    'history keeps 20 changes with unknown timestamps and ignores stopped events',
    () async {
      final battery = FakeBattery();
      final session = BatterySession(battery);
      await session.initialize();
      for (var level = 0; level < 25; level++) {
        battery.source.add({
          'type': 'BATTERY_INFO',
          'sample': 'info',
          'availability': 'available',
          'level': level,
        });
        await Future<void>.delayed(Duration.zero);
      }
      expect(session.eventCount, 25);
      expect(session.history, hasLength(20));
      expect(session.history.first.value!.level, 24);
      expect(session.history.first.value!.timestamp, isNull);
      expect(session.history.first.delivery, BatteryEventDelivery.change);
      await session.stop();
      battery.source.add({
        'type': 'BATTERY_INFO',
        'availability': 'available',
        'level': 90,
      });
      await Future<void>.delayed(Duration.zero);
      expect(session.level, 24);
      session.clearHistory();
      expect(session.history, isEmpty);
      session.dispose();
      await battery.source.close();
    },
  );

  testWidgets('controls switch modes, select samples, stop and restart', (
    tester,
  ) async {
    // Keep the coordinator and its close futures in the same real async zone.
    await tester.runAsync(() async {
      final battery = FakeBattery();
      await tester.pumpWidget(
        MaterialApp(home: BatteryMonitorEntry(battery: battery)),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('定期采样'));
      await tester.tap(find.text('定期采样'));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await tester.pumpAndSettle();
      expect(find.text('采样间隔'), findsOneWidget);
      await tester.ensureVisible(find.byType(DropdownButtonFormField<int>));
      await tester.tap(find.byType(DropdownButtonFormField<int>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('5 秒').last);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await tester.pumpAndSettle();
      expect(battery.openedOptions.last.intervalFor(BatterySample.info), 5000);
      await tester.ensureVisible(find.text('电量读取'));
      await tester.tap(find.text('电量读取'));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await tester.pumpAndSettle();
      expect(battery.openedOptions.last.samples, {
        BatterySample.info,
        BatterySample.level,
      });
      await tester.ensureVisible(find.text('停止监听'));
      await tester.tap(find.text('停止监听'));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await tester.pumpAndSettle();
      expect(battery.source.hasListener, isFalse);
      await tester.tap(find.text('开始监听'));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await tester.pumpAndSettle();
      expect(battery.source.hasListener, isTrue);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      await battery.source.close();
    });
  });

  for (final width in [360.0, 1200.0]) {
    testWidgets('capacity diagnostics and controls at $width dp', (
      tester,
    ) async {
      final battery = FakeBattery()
        ..capacity = BatteryCapacityDetails(
          remaining: 0,
          fullCharge: 80,
          design: 100,
          cycleCount: 0,
          unit: BatteryCapacityUnit.unspecified,
          source: 'IOPS raw',
        );
      tester.view.physicalSize = Size(width, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final screenshotDir = Platform.environment['BATTERY_SCREENSHOT_DIR'];
      if (screenshotDir != null) {
        await tester.runAsync(() async {
          final loader = FontLoader('BatteryScreenshot');
          final font = await File(
            '/System/Library/Fonts/Supplemental/Arial Unicode.ttf',
          ).readAsBytes();
          loader.addFont(Future.value(ByteData.sublistView(font)));
          await loader.load();
          final monospace = FontLoader('monospace');
          monospace.addFont(Future.value(ByteData.sublistView(font)));
          await monospace.load();
        });
      }
      final boundaryKey = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: boundaryKey,
          child: MaterialApp(
            theme: ThemeData(
              fontFamily: screenshotDir == null ? null : 'BatteryScreenshot',
            ),
            home: BatteryMonitorEntry(battery: battery),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('当前容量：0 单位未知'), findsOneWidget);
      expect(find.text('循环次数：0'), findsOneWidget);
      expect(find.text('满充 / 设计：不可计算'), findsOneWidget);
      expect(find.text('系统变化'), findsOneWidget);
      expect(tester.takeException(), isNull);
      if (screenshotDir != null) {
        await tester.runAsync(() async {
          final boundary =
              boundaryKey.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          final image = await boundary.toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await Directory(screenshotDir).create(recursive: true);
          await File(
            '$screenshotDir/battery-${width.toInt()}.png',
          ).writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      await battery.source.close();
    });
  }

  testWidgets('compact typed page refreshes and closes observation', (
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
    await tester.tap(find.text('刷新电池状态'));
    await tester.pumpAndSettle();
    expect(battery.reads, 2);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    expect(battery.source.hasListener, isFalse);
    await battery.source.close();
  });
}
