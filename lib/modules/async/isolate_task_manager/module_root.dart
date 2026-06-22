// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables
import 'package:flutter/material.dart';
import 'package:flutter_study_learning/flutter_study_learning.dart';

import 'task_manager.dart';

class MultiTaskIsolatePage extends StatefulWidget {
  const MultiTaskIsolatePage({super.key, required this.title});

  final String title;

  @override
  State<MultiTaskIsolatePage> createState() => _MultiTaskIsolatePageState();
}

class _MultiTaskIsolatePageState extends State<MultiTaskIsolatePage> {
  late final TaskManager _taskManager;

  @override
  void initState() {
    super.initState();
    _taskManager = TaskManager(
      onTaskUpdate: (task) {
        setState(() {});
      },
      onTaskComplete: (task) {
        setState(() {});
      },
    );
  }

  @override
  void dispose() {
    _taskManager.dispose();
    super.dispose();
  }

  void _startNewTask() {
    _taskManager.startNewTask();
    setState(() {});
  }

  void _pauseTask(Task task) {
    _taskManager.pauseTask(task);
    setState(() {});
  }

  void _resumeTask(Task task) {
    _taskManager.resumeTask(task);
    setState(() {});
  }

  void _stopTask(Task task) {
    _taskManager.stopTask(task);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return LearningScaffold(
      title: widget.title,
      floatingActionButton: FloatingActionButton(
        onPressed: _startNewTask,
        tooltip: '添加新任务',
        child: const Icon(Icons.add),
      ),
      interactiveDemo: SizedBox(
        height: 500,
        child: _taskManager.tasks.isEmpty
            ? const Center(child: Text('点击下方按钮添加任务'))
            : ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: _taskManager.tasks.length,
                itemBuilder: (context, index) {
                  final task = _taskManager.tasks[index];
                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.only(bottom: 12.0),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                task.name,
                                style:
                                    Theme.of(context).textTheme.headlineSmall,
                              ),
                              if (task.isCompleted)
                                const Icon(Icons.check_circle,
                                    color: Colors.green)
                              else
                                IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () => _stopTask(task),
                                  tooltip: '停止任务',
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: task.progress / 100,
                            backgroundColor: Colors.grey[200],
                            color: task.color,
                            minHeight: 12,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('进度: ${task.progress}%'),
                              Text(
                                task.isCompleted
                                    ? '已完成'
                                    : task.isPaused
                                        ? '已暂停'
                                        : '进行中',
                                style: TextStyle(
                                  color: task.isCompleted
                                      ? Colors.green
                                      : task.isPaused
                                          ? Colors.orange
                                          : Colors.blue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          if (!task.isCompleted)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  icon: Icon(task.isPaused
                                      ? Icons.play_arrow
                                      : Icons.pause),
                                  onPressed: task.isPaused
                                      ? () => _resumeTask(task)
                                      : () => _pauseTask(task),
                                  tooltip: task.isPaused ? '继续任务' : '暂停任务',
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
      sections: [
        LearningObjectives(objectives: [
          '理解 Isolate 多任务并行执行的原理',
          '掌握通过 Stream 实时监控任务进度',
          '学会管理多个 Isolate 的生命周期',
        ]),
        ConceptChips(concepts: [
          'Isolate',
          '多任务',
          'Stream',
          '进度上报',
          '暂停/恢复',
          '并发控制',
        ]),
        CodeSnippetCard(
          title: 'TaskManager 核心用法',
          code: 'final manager = TaskManager(\n'
              '  onTaskUpdate: (task) => setState(() {}),\n'
              '  onTaskComplete: (task) => setState(() {}),\n'
              ');\n'
              'manager.startNewTask();\n'
              'manager.pauseTask(task);\n'
              'manager.resumeTask(task);\n'
              'manager.stopTask(task);\n'
              'manager.dispose();',
          explanation: 'TaskManager 封装了 Isolate 的创建、通信和销毁流程。',
        ),
        CommonPitfalls(pitfalls: [
          '忘记 dispose TaskManager — Isolate 不会自动终止，需显式释放资源',
          '在 Isolate 中访问主线程对象 — Isolate 是独立内存空间，只能通过消息传递数据',
          '任务过密导致 UI 卡顿 — 大量任务同时运行时注意控制并发数量',
        ]),
        ExerciseCard(
          task: '为 TaskManager 增加"任务优先级"功能，高优先级任务先执行。',
          hint: '在 Task 模型中增加 priority 字段，在 startNewTask 中对队列排序。',
        ),
      ],
    );
  }
}
