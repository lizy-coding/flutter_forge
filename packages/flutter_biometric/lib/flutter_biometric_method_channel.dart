import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'flutter_biometric_platform_interface.dart';
import 'flutter_biometric_result.dart';
import 'src/biometric_channel_contract.dart';

/// Method channel adapter; every failure path resolves to a typed outcome
/// instead of throwing across the channel boundary.
class MethodChannelFlutterBiometric extends FlutterBiometricPlatform {
  @visibleForTesting
  final methodChannel = const MethodChannel(
    BiometricChannelContract.methodChannel,
  );

  @override
  Future<BiometricCapabilities> queryCapabilities() async {
    try {
      final map = await methodChannel
          .invokeMethod<Object?>(BiometricChannelContract.queryCapabilities)
          .timeout(const Duration(seconds: 10));
      if (map is Map<Object?, Object?> &&
          [
            'deviceSupported',
            'fingerprintAvailable',
            'faceAvailable',
            'deviceCredentialAvailable',
            'strongAvailable',
            'weakAvailable',
            'sensorEnrollmentKnown',
          ].every((key) => map[key] == null || map[key] is bool)) {
        return BiometricCapabilities.fromMap(map);
      }
      return const BiometricCapabilities.none();
    } on TimeoutException {
      return const BiometricCapabilities.none();
    } on PlatformException {
      return const BiometricCapabilities.none();
    } on MissingPluginException {
      return const BiometricCapabilities.none();
    }
  }

  @override
  Future<void> cancel(String operationId) async {
    try {
      await methodChannel
          .invokeMethod<void>(BiometricChannelContract.cancel, {
            BiometricChannelContract.argOperationId: operationId,
          })
          .timeout(const Duration(seconds: 5));
    } on PlatformException {
      return;
    } on MissingPluginException {
      return;
    } on TimeoutException {
      return;
    }
  }

  @override
  Future<BiometricAuthOutcome> authenticate(
    BiometricAuthRequest request,
  ) async {
    try {
      final map = await methodChannel.invokeMethod<Object?>(
        BiometricChannelContract.authenticate,
        request.toMap(),
      );
      return BiometricAuthOutcome.fromMap(map);
    } on PlatformException catch (error) {
      return BiometricAuthOutcome.state(
        BiometricAuthStatus.unavailable,
        'platform_exception',
        error.message ?? 'Platform channel reported an error',
      );
    } on MissingPluginException {
      return BiometricAuthOutcome.state(
        BiometricAuthStatus.unsupported,
        'platform_unsupported',
        '当前平台未提供本地认证适配',
      );
    }
  }
}
