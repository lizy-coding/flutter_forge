import 'package:flutter/material.dart';

import 'module_root.dart' as isolate_task_manager;

class IsolateStreamEntry extends StatelessWidget {
  const IsolateStreamEntry({super.key});

  @override
  Widget build(BuildContext context) {
    return const isolate_task_manager.MultiTaskIsolatePage(
      title: '多任务并行处理与实时进度监听',
    );
  }
}
