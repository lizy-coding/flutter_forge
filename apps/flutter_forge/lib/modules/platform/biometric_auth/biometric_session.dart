import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_biometric/flutter_biometric.dart';

/// One module session: capability query results, prompt outcomes and the
/// event log learners observe. All native access stays behind the typed
/// bridge interface so the session is fully testable with fakes.
class BiometricSession extends ChangeNotifier {
  BiometricSession(this._biometric);

  final FlutterBiometric _biometric;

  BiometricCapabilities? capabilities;
  BiometricAuthOutcome? lastOutcome;
  bool loading = false;
  bool _closed = false;
  final _disposed = Completer<void>();
  Future<T> _owned<T>(Future<T> operation) => Future.any([
    operation,
    _disposed.future.then<T>((_) => throw const _SessionClosed()),
  ]);
  int _epoch = 0;
  bool _current(int epoch) => !_closed && epoch == _epoch;

  @override
  void dispose() {
    if (_closed) return;
    _closed = true;
    _disposed.complete();
    ++_epoch;
    loading = false;
    unawaited(_biometric.close());
    super.dispose();
  }

  final List<String> logs = [];

  Future<void> initialize() async {
    if (_closed || loading) return;
    final epoch = ++_epoch;
    loading = true;
    notifyListeners();
    try {
      final result = await _owned(_biometric.queryCapabilities());
      if (!_current(epoch)) return;
      capabilities = result;
    } on _SessionClosed {
      return;
    } finally {
      if (_current(epoch)) {
        loading = false;
        notifyListeners();
      }
    }
  }

  bool get hasFingerprint => capabilities?.fingerprintAvailable ?? false;
  bool get hasFace => capabilities?.faceAvailable ?? false;
  bool get hasCredentialFallback =>
      capabilities?.deviceCredentialAvailable ?? false;

  String get capabilityText {
    final caps = capabilities;
    if (caps == null) return '正在查询本机能力…';
    if (!caps.deviceSupported) {
      return '本机未提供可用的生物识别或设备凭据，模块进入降级展示。';
    }
    final types = [
      if (caps.fingerprintAvailable) '指纹',
      if (caps.faceAvailable) '面容',
    ];
    final prefix = caps.sensorEnrollmentKnown ? '已录入：' : '硬件线索（不证明逐类已录入）：';
    final credential = caps.deviceCredentialAvailable ? '（支持凭据回退）' : '（无凭据回退）';
    return '$prefix${types.isEmpty ? '无' : types.join('、')}$credential';
  }

  String get outcomeText {
    final outcome = lastOutcome;
    if (outcome == null) return '尚未发起认证。';
    if (outcome.isAuthenticated) {
      return switch (outcome.value!.method) {
        BiometricAuthenticationMethod.deviceCredential => '认证成功：本次由设备凭据完成',
        BiometricAuthenticationMethod.biometric => '认证成功：本次由生物特征完成',
        BiometricAuthenticationMethod.unknown => '认证成功：系统未披露本次认证方式（unknown）',
      };
    }
    return '认证未通过：${outcome.status.name}（${outcome.reason?.code ?? 'unspecified_reason'}）'
        '${outcome.reason == null ? '' : ' —— ${outcome.reason!.message}'}';
  }

  Future<void> authenticate(BiometricStrength strength) async {
    if (_closed || loading) return;
    final epoch = ++_epoch;
    loading = true;
    notifyListeners();
    final label = switch (strength) {
      BiometricStrength.strong => '强生物识别',
      BiometricStrength.weak => '弱或更强生物识别',
      BiometricStrength.strongWithCredential => '凭据回退认证',
    };
    logs.add('发起 $label（strength=${strength.name}）');
    notifyListeners();

    try {
      final outcome = await _owned(
        _biometric.authenticate(
          BiometricAuthRequest(
            reason: '验证身份以继续本模块的教学实验',
            strength: strength,
            title: '生物特征与本地认证',
          ),
        ),
      );
      if (!_current(epoch)) return;
      lastOutcome = outcome;
      logs.add(
        '返回 ${outcome.status.name}'
        '${outcome.reason == null ? '' : '（${outcome.reason!.code}）'}',
      );
    } on _SessionClosed {
      return;
    } finally {
      if (_current(epoch)) {
        loading = false;
        notifyListeners();
      }
    }
  }
}

class _SessionClosed implements Exception {
  const _SessionClosed();
}
