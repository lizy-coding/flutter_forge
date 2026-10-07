import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_battery/flutter_battery.dart';

class BatterySession extends ChangeNotifier {
  BatterySession(this.battery);

  final FlutterBattery battery;
  BatteryPlatformCapabilities? capabilities;
  BatteryInfo? info;
  BatteryHealth? health;
  int? level;
  String? error;
  String? streamError;
  int eventCount = 0;
  bool loading = false;
  bool _disposed = false;
  StreamSubscription<Map<String, dynamic>>? _subscription;
  BatteryObservation? _observation;

  Future<void> initialize() async {
    try {
      final result = await battery.getPlatformCapabilities();
      if (_disposed) return;
      capabilities = result;
      if (result.isSupported(BatteryFeature.batteryLevelStream)) {
        final samples = <BatterySample>{BatterySample.level};
        if (result.isSupported(BatteryFeature.batteryInfoStream)) {
          samples.add(BatterySample.info);
        }
        if (result.isSupported(BatteryFeature.batteryHealthStream)) {
          samples.add(BatterySample.health);
        }
        final observation = await battery.observe(
          options: BatteryObservationOptions(samples: samples),
        );
        if (_disposed) {
          await observation.close();
          return;
        }
        _observation = observation;
        _subscription = observation.events.listen(
          (event) {
            if (_disposed) return;
            eventCount++;
            if (event[BatteryPayloadKeys.type] ==
                BatteryEventTypes.batteryInfo) {
              info = BatteryInfo.fromMap(event);
            }
            if (event[BatteryPayloadKeys.type] ==
                BatteryEventTypes.batteryHealth) {
              health = BatteryHealth.fromMap(event);
            }
            final value =
                event[BatteryPayloadKeys.level] ??
                event[BatteryPayloadKeys.batteryLevel];
            if (event[BatteryPayloadKeys.type] ==
                BatteryEventTypes.batteryUnavailable) {
              level = null;
            } else if (value is int) {
              level = value >= 0 && value <= 100 ? value : null;
            }
            streamError = null;
            notifyListeners();
          },
          onError: (Object failure) {
            if (_disposed) return;
            streamError = '事件监听失败：$failure';
            notifyListeners();
          },
        );
      }
      await refresh();
    } catch (failure) {
      if (_disposed) return;
      error = '初始化失败：$failure';
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    if (_disposed || loading || capabilities == null) return;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final caps = capabilities!;
      if (caps.isSupported(BatteryFeature.batteryInfo)) {
        final result = await battery.getBatteryInfo();
        if (_disposed) return;
        info = result;
        level = result.level >= 0 && result.level <= 100 ? result.level : null;
      } else if (caps.isSupported(BatteryFeature.batteryLevel)) {
        final result = await battery.getBatteryLevel();
        if (_disposed) return;
        level = result != null && result >= 0 && result <= 100 ? result : null;
      }
      if (caps.isSupported(BatteryFeature.batteryHealth)) {
        final result = await battery.getBatteryHealth();
        if (_disposed) return;
        health = result;
      }
    } catch (failure) {
      if (_disposed) return;
      error = '读取失败：$failure';
    } finally {
      if (!_disposed) {
        loading = false;
        notifyListeners();
      }
    }
  }

  Future<void> _releaseObservation() async {
    final closing = _observation?.close();
    try {
      await _subscription?.cancel();
    } finally {
      await closing;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(
      _releaseObservation().catchError((Object error) {
        debugPrint('Battery observation cleanup failed: $error');
      }),
    );
    super.dispose();
  }
}
