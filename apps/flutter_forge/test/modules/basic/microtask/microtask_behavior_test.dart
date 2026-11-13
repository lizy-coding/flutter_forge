import 'package:flutter/material.dart';
import 'package:flutter_forge_app/modules/basic/microtask/models/event_log.dart';
import 'package:flutter_forge_app/modules/basic/microtask/pages/microtask_queue_page.dart';
import 'package:flutter_forge_app/modules/basic/microtask/widgets/event_log_view.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _runTest(WidgetTester tester, String label) async {
  await tester.pumpWidget(const MaterialApp(home: MicrotaskQueuePage()));
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text(label));
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

Finder _logScrollable() => find
    .descendant(
      of: find.byType(EventLogView),
      matching: find.byType(Scrollable),
    )
    .first;

void main() {
  test('EventLog formats type prefixes and messages', () {
    final log = EventLog(message: '开始', type: EventType.microtask, id: 1);
    expect(log.formattedMessage, '【微任务】开始');
    expect(log.color, Colors.blue);

    final sync = EventLog(message: '同步', type: EventType.sync, id: 2);
    expect(sync.formattedMessage, '【同步】同步');
    expect(sync.color, Colors.black);

    final event = EventLog(message: '事件', type: EventType.event, id: 3);
    expect(event.formattedMessage, '【事件任务】事件');
    expect(event.color, Colors.red);
  });

  testWidgets('basic run lists sync code, microtasks, then event tasks', (
    tester,
  ) async {
    await _runTest(tester, '基础微任务测试');

    // The visible window only holds the first rows: microtasks already sit
    // in the log while the event task needs scrolling to reach, which is
    // the teaching point — microtasks are drained first.
    expect(find.textContaining('代码开始执行'), findsOneWidget);
    expect(find.textContaining('微任务1执行'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.textContaining('事件任务执行').first,
      100,
      scrollable: _logScrollable(),
    );
    // Drain the closing timer so no timer is pending at teardown; the
    // closing row itself sits below the virtualized window, so only
    // advance the clock without asserting its visibility.
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('nested microtask run drains nested microtasks into the log', (
    tester,
  ) async {
    await _runTest(tester, '嵌套微任务测试');

    expect(find.textContaining('外层微任务1执行'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.textContaining('二层嵌套微任务执行'),
      100,
      scrollable: _logScrollable(),
    );
    expect(find.textContaining('二层嵌套微任务执行'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('clear button empties the log list', (tester) async {
    await _runTest(tester, '基础微任务测试');
    expect(find.textContaining('代码开始执行'), findsOneWidget);
    // Let the run's closing timer fire before teardown.
    await tester.pump(const Duration(seconds: 3));

    await tester.tap(find.byIcon(Icons.delete));
    await tester.pumpAndSettle();
    expect(find.textContaining('代码开始执行'), findsNothing);
  });
}
