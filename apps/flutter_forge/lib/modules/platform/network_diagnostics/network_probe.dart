import 'diagnostic_models.dart';
import 'network_probe_unavailable.dart'
    if (dart.library.io) 'desktop_network_probe.dart'
    as backend;

abstract interface class NetworkProbe {
  Future<NetworkSnapshot> snapshot(DiagnosticCancellation cancellation);
  Future<ProbeSample> probe(
    DiagnosticTarget target,
    int round,
    DiagnosticCancellation cancellation,
  );
}

NetworkProbe createNetworkProbe() => backend.createNetworkProbe();
