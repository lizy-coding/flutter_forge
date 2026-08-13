import 'dart:isolate';
import 'dart:async';
import 'dart:math';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

// 任务模型
class Task {
  final int id;
  final String name;
  int progress;
  bool isCompleted;
  bool isPaused = false;
  Isolate? isolate;
  ReceivePort? receivePort;
  StreamSubscription<dynamic>? subscription;
  SendPort? isolateSendPort;
  final Color color;

  Task({
    required this.id,
    required this.name,
    this.progress = 0,
    this.isCompleted = false,
  }) : color = _getRandomColor();

  static Color _getRandomColor() {
    final random = Random();
    return Color.fromRGBO(
      random.nextInt(200) + 55, // 确保颜色不太暗
      random.nextInt(200) + 55,
      random.nextInt(200) + 55,
      1.0,
    );
  }

  void dispose() {
    isolate?.kill(priority: Isolate.immediate);
    subscription?.cancel();
    receivePort?.close();
  }

  void pause() {
    if (!isCompleted && !isPaused && isolateSendPort != null) {
      isolateSendPort?.send({'action': 'pause'});
      isPaused = true;
    }
  }

  void resume() {
    if (!isCompleted && isPaused && isolateSendPort != null) {
      isolateSendPort?.send({'action': 'resume'});
      isPaused = false;
    }
  }
}

// 任务管理类，负责管理任务的生命周期
class TaskManager {
  final List<Task> _tasks = [];
  int _nextTaskId = 1;
  final Function(Task)? onTaskUpdate;
  final Function(Task)? onTaskComplete;

  TaskManager({this.onTaskUpdate, this.onTaskComplete});

  List<Task> get tasks => List.unmodifiable(_tasks);

  // 创建并启动新任务
  Task startNewTask() {
    final task = Task(id: _nextTaskId++, name: '任务 ${_nextTaskId - 1}');

    _tasks.add(task);
    _startTaskInIsolate(task);

    return task;
  }

  // 在Isolate中启动任务
  void _startTaskInIsolate(Task task) async {
    task.receivePort = ReceivePort();

    // 启动Isolate，传递任务ID、初始进度和sendPort
    task.isolate = await Isolate.spawn(_taskIsolate, {
      'sendPort': task.receivePort!.sendPort,
      'taskId': task.id,
      'initialProgress': task.progress,
    });

    // 监听任务进度更新和Isolate的SendPort
    task.subscription = task.receivePort!.listen((dynamic data) {
      if (data is SendPort) {
        // 保存Isolate的SendPort，用于向Isolate发送命令
        task.isolateSendPort = data;
      } else if (data is Map<String, dynamic>) {
        final int taskId = data['taskId'];
        final Task? updatedTask = _tasks.firstWhereOrNull(
          (t) => t.id == taskId,
        );

        if (updatedTask != null) {
          if (data.containsKey('progress')) {
            updatedTask.progress = data['progress'];
          }
          if (data.containsKey('completed')) {
            updatedTask.isCompleted = data['completed'];
          }

          // 通知任务更新
          if (onTaskUpdate != null) {
            onTaskUpdate!(updatedTask);
          }

          // 通知任务完成
          if (updatedTask.isCompleted && onTaskComplete != null) {
            onTaskComplete!(updatedTask);
          }
        }
      }
    });
  }

  // 暂停任务
  void pauseTask(Task task) {
    task.pause();
  }

  // 恢复任务
  void resumeTask(Task task) {
    task.resume();
  }

  // 停止特定任务
  void stopTask(Task task) {
    task.dispose();
    _tasks.remove(task);
  }

  // 停止所有任务
  void stopAllTasks() {
    for (final task in _tasks) {
      task.dispose();
    }
    _tasks.clear();
  }

  // 清理资源
  void dispose() {
    stopAllTasks();
  }
}

// Isolate中执行的任务函数
void _taskIsolate(dynamic message) {
  final SendPort sendPort = message['sendPort'];
  final int taskId = message['taskId'];
  final int initialProgress = message['initialProgress'] ?? 0;
  final Random random = Random();
  int progress = initialProgress;

  // 创建一个ReceivePort来接收来自主线程的命令
  final ReceivePort commandPort = ReceivePort();

  // 向主线程发送命令端口的SendPort
  sendPort.send(commandPort.sendPort);

  // 任务状态控制变量
  bool isPaused = false;
  bool isRunning = true;
  Timer? timer;

  // 每个任务的完成时间随机（10-30秒）
  final int totalSteps = random.nextInt(20) + 10;
  final int delayMs = random.nextInt(500) + 300;

  // 创建定时器模拟任务执行
  void startTimer() {
    timer = Timer.periodic(Duration(milliseconds: delayMs), (t) {
      if (!isPaused && isRunning) {
        // 每次进度随机增加（2-8%）
        final int progressIncrement = random.nextInt(7) + 2;
        progress = min(progress + progressIncrement, 100);

        // 发送进度更新
        sendPort.send({
          'taskId': taskId,
          'progress': progress,
          'completed': progress >= 100,
        });

        // 任务完成时停止定时器
        if (progress >= 100 || t.tick >= totalSteps) {
          sendPort.send({'taskId': taskId, 'progress': 100, 'completed': true});
          t.cancel();
          isRunning = false;
          commandPort.close();
        }
      }
    });
  }

  // 启动定时器
  startTimer();

  // 监听来自主线程的命令
  commandPort.listen((dynamic command) {
    if (command is Map<String, dynamic>) {
      final String action = command['action'];
      switch (action) {
        case 'pause':
          isPaused = true;
          break;
        case 'resume':
          isPaused = false;
          break;
        case 'stop':
          isRunning = false;
          timer?.cancel();
          commandPort.close();
          break;
      }
    }
  });
}
