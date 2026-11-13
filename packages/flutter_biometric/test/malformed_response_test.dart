import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_biometric/flutter_biometric.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel(BiometricChannelContract.methodChannel);
  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null),
  );
  for (final payload in <Object?>[
    42,
    'wrong',
    [],
    {'status': 'failed', 'reason': 42},
    {'status': 'failed', 'message': []},
  ]) {
    test('malformed reply $payload resolves to invalidData', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (_) async => payload);
      final adapter = MethodChannelFlutterBiometric();
      final result = await adapter.authenticate(
        const BiometricAuthRequest(reason: "test"),
      );
      expect(result.status, BiometricAuthStatus.invalidData);
    });
  }
}
