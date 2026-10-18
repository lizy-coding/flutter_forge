import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_forge_app/modules/platform/usb_network/module_entry.dart';

import 'fake_usb_network.dart';

void main() {
  testWidgets('scan, connect, exchange and disconnect through the page', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final adapter = FakeUsbAdapter();
    await tester.pumpWidget(
      MaterialApp(home: UsbNetworkEntry(adapter: adapter)),
    );
    await tester.tap(find.text('扫描 NCM 网卡'));
    await tester.pumpAndSettle();
    expect(find.textContaining('192.168.7.1/24'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('usb-host')), '192.168.7.2');
    await tester.enterText(find.byKey(const Key('usb-port')), '1234');
    await tester.tap(find.text('连接'));
    await tester.pumpAndSettle();
    expect(find.text('已连接'), findsOneWidget);
    await tester.ensureVisible(find.text('发送'));
    await tester.tap(find.text('发送'));
    await tester.pumpAndSettle();
    expect(utf8.decode(adapter.connection.sent.single), 'hello\n');
    adapter.connection.incoming.add(
      Uint8List.fromList(utf8.encode('echo hello')),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('echo hello'), findsOneWidget);
    await tester.ensureVisible(find.text('断开'));
    await tester.runAsync(() async {
      await tester.tap(find.text('断开'));
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pumpAndSettle();
    await tester.pump();
    expect(adapter.connection.closeCalls, 1);
    expect(find.text('未连接'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('compact layout, large text and empty interface state', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final adapter = FakeUsbAdapter()..interfaces = [];
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.4)),
          child: child!,
        ),
        home: UsbNetworkEntry(adapter: adapter),
      ),
    );
    await tester.tap(find.text('扫描 NCM 网卡'));
    await tester.pumpAndSettle();
    expect(find.text('未发现可用 NCM 网卡'), findsWidgets);
    expect(tester.takeException(), isNull);
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, '连接'),
    );
    expect(button.onPressed, isNull);
    await tester.ensureVisible(find.text('发送'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
