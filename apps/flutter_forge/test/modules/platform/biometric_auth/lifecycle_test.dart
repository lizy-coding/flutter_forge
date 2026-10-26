import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_biometric/flutter_biometric.dart';
import 'package:flutter_forge_app/modules/platform/biometric_auth/biometric_session.dart';

class PendingPlatform extends FlutterBiometricPlatform {
  final pending = Completer<BiometricCapabilities>();
  @override
  Future<BiometricCapabilities> queryCapabilities() => pending.future;
}

class ControlledPlatform extends FlutterBiometricPlatform {
  final pending = Completer<BiometricAuthOutcome>();
  final cancelled = <String>[];
  int requests = 0;
  bool failQuery = false;
  @override
  Future<BiometricCapabilities> queryCapabilities() async {
    if (failQuery) throw StateError('programming error');
    return const BiometricCapabilities.none();
  }

  @override
  Future<BiometricAuthOutcome> authenticate(BiometricAuthRequest request) {
    requests++;
    return pending.future;
  }

  @override
  Future<void> cancel(String operationId) async {
    cancelled.add(operationId);
  }
}

void main() {
  test(
    'dispose during authentication cancels once and ignores native success',
    () async {
      final platform = ControlledPlatform();
      final session = BiometricSession(FlutterBiometric(platform: platform));
      final pending = session.authenticate(
        BiometricStrength.strongWithCredential,
      );
      await session.authenticate(BiometricStrength.strong);
      await session.initialize();
      expect(platform.requests, 1);
      final logs = List.of(session.logs);
      session.dispose();
      session.dispose();
      await pending.timeout(const Duration(seconds: 1));
      expect(platform.cancelled, hasLength(1));
      platform.pending.complete(BiometricAuthOutcome.authenticated());
      await Future<void>.delayed(Duration.zero);
      expect(session.logs, logs);
      expect(session.lastOutcome, isNull);
      await session.authenticate(BiometricStrength.weak);
      expect(platform.requests, 1);
    },
  );
  test(
    'unexpected query error releases loading and stays visible to tests; retry works',
    () async {
      final platform = ControlledPlatform()..failQuery = true;
      final session = BiometricSession(FlutterBiometric(platform: platform));
      await expectLater(session.initialize(), throwsStateError);
      expect(session.loading, isFalse);
      platform.failQuery = false;
      await session.initialize();
      expect(session.capabilities, isNotNull);
      session.dispose();
    },
  );

  test('dispose during query ignores late result and future calls', () async {
    final platform = PendingPlatform();
    final session = BiometricSession(FlutterBiometric(platform: platform));
    final opening = session.initialize();
    session.dispose();
    await opening.timeout(const Duration(seconds: 1));
    platform.pending.complete(const BiometricCapabilities.none());
    await opening;
    expect(session.capabilities, isNull);
    await session.initialize();
  });
}
