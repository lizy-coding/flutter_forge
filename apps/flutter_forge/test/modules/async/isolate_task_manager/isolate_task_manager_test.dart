import 'dart:isolate';

import 'package:flutter/widgets.dart';
import 'package:flutter_forge_app/modules/async/isolate_task_manager/module_entry.dart';
import 'package:flutter_forge_app/modules/async/isolate_task_manager/task_manager.dart';
import 'package:flutter_test/flutter_test.dart';

/// A controllable stand-in for the module's random isolate: it answers the
/// handshake, honours pause/resume, and only advances when told to 'step'.
void _controlledIsolate(dynamic raw) {
  final message = raw as Map<dynamic, dynamic>;
  final sendPort = message['sendPort'] as SendPort;
  final commandPort = ReceivePort();
  sendPort.send(commandPort.sendPort);
  var progress = (message['initialProgress'] as int?) ?? 0;
  var paused = false;
  commandPort.listen((command) {
    if (command is! Map) return;
    switch (command['action']) {
      case 'pause':
        paused = true;
      case 'resume':
        paused = false;
      case 'step':
        if (paused) return;
        progress += command['delta'] as int;
        sendPort.send({
          'taskId': message['taskId'],
          'progress': progress,
          'completed': progress >= 100,
        });
    }
  });
}

Future<void> waitFor(
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('condition not met within $timeout');
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
    await pumpEventQueue();
  }
}

void main() {
  test('module entry is constructible', () {
    expect(const IsolateStreamEntry(), isA<Widget>());
  });

  test('progress updates flow through the manager callbacks', () async {
    final updates = <Task>[];
    final manager = TaskManager(
      onTaskUpdate: updates.add,
      spawn: (entry, message) => Isolate.spawn(_controlledIsolate, message),
    );
    addTearDown(manager.dispose);

    final task = manager.startNewTask();
    await waitFor(() => task.isolateSendPort != null);
    task.isolateSendPort!.send({'action': 'step', 'delta': 30});
    await waitFor(() => updates.isNotEmpty);

    expect(task.progress, 30);
    expect(updates.single.id, task.id);
  });

  test('pause gates progress until resume', () async {
    final updates = <Task>[];
    final manager = TaskManager(
      onTaskUpdate: updates.add,
      spawn: (entry, message) => Isolate.spawn(_controlledIsolate, message),
    );
    addTearDown(manager.dispose);

    final task = manager.startNewTask();
    await waitFor(() => task.isolateSendPort != null);

    manager.pauseTask(task);
    expect(task.isPaused, isTrue);
    task.isolateSendPort!.send({'action': 'step', 'delta': 10});
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await pumpEventQueue();
    expect(updates, isEmpty, reason: '暂停期间不应有进度更新');

    manager.resumeTask(task);
    expect(task.isPaused, isFalse);
    task.isolateSendPort!.send({'action': 'step', 'delta': 40});
    await waitFor(() => updates.isNotEmpty);
    expect(task.progress, 40);
  });

  test('completion disposes the task and fires onTaskComplete', () async {
    var completed = 0;
    final manager = TaskManager(
      onTaskComplete: (_) => completed++,
      spawn: (entry, message) => Isolate.spawn(_controlledIsolate, message),
    );
    addTearDown(manager.dispose);

    final task = manager.startNewTask();
    await waitFor(() => task.isolateSendPort != null);
    task.isolateSendPort!.send({'action': 'step', 'delta': 100});
    await waitFor(() => completed > 0);

    expect(task.isCompleted, isTrue);
    expect(task.isolate, isNull, reason: '完成后任务应释放隔离资源');
  });

  test('a stopped task ignores late isolate updates', () async {
    final updates = <Task>[];
    final manager = TaskManager(
      onTaskUpdate: updates.add,
      spawn: (entry, message) => Isolate.spawn(_controlledIsolate, message),
    );
    addTearDown(manager.dispose);

    final task = manager.startNewTask();
    await waitFor(() => task.isolateSendPort != null);
    final isolatePort = task.isolateSendPort!;
    manager.stopTask(task);
    expect(manager.tasks, isEmpty);

    isolatePort.send({'action': 'step', 'delta': 10});
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await pumpEventQueue();
    expect(updates, isEmpty, reason: '停止后到达的消息必须被丢弃');
  });

  test('startNewTask after the manager is disposed throws', () async {
    final manager = TaskManager(
      spawn: (entry, message) => Isolate.spawn(_controlledIsolate, message),
    );
    manager.dispose();
    expect(manager.startNewTask, throwsStateError);
  });

  test('a spawn failure records the error and notifies', () async {
    final updates = <Task>[];
    final manager = TaskManager(
      onTaskUpdate: updates.add,
      spawn: (entry, message) async => throw StateError('无法创建隔离'),
    );

    final task = manager.startNewTask();
    await waitFor(() => task.error != null);

    expect(task.error, contains('任务启动失败'));
    expect(updates.map((t) => t.id), contains(task.id));
    manager.dispose();
  });
}
