import 'package:flutter/material.dart';
import 'package:flutter_forge_app/modules/platform/bluetooth_ble/module_root.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

// Opt-in real radio workflow. A skipped run is not hardware acceptance.
const _hardwareAcceptance = bool.fromEnvironment('BLE_HARDWARE_ACCEPTANCE');

Future<void> _waitFor(
  WidgetTester tester,
  bool Function() ready,
  String failure, {
  Duration limit = const Duration(seconds: 20),
}) async {
  final deadline = DateTime.now().add(limit);
  while (!ready() && DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 200));
  }
  expect(ready(), isTrue, reason: failure);
}

int _discoveredCount(WidgetTester tester) {
  final label = tester.widget<Text>(find.textContaining('累计发现 ')).data!;
  return int.parse(RegExp(r'累计发现 (\d+) 台').firstMatch(label)!.group(1)!);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'real BLE scan stops on confirmation and retains results on rescan',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: BluetoothBlePage()));
      await _waitFor(
        tester,
        () =>
            find.text('适配器：已开启').evaluate().isNotEmpty &&
            find.text('权限：已授予').evaluate().isNotEmpty,
        'Require a real Bluetooth adapter and approval of this build in the system permission prompt.',
        limit: const Duration(seconds: 45),
      );

      final scan = find.byKey(const Key('ble-scan'));
      final stop = find.byKey(const Key('ble-stop-scan'));
      final status = find.byKey(const Key('ble-scan-status'));
      bool running() => tester.widget<Text>(status).data!.startsWith('剩余 ');
      bool stopped() => tester.widget<Text>(status).data!.startsWith('手动停止');

      await tester.ensureVisible(scan);
      await tester.tap(scan);
      await _waitFor(
        tester,
        running,
        'Native scan did not enter the running state.',
      );
      await tester.pump(const Duration(seconds: 2));
      final beforeStop = _discoveredCount(tester);
      await tester.ensureVisible(stop);
      await tester.tap(stop);
      await _waitFor(tester, stopped, 'Native scan stop was not confirmed.');
      expect(_discoveredCount(tester), greaterThanOrEqualTo(beforeStop));

      final retained = _discoveredCount(tester);
      await tester.tap(scan);
      await _waitFor(tester, running, 'Rescan did not start.');
      expect(_discoveredCount(tester), greaterThanOrEqualTo(retained));
      await tester.tap(stop);
      await _waitFor(tester, stopped, 'Rescan stop was not confirmed.');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
    skip: !_hardwareAcceptance,
  );
}
