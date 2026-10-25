import 'package:flutter/material.dart';
import 'package:flutter_forge_app/modules/platform/biometric_auth/biometric_session.dart';
import 'package:flutter_forge_app/modules/platform/biometric_auth/module_entry.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_biometric/flutter_biometric.dart';

class FakeBiometricPlatform extends FlutterBiometricPlatform {
  BiometricCapabilities capabilities = const BiometricCapabilities(
    deviceSupported: true,
    fingerprintAvailable: true,
    faceAvailable: false,
    deviceCredentialAvailable: true,
    enrolledTypes: [BiometricType.fingerprint],
  );
  BiometricAuthOutcome outcome = BiometricAuthOutcome.authenticated();
  final requests = <BiometricAuthRequest>[];

  @override
  Future<BiometricCapabilities> queryCapabilities() async => capabilities;

  @override
  Future<BiometricAuthOutcome> authenticate(
    BiometricAuthRequest request,
  ) async {
    requests.add(request);
    return outcome;
  }
}

FlutterBiometric fakeBridge(FakeBiometricPlatform platform) =>
    FlutterBiometric(platform: platform);

void main() {
  group(BiometricSession, () {
    test('initialize reads runtime capabilities from the bridge', () async {
      final platform = FakeBiometricPlatform();
      final session = BiometricSession(fakeBridge(platform));

      await session.initialize();

      expect(session.hasFingerprint, isTrue);
      expect(session.hasFace, isFalse);
      expect(session.hasCredentialFallback, isTrue);
      expect(session.capabilityText, contains('指纹'));
      expect(session.capabilityText, isNot(contains('面容：')));
    });

    test('a device without support degrades the summary text', () async {
      final platform = FakeBiometricPlatform()
        ..capabilities = const BiometricCapabilities.none();
      final session = BiometricSession(fakeBridge(platform));

      await session.initialize();

      expect(session.capabilityText, contains('降级'));
    });

    test('authenticate forwards the request and reports success', () async {
      final platform = FakeBiometricPlatform();
      final session = BiometricSession(fakeBridge(platform));

      await session.authenticate(BiometricStrength.strong);

      expect(platform.requests.single.strength, BiometricStrength.strong);
      expect(platform.requests.single.reason, isNotEmpty);
      expect(session.outcomeText, contains('认证成功'));
      expect(session.logs.last, contains('authenticated'));
    });

    test('failure outcomes surface their stable reason code', () async {
      final platform = FakeBiometricPlatform()
        ..outcome = BiometricAuthOutcome.state(
          BiometricAuthStatus.notEnrolled,
          'android_error_11',
          '未录入生物特征',
        );
      final session = BiometricSession(fakeBridge(platform));

      await session.authenticate(BiometricStrength.strong);

      expect(session.outcomeText, contains('notEnrolled'));
      expect(session.outcomeText, contains('android_error_11'));
    });
  });

  testWidgets('entry renders capabilities and completes a fingerprint flow', (
    tester,
  ) async {
    final platform = FakeBiometricPlatform();
    await tester.pumpWidget(
      MaterialApp(home: BiometricAuthEntry(biometric: fakeBridge(platform))),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('已录入：指纹'), findsOneWidget);
    expect(find.text('面容认证'), findsOneWidget);
    // Face is unavailable on this fake, so its button stays disabled.
    final faceButton = tester.widget<FilledButton>(
      find.ancestor(of: find.text('面容认证'), matching: find.byType(FilledButton)),
    );
    expect(faceButton.onPressed, isNull);

    await tester.tap(find.text('指纹认证'));
    await tester.pumpAndSettle();

    expect(find.textContaining('认证成功'), findsOneWidget);
    expect(platform.requests, hasLength(1));
  });

  testWidgets('entry disables every action on unsupported devices', (
    tester,
  ) async {
    final platform = FakeBiometricPlatform()
      ..capabilities = const BiometricCapabilities.none();
    await tester.pumpWidget(
      MaterialApp(home: BiometricAuthEntry(biometric: fakeBridge(platform))),
    );
    await tester.pumpAndSettle();

    final fingerprintButton = tester.widget<FilledButton>(
      find.ancestor(of: find.text('指纹认证'), matching: find.byType(FilledButton)),
    );
    expect(fingerprintButton.onPressed, isNull);
    expect(find.textContaining('本机未提供可用的生物识别'), findsOneWidget);
  });
}
