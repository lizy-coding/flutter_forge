import 'package:flutter_forge_app/modules/basic/debounce_throttle/utils/debounce_throttle.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('debouncer collapses rapid calls into the last action', (
    tester,
  ) async {
    final debouncer = Debouncer(delay: const Duration(milliseconds: 300));
    var runs = 0;
    debouncer.run(() => runs = 1);
    await tester.pump(const Duration(milliseconds: 200));
    debouncer.run(() => runs = 2);
    await tester.pump(const Duration(milliseconds: 200));
    expect(runs, 0, reason: '第二次调用必须重置计时');

    await tester.pump(const Duration(milliseconds: 100));
    expect(runs, 2, reason: '只有最后一次动作应执行');
    debouncer.dispose();
  });

  testWidgets('debouncer dispose cancels the pending action', (tester) async {
    final debouncer = Debouncer(delay: const Duration(milliseconds: 100));
    var runs = 0;
    debouncer.run(() => runs++);
    debouncer.dispose();
    await tester.pump(const Duration(milliseconds: 500));
    expect(runs, 0);
  });

  testWidgets('throttle runs immediately then blocks until the limit', (
    tester,
  ) async {
    final throttle = Throttle(limit: const Duration(milliseconds: 500));
    var runs = 0;
    throttle.run(() => runs++);
    expect(runs, 1, reason: '第一次调用立即执行');

    throttle.run(() => runs++);
    throttle.run(() => runs++);
    expect(runs, 1, reason: '窗口期内的调用必须被丢弃');

    await tester.pump(const Duration(milliseconds: 500));
    throttle.run(() => runs++);
    expect(runs, 2, reason: '窗口结束后恢复执行');
    // Drain the re-arm timer so no timer is pending at teardown.
    await tester.pump(const Duration(milliseconds: 500));
  });
}
