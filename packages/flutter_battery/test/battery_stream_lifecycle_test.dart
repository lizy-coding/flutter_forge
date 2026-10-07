import 'package:flutter/services.dart';
import 'package:flutter_battery/flutter_battery.dart';
import 'package:flutter_battery/flutter_battery_method_channel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const events = MethodChannel(BatteryChannelNames.eventChannel);
  const methods = MethodChannel(BatteryChannelNames.methodChannel);

  tearDown(() {
    messenger.setMockMethodCallHandler(events, null);
    messenger.setMockMethodCallHandler(methods, null);
  });

  test(
    'consumers share native listener and last cancellation releases it',
    () async {
      var listens = 0;
      var cancels = 0;
      messenger.setMockMethodCallHandler(events, (call) async {
        if (call.method == 'listen') listens++;
        if (call.method == 'cancel') cancels++;
        return null;
      });
      messenger.setMockMethodCallHandler(methods, (_) async => true);
      final platform = MethodChannelFlutterBattery();
      final first = <Map<String, dynamic>>[];
      final second = <Map<String, dynamic>>[];
      final a = platform.batteryStream.listen(first.add);
      final b = platform.batteryStream.listen(second.add);
      await Future<void>.delayed(Duration.zero);
      expect(listens, 1);
      await messenger.handlePlatformMessage(
        BatteryChannelNames.eventChannel,
        const StandardMethodCodec().encodeSuccessEnvelope({
          BatteryPayloadKeys.batteryLevel: 52,
          BatteryPayloadKeys.timestamp: 1,
        }),
        (_) {},
      );
      await Future<void>.delayed(Duration.zero);
      expect(first.single[BatteryPayloadKeys.level], 52);
      expect(
        second.single[BatteryPayloadKeys.type],
        BatteryEventTypes.batteryLevel,
      );
      await a.cancel();
      expect(cancels, 0);
      await b.cancel();
      await Future<void>.delayed(Duration.zero);
      expect(cancels, 1);
      final c = platform.batteryStream.listen((_) {});
      await Future<void>.delayed(Duration.zero);
      expect(listens, 2);
      await c.cancel();
    },
  );

  for (final code in ['missing', 'NOT_SUPPORTED']) {
    test('notification maps $code to typed unsupported feature', () async {
      messenger.setMockMethodCallHandler(methods, (_) async {
        if (code == 'missing') throw MissingPluginException();
        throw PlatformException(code: code);
      });
      final platform = MethodChannelFlutterBattery();
      await expectLater(
        platform.showNotification(title: 'test', message: 'test'),
        throwsA(
          isA<UnsupportedBatteryFeatureException>().having(
            (e) => e.feature,
            'feature',
            BatteryFeature.nativeNotifications,
          ),
        ),
      );
      await expectLater(
        platform.scheduleNotification(title: 'test', message: 'test'),
        throwsA(
          isA<UnsupportedBatteryFeatureException>().having(
            (e) => e.feature,
            'feature',
            BatteryFeature.scheduledNotifications,
          ),
        ),
      );
    });
  }
}
