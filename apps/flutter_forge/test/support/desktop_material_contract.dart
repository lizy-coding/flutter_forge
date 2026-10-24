import 'package:flutter_test/flutter_test.dart';

void expectDesktopMaterial(Map<dynamic, dynamic> state, {required bool macOS}) {
  final active = state['materialActive'];
  final allowed = state['transparencyAllowed'];
  expect(active, isA<bool>());
  expect(allowed, isA<bool>());
  if (macOS) {
    expect(active, allowed);
  } else {
    expect(state['systemBackdropSupported'], isA<bool>());
    if (allowed == false || state['systemBackdropSupported'] == false) {
      expect(active, isFalse);
    }
    // API support does not guarantee initialization succeeds; solid is valid.
    if (active == true) expect(allowed, isTrue);
  }
}
