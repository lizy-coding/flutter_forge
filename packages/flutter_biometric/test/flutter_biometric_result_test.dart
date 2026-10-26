import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_biometric/flutter_biometric.dart';

void main() {
  group(BiometricAuthOutcome, () {
    test('authenticated carries a value', () {
      final outcome = BiometricAuthOutcome.authenticated(
        usedDeviceCredential: true,
      );

      expect(outcome.isAuthenticated, isTrue);
      expect(outcome.value!.usedDeviceCredential, isTrue);
      expect(outcome.reason, isNull);
    });

    test('state outcomes never carry a value', () {
      final outcome = BiometricAuthOutcome.state(
        BiometricAuthStatus.notEnrolled,
        'not_enrolled',
        '请在系统设置录入生物特征',
      );

      expect(outcome.isAuthenticated, isFalse);
      expect(outcome.value, isNull);
      expect(outcome.reason?.code, 'not_enrolled');
    });

    test('authenticated is not constructible as a state outcome', () {
      expect(
        () => BiometricAuthOutcome.state(
          BiometricAuthStatus.authenticated,
          'invalid',
          'authenticated must carry a value',
        ),
        throwsArgumentError,
      );
    });

    test('blank reason codes collapse to unspecified_reason', () {
      final outcome = BiometricAuthOutcome.state(
        BiometricAuthStatus.failed,
        '   ',
        '',
      );

      expect(outcome.reason?.code, 'unspecified_reason');
      expect(outcome.reason?.message, 'No additional detail');
    });

    test('fromMap keeps every field of an authenticated reply', () {
      final outcome = BiometricAuthOutcome.fromMap({
        'status': 'authenticated',
        'usedDeviceCredential': true,
      });

      expect(outcome.isAuthenticated, isTrue);
      expect(outcome.value!.usedDeviceCredential, isTrue);
    });
  });

  group(BiometricCapabilities, () {
    test('none reports no support', () {
      const capabilities = BiometricCapabilities.none();

      expect(capabilities.deviceSupported, isFalse);
      expect(capabilities.fingerprintAvailable, isFalse);
      expect(capabilities.faceAvailable, isFalse);
      expect(capabilities.deviceCredentialAvailable, isFalse);
      expect(capabilities.enrolledTypes, isEmpty);
    });

    test('fromMap ignores unknown biometric types', () {
      final capabilities = BiometricCapabilities.fromMap({
        'deviceSupported': true,
        'fingerprintAvailable': true,
        'faceAvailable': false,
        'deviceCredentialAvailable': true,
        'enrolledTypes': ['fingerprint', 'iris', 42],
      });

      expect(capabilities.enrolledTypes, [BiometricType.fingerprint]);
      expect(capabilities.deviceCredentialAvailable, isTrue);
    });

    test('fromMap tolerates a missing type list', () {
      final capabilities = BiometricCapabilities.fromMap({
        'fingerprintAvailable': true,
      });

      expect(capabilities.enrolledTypes, isEmpty);
      expect(capabilities.faceAvailable, isFalse);
    });
  });

  test('requests serialize every prompt field', () {
    const request = BiometricAuthRequest(
      reason: '解锁教学凭据',
      strength: BiometricStrength.weak,
      subtitle: '请验证指纹或面容',
    );
    final map = request.toMap();

    expect(map['reason'], '解锁教学凭据');
    expect(map['strength'], 'weak');
    expect(map['title'], '身份验证');
    expect(map['subtitle'], '请验证指纹或面容');
    expect(map['negativeLabel'], '取消');
  });
}
