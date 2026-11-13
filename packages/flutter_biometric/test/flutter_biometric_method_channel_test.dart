import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_biometric/flutter_biometric.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(BiometricChannelContract.methodChannel);

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  void mockResponses(Object? Function(String method, Object? args) respond) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          return respond(call.method, call.arguments);
        });
  }

  test('queryCapabilities keeps the channel contract', () async {
    final adapter = MethodChannelFlutterBiometric();
    mockResponses((method, args) {
      expect(method, BiometricChannelContract.queryCapabilities);
      return {
        'deviceSupported': true,
        'fingerprintAvailable': true,
        'faceAvailable': true,
        'deviceCredentialAvailable': false,
        'enrolledTypes': ['fingerprint', 'face', 'unknown-type'],
      };
    });

    final capabilities = await adapter.queryCapabilities();

    expect(capabilities.deviceSupported, isTrue);
    expect(capabilities.fingerprintAvailable, isTrue);
    expect(capabilities.faceAvailable, isTrue);
    expect(capabilities.deviceCredentialAvailable, isFalse);
    expect(capabilities.enrolledTypes, [
      BiometricType.fingerprint,
      BiometricType.face,
    ]);
  });

  test('authenticate passes the request through and maps success', () async {
    final adapter = MethodChannelFlutterBiometric();
    const request = BiometricAuthRequest(
      reason: '解锁教学凭据',
      strength: BiometricStrength.strongWithCredential,
    );
    mockResponses((method, args) {
      expect(method, BiometricChannelContract.authenticate);
      expect(
        (args as Map<Object?, Object?>)[BiometricChannelContract.argStrength],
        'strongWithCredential',
      );
      return {'status': 'authenticated', 'usedDeviceCredential': true};
    });

    final outcome = await adapter.authenticate(request);

    expect(outcome.isAuthenticated, isTrue);
    expect(outcome.value!.usedDeviceCredential, isTrue);
  });

  test('every native failure status maps to its typed outcome', () async {
    const statuses = {
      'userCancel': BiometricAuthStatus.userCancel,
      'systemCancel': BiometricAuthStatus.systemCancel,
      'timeout': BiometricAuthStatus.timeout,
      'lockout': BiometricAuthStatus.lockout,
      'permanentlyLockedOut': BiometricAuthStatus.permanentlyLockedOut,
      'notEnrolled': BiometricAuthStatus.notEnrolled,
      'noHardware': BiometricAuthStatus.noHardware,
      'hardwareUnavailable': BiometricAuthStatus.hardwareUnavailable,
      'credentialNotSet': BiometricAuthStatus.credentialNotSet,
      'unavailable': BiometricAuthStatus.unavailable,
      'failed': BiometricAuthStatus.failed,
    };
    for (final entry in statuses.entries) {
      final adapter = MethodChannelFlutterBiometric();
      mockResponses(
        (_, _) => {
          'status': entry.key,
          'reason': 'native_reason',
          'message': 'native message',
        },
      );

      final outcome = await adapter.authenticate(
        const BiometricAuthRequest(reason: '验证身份'),
      );

      expect(outcome.status, entry.value, reason: entry.key);
      expect(outcome.reason?.code, 'native_reason');
      expect(outcome.value, isNull);
    }
  });

  test('unknown statuses degrade to invalidData instead of throwing', () async {
    final adapter = MethodChannelFlutterBiometric();
    mockResponses((_, _) => {'status': 'vendor_specific_state'});

    final outcome = await adapter.authenticate(
      const BiometricAuthRequest(reason: '验证身份'),
    );

    expect(outcome.status, BiometricAuthStatus.invalidData);
    expect(outcome.reason?.code, 'unknown_status');
  });

  test('a null reply becomes invalidData', () async {
    final adapter = MethodChannelFlutterBiometric();
    mockResponses((_, _) => null);

    final outcome = await adapter.authenticate(
      const BiometricAuthRequest(reason: '验证身份'),
    );

    expect(outcome.status, BiometricAuthStatus.invalidData);
    expect(outcome.reason?.code, 'null_response');
  });

  test('a PlatformException becomes unavailable, not a throw', () async {
    final adapter = MethodChannelFlutterBiometric();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          throw PlatformException(code: 'boom', message: 'native crash');
        });

    final outcome = await adapter.authenticate(
      const BiometricAuthRequest(reason: '验证身份'),
    );
    final capabilities = await adapter.queryCapabilities();

    expect(outcome.status, BiometricAuthStatus.unavailable);
    expect(outcome.reason?.code, 'platform_exception');
    expect(capabilities.deviceSupported, isFalse);
  });

  test('missing plugin keeps both queries non-throwing', () async {
    final adapter = MethodChannelFlutterBiometric();

    final capabilities = await adapter.queryCapabilities();
    final outcome = await adapter.authenticate(
      const BiometricAuthRequest(reason: '验证身份'),
    );

    expect(capabilities, const BiometricCapabilities.none());
    expect(outcome.status, BiometricAuthStatus.unsupported);
    expect(outcome.reason?.code, 'platform_unsupported');
  });
}
