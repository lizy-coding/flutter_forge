import 'dart:async';
import 'dart:isolate';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_forge_app/modules/async/isolate_task_manager/task_manager.dart';

void idleWorker(dynamic _) {
  ReceivePort();
}

void main() {
  test('a task stopped while spawn is pending kills the late handle', () async {
    final exited = ReceivePort();
    final worker = await Isolate.spawn(
      idleWorker,
      null,
      paused: true,
      onExit: exited.sendPort,
    );
    final gate = Completer<Isolate>();
    var updates = 0;
    final manager = TaskManager(
      spawn: (_, __) => gate.future,
      onTaskUpdate: (_) => updates++,
    );
    try {
      final task = manager.startNewTask();
      manager.stopTask(task);
      final exit = exited.first;
      gate.complete(worker);
      await exit.timeout(const Duration(seconds: 2));
      expect(manager.tasks, isEmpty);
      expect(task.isolate, isNull);
      expect(task.receivePort, isNull);
      expect(updates, 0);
    } finally {
      manager.dispose();
      worker.kill(priority: Isolate.immediate);
      exited.close();
    }
  });

  test('completed tasks release ports and their worker exactly once', () async {
    final exited = ReceivePort();
    final worker = await Isolate.spawn(
      idleWorker,
      null,
      paused: true,
      onExit: exited.sendPort,
    );
    final completed = Completer<Task>();
    var completions = 0;
    final manager = TaskManager(
      spawn: (_, message) async {
        final port = message['sendPort'] as SendPort;
        port.send({
          'taskId': message['taskId'],
          'progress': 100,
          'completed': true,
        });
        port.send({
          'taskId': message['taskId'],
          'progress': 100,
          'completed': true,
        });
        return worker;
      },
      onTaskComplete: (task) {
        completions++;
        if (!completed.isCompleted) completed.complete(task);
      },
    );
    try {
      manager.startNewTask();
      final task = await completed.future.timeout(const Duration(seconds: 2));
      await exited.first.timeout(const Duration(seconds: 2));
      expect(task.isCompleted, isTrue);
      expect(task.isolate, isNull);
      expect(task.receivePort, isNull);
      expect(task.subscription, isNull);
      expect(completions, 1);
    } finally {
      manager.dispose();
      worker.kill(priority: Isolate.immediate);
      exited.close();
    }
  });

  test('spawn failures release resources and remain visible', () async {
    final changed = Completer<Task>();
    final manager = TaskManager(
      spawn: (_, __) async => throw StateError('spawn unavailable'),
      onTaskUpdate: changed.complete,
    );
    final task = manager.startNewTask();
    await changed.future;
    expect(task.error, contains('spawn unavailable'));
    expect(task.receivePort, isNull);
    manager.dispose();
    expect(manager.startNewTask, throwsStateError);
  });
}
