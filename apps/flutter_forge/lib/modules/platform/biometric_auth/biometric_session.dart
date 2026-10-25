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
  final List<String> logs = [];

  Future<void> initialize() async {
    loading = true;
    notifyListeners();
    capabilities = await _biometric.queryCapabilities();
    loading = false;
    notifyListeners();
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
    final credential = caps.deviceCredentialAvailable ? '（支持凭据回退）' : '（无凭据回退）';
    return '已录入：${types.isEmpty ? '无' : types.join('、')}$credential';
  }

  String get outcomeText {
    final outcome = lastOutcome;
    if (outcome == null) return '尚未发起认证。';
    if (outcome.isAuthenticated) {
      return outcome.value!.usedDeviceCredential
          ? '认证成功：本次由设备凭据完成（原因码 usedDeviceCredential=true）'
          : '认证成功：本次由生物特征完成';
    }
    return '认证未通过：${outcome.status.name}（${outcome.reason?.code ?? 'unspecified_reason'}）'
        '${outcome.reason == null ? '' : ' —— ${outcome.reason!.message}'}';
  }

  Future<void> authenticate(BiometricStrength strength) async {
    if (loading) return;
    loading = true;
    notifyListeners();
    final label = switch (strength) {
      BiometricStrength.strong => '指纹认证',
      BiometricStrength.weak => '面容认证',
      BiometricStrength.strongWithCredential => '凭据回退认证',
    };
    logs.add('发起 $label（strength=${strength.name}）');
    notifyListeners();

    final outcome = await _biometric.authenticate(
      BiometricAuthRequest(
        reason: '验证身份以继续本模块的教学实验',
        strength: strength,
        title: '生物特征与本地认证',
      ),
    );
    lastOutcome = outcome;
    logs.add(
      '返回 ${outcome.status.name}'
      '${outcome.reason == null ? '' : '（${outcome.reason!.code}）'}',
    );
    loading = false;
    notifyListeners();
  }
}
