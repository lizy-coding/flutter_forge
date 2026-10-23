import 'diagnostic_models.dart';
import 'network_probe.dart';

NetworkProbe createNetworkProbe() => _UnavailableProbe();

class _UnavailableProbe implements NetworkProbe {
  @override
  Future<NetworkSnapshot> snapshot(DiagnosticCancellation cancellation) async =>
      throw UnsupportedError('当前宿主未接入网络诊断能力');

  @override
  Future<ProbeSample> probe(
    DiagnosticTarget target,
    int round,
    DiagnosticCancellation cancellation,
  ) async => throw UnsupportedError('当前宿主未接入网络诊断能力');
}
