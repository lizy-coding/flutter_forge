import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_biometric_method_channel.dart';
import 'flutter_biometric_result.dart';

abstract class FlutterBiometricPlatform extends PlatformInterface {
  FlutterBiometricPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterBiometricPlatform _instance = MethodChannelFlutterBiometric();

  /// The default instance of [FlutterBiometricPlatform] to use.
  ///
  /// Defaults to [MethodChannelFlutterBiometric].
  static FlutterBiometricPlatform get instance => _instance;

  static set instance(FlutterBiometricPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Never throws: an adapter without biometric support reports no
  /// capabilities.
  Future<BiometricCapabilities> queryCapabilities() async =>
      const BiometricCapabilities.none();

  Future<void> cancel(String operationId) async {}

  /// Never throws: a platform without an adapter reports unsupported.
  Future<BiometricAuthOutcome> authenticate(
    BiometricAuthRequest request,
  ) async => BiometricAuthOutcome.state(
    BiometricAuthStatus.unsupported,
    'platform_unsupported',
    '当前平台未提供本地认证适配',
  );
}
