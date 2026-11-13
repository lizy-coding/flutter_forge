import 'dart:async';
import 'flutter_biometric_platform_interface.dart';
import 'flutter_biometric_result.dart';

export 'flutter_biometric_method_channel.dart';
export 'flutter_biometric_platform_interface.dart';
export 'flutter_biometric_result.dart';
export 'src/biometric_channel_contract.dart';

/// Entry point of the plugin: consumers talk to [FlutterBiometricPlatform]
/// and typed results only, never to the method channel directly.
class FlutterBiometric {
  FlutterBiometric({FlutterBiometricPlatform? platform})
    : _platform = platform ?? FlutterBiometricPlatform.instance;

  final FlutterBiometricPlatform _platform;

  /// Runtime adapter capabilities, complementary to any static platform
  /// matrix: static rules gate the feature entry, this gate decides which
  /// sensors are usable on the actual device.
  Future<BiometricCapabilities> queryCapabilities() =>
      _platform.queryCapabilities();

  static int _nextOperation = 0;
  String? _activeId;
  Completer<BiometricAuthOutcome>? _cancelled;
  bool _closed = false;

  Future<BiometricAuthOutcome> authenticate(
    BiometricAuthRequest request,
  ) async {
    if (_closed || _activeId != null) {
      return BiometricAuthOutcome.state(
        BiometricAuthStatus.unavailable,
        _closed ? 'owner_closed' : 'authentication_in_progress',
        'Authentication owner is unavailable',
      );
    }
    final id = '${DateTime.now().microsecondsSinceEpoch}/${++_nextOperation}';
    _activeId = id;
    final cancelled = Completer<BiometricAuthOutcome>();
    _cancelled = cancelled;
    try {
      return await Future.any([
        _platform.authenticate(
          BiometricAuthRequest(
            reason: request.reason,
            strength: request.strength,
            title: request.title,
            subtitle: request.subtitle,
            negativeLabel: request.negativeLabel,
            operationId: id,
          ),
        ),
        cancelled.future,
      ]);
    } finally {
      if (_activeId == id) {
        _activeId = null;
        _cancelled = null;
      }
    }
  }

  Future<void> cancel() async {
    final id = _activeId;
    if (id == null) return;
    final pending = _cancelled;
    if (pending != null && !pending.isCompleted) {
      pending.complete(
        BiometricAuthOutcome.state(
          BiometricAuthStatus.systemCancel,
          'owner_cancelled',
          'Authentication owner cancelled',
        ),
      );
    }
    await _platform.cancel(id);
  }

  Future<void>? _closing;
  Future<void> close() {
    _closed = true;
    return _closing ??= cancel();
  }
}
