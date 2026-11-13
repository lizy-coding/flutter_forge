import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bluetooth_system_bridge/bluetooth_system_bridge.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.android);
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(MethodChannelBluetoothSystem.channel, null);
  });
  void reply(Object? value) => TestDefaultBinaryMessengerBinding
      .instance
      .defaultBinaryMessenger
      .setMockMethodCallHandler(
        MethodChannelBluetoothSystem.channel,
        (_) async => value,
      );
  test('only available outcomes can carry a value', () {
    expect(
      () => BluetoothSystemOutcome<bool>.state(
        BluetoothSystemStatus.available,
        'invalid',
      ),
      throwsArgumentError,
    );
  });
  test('capabilities absent plugin degrades without throwing', () async {
    expect(
      (await MethodChannelBluetoothSystem().queryCapabilities()).settings,
      isFalse,
    );
    expect(
      (await MethodChannelBluetoothSystem().connectedAudioDevices()).status,
      BluetoothSystemStatus.unsupported,
    );
  });
  test('bad item preserves good items and exposes a failed entry', () async {
    reply([
      {
        'id': 'a',
        'name': 'headset',
        'profiles': ['audio'],
      },
      42,
      {
        'id': 'b',
        'profiles': ['call'],
      },
    ]);
    final result = await MethodChannelBluetoothSystem().connectedAudioDevices();
    expect(result.isAvailable, isTrue);
    expect(result.value!.map((e) => e.id), ['a', 'invalid/1', 'b']);
    expect(result.value![1].error, 'invalid_device_entry');
  });
  test('wrong list is invalidData', () async {
    reply({'devices': []});
    expect(
      (await MethodChannelBluetoothSystem().connectedAudioDevices()).status,
      BluetoothSystemStatus.invalidData,
    );
  });
  test('permission and adapter failures remain distinguishable', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          MethodChannelBluetoothSystem.channel,
          (_) async => throw PlatformException(code: 'permission_denied'),
        );
    expect(
      (await MethodChannelBluetoothSystem().connectedAudioDevices()).status,
      BluetoothSystemStatus.permissionDenied,
    );
  });
  test('settings preserves channel request and acknowledgement', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(MethodChannelBluetoothSystem.channel, (
          call,
        ) async {
          expect(call.method, 'openSettings');
          return null;
        });
    expect((await MethodChannelBluetoothSystem().openSettings()).value, isTrue);
  });
}
