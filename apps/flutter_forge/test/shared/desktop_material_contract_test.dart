import 'package:flutter_test/flutter_test.dart';
import '../support/desktop_material_contract.dart';

void main() {
  test('Win10 permits solid while system transparency is allowed', () {
    expectDesktopMaterial({
      'materialActive': false,
      'transparencyAllowed': true,
      'systemBackdropSupported': false,
    }, macOS: false);
  });
  test('Win11 permits enabled material and initialization fallback', () {
    for (final active in [true, false]) {
      expectDesktopMaterial({
        'materialActive': active,
        'transparencyAllowed': true,
        'systemBackdropSupported': true,
      }, macOS: false);
    }
  });
  test('disabled transparency rejects active material', () {
    expect(
      () => expectDesktopMaterial({
        'materialActive': true,
        'transparencyAllowed': false,
        'systemBackdropSupported': true,
      }, macOS: false),
      throwsA(isA<TestFailure>()),
    );
  });
  test('unsupported backdrop rejects active material', () {
    expect(
      () => expectDesktopMaterial({
        'materialActive': true,
        'transparencyAllowed': true,
        'systemBackdropSupported': false,
      }, macOS: false),
      throwsA(isA<TestFailure>()),
    );
  });
  test('macOS retains the existing allowed versus active assertion', () {
    for (final allowed in [true, false]) {
      expectDesktopMaterial({
        'materialActive': allowed,
        'transparencyAllowed': allowed,
      }, macOS: true);
    }
    expect(
      () => expectDesktopMaterial({
        'materialActive': false,
        'transparencyAllowed': true,
      }, macOS: true),
      throwsA(isA<TestFailure>()),
    );
  });
}
