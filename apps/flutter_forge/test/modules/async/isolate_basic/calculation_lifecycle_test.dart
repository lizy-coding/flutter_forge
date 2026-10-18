import 'dart:async';
import 'dart:isolate';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_forge_app/modules/async/isolate_basic/with_isolate_page.dart';

void idleWorker(dynamic _) {
  ReceivePort();
}

void main() {
  testWidgets('leaving during spawn terminates the late calculation handle', (
    tester,
  ) async {
    final exited = ReceivePort();
    final worker = await tester.runAsync(
      () => Isolate.spawn(
        idleWorker,
        null,
        paused: true,
        onExit: exited.sendPort,
      ),
    );
    final gate = Completer<Isolate>();
    try {
      await tester.pumpWidget(
        MaterialApp(home: WithIsolatePage(spawn: (_, __) => gate.future)),
      );
      await tester.tap(find.text('开始计算'));
      await tester.pump();
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      gate.complete(worker!);
      await tester.pump();
      await tester.runAsync(
        () => exited.first.timeout(const Duration(seconds: 2)),
      );
      expect(tester.takeException(), isNull);
    } finally {
      worker?.kill(priority: Isolate.immediate);
      exited.close();
    }
  });

  testWidgets('a failed spawn stops loading and allows another calculation', (
    tester,
  ) async {
    var attempts = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: WithIsolatePage(
          spawn: (_, __) async {
            attempts++;
            throw StateError('controlled spawn failure');
          },
        ),
      ),
    );
    await tester.tap(find.text('开始计算'));
    await tester.pump();
    expect(find.textContaining('controlled spawn failure'), findsOneWidget);
    expect(find.text('开始计算'), findsOneWidget);
    await tester.tap(find.text('开始计算'));
    await tester.pump();
    expect(attempts, 2);
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    expect(tester.takeException(), isNull);
  });
}
