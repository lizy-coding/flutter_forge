import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

// Pump a bounded number of frames, including continuously animated pages.
// Avoid pumpAndSettle for GPU, media and streaming surfaces.
Future<void> waitForCondition(
  WidgetTester tester,
  FutureOr<bool> Function() ready, {
  required String reason,
  Duration timeout = const Duration(seconds: 8),
  Duration step = const Duration(milliseconds: 80),
}) async {
  if (timeout <= Duration.zero || step <= Duration.zero) {
    throw ArgumentError('Polling duration and step must be positive');
  }
  final clock = Stopwatch()..start();
  var elapsed = Duration.zero;
  while (true) {
    final used = elapsed > clock.elapsed ? elapsed : clock.elapsed;
    final remaining = timeout - used;
    if (remaining <= Duration.zero) fail(reason);
    final value = ready();
    if (value is Future<bool> ? await value.timeout(remaining) : value) return;
    final frame = remaining < step ? remaining : step;
    await tester.pump(frame);
    elapsed += frame;
  }
}

Future<void> waitForWidget(WidgetTester tester, Finder finder) =>
    waitForCondition(
      tester,
      () => finder.evaluate().isNotEmpty,
      reason: 'Widget did not appear: $finder',
    );

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await waitForWidget(tester, finder);
  expect(finder, findsOneWidget);
  await Scrollable.ensureVisible(tester.element(finder), alignment: 0.5);
  await tester.pump();
  await waitForCondition(
    tester,
    () => finder.hitTestable().evaluate().length == 1,
    reason: 'Control is obscured or cannot receive input: $finder',
  );
  await tester.tap(finder);
  await pumpFrames(tester, const Duration(milliseconds: 450));
}

Future<void> pumpFrames(WidgetTester tester, Duration duration) async {
  const step = Duration(milliseconds: 50);
  for (var elapsed = Duration.zero; elapsed < duration; elapsed += step) {
    await tester.pump(step);
  }
}

void expectNoFlutterErrors(WidgetTester tester, String action) {
  final errors = <Object>[];
  Object? error;
  while ((error = tester.takeException()) != null) {
    errors.add(error!);
  }
  expect(errors, isEmpty, reason: action);
}
