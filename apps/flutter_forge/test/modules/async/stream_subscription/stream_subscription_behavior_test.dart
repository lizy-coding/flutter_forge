import 'package:flutter/material.dart';
import 'package:flutter_forge_app/modules/async/stream_subscription/pages/stream_demo_controller.dart';
import 'package:flutter_forge_app/modules/async/stream_subscription/pages/stream_demo_page.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StreamDemoController', () {
    test('subscribe and unsubscribe toggle the subscription state', () async {
      final controller = StreamDemoController();
      addTearDown(controller.dispose);

      expect(controller.isSubscribed, isFalse);
      controller.subscribe();
      expect(controller.isSubscribed, isTrue);

      controller.unsubscribe();
      await Future<void>.delayed(Duration.zero);
      expect(controller.isSubscribed, isFalse);
    });

    test(
      'periodic push delivers messages to the active subscription',
      () async {
        final controller = StreamDemoController();
        addTearDown(controller.dispose);
        controller.setInterval(1);
        controller.subscribe();
        controller.start();
        await Future<void>.delayed(const Duration(milliseconds: 1300));
        controller.stop();

        expect(controller.isPushing, isFalse);
        expect(controller.messages, isNotEmpty);
        expect(controller.messages.first, startsWith('模拟消息 #1'));
      },
    );

    test('injected errors surface as message entries', () async {
      final controller = StreamDemoController();
      addTearDown(controller.dispose);
      controller.subscribe();
      controller.start();
      controller.addError();
      await Future<void>.delayed(Duration.zero);
      controller.stop();

      expect(controller.messages, contains('错误: 模拟错误事件'));
    });

    test('closing the stream resets the demo state', () async {
      final controller = StreamDemoController();
      addTearDown(controller.dispose);
      controller.setInterval(1);
      controller.subscribe();
      controller.start();
      await Future<void>.delayed(const Duration(milliseconds: 1300));
      controller.closeStream();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(controller.isPushing, isFalse);
      expect(controller.messages, isEmpty);
      expect(controller.isSubscribed, isFalse);
    });

    test('setInterval ignores non-positive values', () {
      final controller = StreamDemoController();
      addTearDown(controller.dispose);
      controller.setInterval(0);
      expect(controller.interval, 2);
    });
  });

  testWidgets('page wires push and subscription controls', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: StreamDemoPage()));
    await tester.pumpAndSettle();

    expect(find.text('订阅'), findsOneWidget);
    await tester.ensureVisible(find.text('订阅'));
    await tester.tap(find.text('订阅'));
    await tester.pump();

    await tester.ensureVisible(find.text('开始推送'));
    await tester.tap(find.text('开始推送'));
    // Advance the fake clock past the 2s push interval so the periodic
    // timer delivers into the subscription.
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.textContaining('模拟消息 #1'), findsOneWidget);

    await tester.ensureVisible(find.text('停止推送'));
    await tester.tap(find.text('停止推送'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
