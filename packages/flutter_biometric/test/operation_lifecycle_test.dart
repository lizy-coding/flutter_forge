import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_biometric/flutter_biometric.dart';

class PendingPlatform extends FlutterBiometricPlatform {
  final attempts = <Completer<BiometricAuthOutcome>>[];
  final ids = <String>[];
  final cancelled = <String>[];
  @override
  Future<BiometricAuthOutcome> authenticate(BiometricAuthRequest request) {
    ids.add(request.operationId!);
    final pending = Completer<BiometricAuthOutcome>();
    attempts.add(pending);
    return pending.future;
  }

  @override
  Future<void> cancel(String operationId) async {
    cancelled.add(operationId);
  }
}

void main() {
  const request = BiometricAuthRequest(reason: 'test');
  test(
    'closing resolves pending authentication once and rejects new calls',
    () async {
      final platform = PendingPlatform();
      final bridge = FlutterBiometric(platform: platform);
      final pending = bridge.authenticate(request);
      await bridge.close();
      await bridge.close();
      expect((await pending).status, BiometricAuthStatus.systemCancel);
      expect(platform.cancelled, [platform.ids.single]);
      platform.attempts.single.complete(BiometricAuthOutcome.authenticated());
      expect((await bridge.authenticate(request)).reason!.code, 'owner_closed');
    },
  );
  test(
    'busy is rejected; late old completion cannot finish a new operation',
    () async {
      final platform = PendingPlatform();
      final bridge = FlutterBiometric(platform: platform);
      final first = bridge.authenticate(request);
      expect(
        (await bridge.authenticate(request)).reason!.code,
        'authentication_in_progress',
      );
      await bridge.cancel();
      expect((await first).status, BiometricAuthStatus.systemCancel);
      final second = bridge.authenticate(request);
      expect(platform.ids.toSet(), hasLength(2));
      platform.attempts.first.complete(BiometricAuthOutcome.authenticated());
      platform.attempts.last.complete(
        BiometricAuthOutcome.state(
          BiometricAuthStatus.userCancel,
          'cancel',
          'cancelled',
        ),
      );
      expect((await second).status, BiometricAuthStatus.userCancel);
      await bridge.close();
    },
  );
  test('unknown method is successful without inventing a mechanism', () {
    final result = BiometricAuthOutcome.fromMap({
      'status': 'authenticated',
      'authenticationMethod': 'unknown',
    });
    expect(result.isAuthenticated, isTrue);
    expect(result.value!.usedDeviceCredential, isNull);
    expect(
      BiometricAuthOutcome.fromMap({
        'status': 'authenticated',
        'usedDeviceCredential': 'false',
      }).status,
      BiometricAuthStatus.invalidData,
    );
    expect(
      BiometricAuthOutcome.fromMap({'status': 'authenticated'}).status,
      BiometricAuthStatus.invalidData,
    );
  });
}
